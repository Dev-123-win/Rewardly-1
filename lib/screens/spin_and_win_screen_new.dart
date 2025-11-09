import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import '../providers/user_provider_new.dart';
import '../providers/ad_provider_new.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/spin_result_dialog.dart';

class SpinAndWinScreenNew extends StatefulWidget {
  static const String routeName = '/spin-and-win';

  const SpinAndWinScreenNew({super.key});

  @override
  State<SpinAndWinScreenNew> createState() => _SpinAndWinScreenNewState();
}

class _SpinAndWinScreenNewState extends State<SpinAndWinScreenNew> {
  final StreamController<int> _wheelNotifier = StreamController<int>();
  final List<int> _spinRewards = [0, 3, 6, 9, 10, 30];
  int _currentSpinIndex = 0;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdProviderNew>(context, listen: false).loadRewardedAd();
    });
  }

  @override
  void dispose() {
    _wheelNotifier.close();
    super.dispose();
  }

  void _startSpin() async {
    if (_isSpinning) return;

    final adProvider = Provider.of<AdProviderNew>(context, listen: false);

    if (adProvider.rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait while we prepare your spin...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      adProvider.loadRewardedAd();
      return;
    }

    setState(() {
      _isSpinning = true;
    });

    adProvider.showRewardedAd(
      onAdEarned: (reward) async {
        if (!mounted) return;

        // Ensure random spin with weighted probabilities
        final random = Random();
        final double value = random.nextDouble();

        // 30% chance for 0 coins
        // 25% chance for 3 coins
        // 20% chance for 6 coins
        // 15% chance for 9 coins
        // 8% chance for 10 coins
        // 2% chance for 30 coins

        if (value < 0.30) {
          _currentSpinIndex = 0; // 0 coins
        } else if (value < 0.55) {
          _currentSpinIndex = 1; // 3 coins
        } else if (value < 0.75) {
          _currentSpinIndex = 2; // 6 coins
        } else if (value < 0.90) {
          _currentSpinIndex = 3; // 9 coins
        } else if (value < 0.98) {
          _currentSpinIndex = 4; // 10 coins
        } else {
          _currentSpinIndex = 5; // 30 coins
        }

        _wheelNotifier.add(_currentSpinIndex);
      },
    );
  }

  void _showResult(int coins) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SpinResultDialog(coins: coins),
    ).then((_) async { // Made the callback async
      if (!mounted) return; // Check mounted state

      if (coins > 0) {
        // Record the reward if coins were won
        Provider.of<UserProviderNew>(
          context,
          listen: false,
        ).recordGameReward(gameType: 'spin', amount: coins);
      }
      // Load next ad
      Provider.of<AdProviderNew>(context, listen: false).loadRewardedAd();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final items = _spinRewards.map((reward) {
      final bool isZero = reward == 0;
      return FortuneItem(
        child: Transform.rotate(
          angle: pi / 2, // Rotate text 90 degrees for better readability
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isZero) ...[
                Icon(Iconsax.coin, color: Colors.white, size: 24),
                const SizedBox(height: 4),
              ],
              Text(
                isZero ? 'Try Again' : reward.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isZero ? 16 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        style: FortuneItemStyle(
          color: isZero
              ? colorScheme.surfaceVariant
              : (reward >= 10
                    ? colorScheme.primary
                    : colorScheme.primaryContainer),
          borderColor: colorScheme.outline.withOpacity(0.1),
          borderWidth: 1,
        ),
      );
    }).toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Spin & Win',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: FortuneWheel(
                        selected: _wheelNotifier.stream,
                        animateFirst: false,
                        items: items,
                        onAnimationEnd: () {
                          setState(() {
                            _isSpinning = false;
                          });
                          _showResult(_spinRewards[_currentSpinIndex]);
                        },
                        indicators: const <FortuneIndicator>[
                          FortuneIndicator(
                            alignment: Alignment.topCenter,
                            child: TriangleIndicator(
                              color: Colors.red,
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              FilledButton.icon(
                onPressed: _isSpinning ? null : _startSpin,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: colorScheme.primary,
                  disabledBackgroundColor: colorScheme.surfaceVariant,
                ),
                icon: Icon(
                  _isSpinning ? Icons.hourglass_empty : Icons.play_circle,
                  size: 24,
                ),
                label: Text(
                  _isSpinning ? 'Spinning...' : 'Watch Ad & Get 1 Spin',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _isSpinning
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
