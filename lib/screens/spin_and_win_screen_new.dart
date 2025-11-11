import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import '../providers/local_user_provider.dart';
import '../providers/ad_provider_new.dart';
import '../widgets/spin_result_dialog.dart';
import '../widgets/spin_welcome_dialog.dart';

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
  int _availableSpins = 0; // New state variable for available spins
  bool _showSpinAnimation = false; // New state variable for animation

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // AdProviderNew now preloads ads in its constructor, so no need to call loadRewardedAd here.
      // Show welcome dialog
      showDialog(
        context: context,
        builder: (context) => const SpinWelcomeDialog(),
      );
    });
  }

  @override
  void dispose() {
    _wheelNotifier.close();
    super.dispose();
  }

  void _watchAdAndPrepareSpin() async {
    if (_isSpinning) return; // Cannot watch ad while spinning

    final adProvider = Provider.of<AdProviderNew>(context, listen: false);

    if (adProvider.rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait while we prepare your ad...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // AdProviderNew now handles preloading internally.
      // adProvider.loadRewardedAd(); // No longer needed here
      return;
    }

    adProvider.showRewardedAd(
      onAdEarned: (reward) async {
        if (!mounted) return;
        setState(() {
          if (_availableSpins < 3) {
            _availableSpins++;
          }
          _showSpinAnimation = true;
        });
        // After a short delay, hide the animation and load next ad
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _showSpinAnimation = false;
            });
            // AdProviderNew handles preloading internally, no need to explicitly call loadRewardedAd here.
          }
        });
      },
    );
  }

  void _triggerWheelSpin() async {
    if (_isSpinning) return;
    if (_availableSpins == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Watch an ad to get a spin!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSpinning = true;
      _availableSpins--; // Consume one spin
    });

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
  }

  void _showResult(int coins) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SpinResultDialog(coins: coins),
    ).then((_) async {
      // Made the callback async
      if (!mounted) return; // Check mounted state

      if (coins > 0) {
        // Record the reward if coins were won
        Provider.of<LocalUserProvider>(
          context,
          listen: false,
        ).recordGameReward(gameType: 'spin', amount: coins);
      }
      // AdProviderNew handles preloading internally, no need to explicitly call loadRewardedAd here.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Spin and Win',
          style: TextStyle(
            color: Colors.black, // Ensure title is visible
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false, // Ensure title is not centered if actions push it
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0), // Adjusted padding to the right
            child: Row(
              children: [
                Icon(
                  Iconsax.wallet, // Changed to wallet icon
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Consumer<LocalUserProvider>(
                  builder: (context, provider, _) => Text(
                    '${provider.currentUser?.coins ?? 0}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).colorScheme.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              // New "Watch Ad & Spin" button above the wheel
              FilledButton.icon(
                onPressed: _isSpinning ? null : _watchAdAndPrepareSpin, // Only watches ad
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                icon: Icon(
                  _isSpinning ? Icons.hourglass_empty : Icons.play_circle,
                  size: 28,
                ),
                label: Text(
                  _isSpinning ? 'Spinning...' : 'Watch Ad & Get Spin!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Wheel container with effects
              Stack(
                alignment: Alignment.center,
                children: [
                  // Glow effect behind wheel
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width - 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 50,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  // Wheel border decoration
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.2),
                          spreadRadius: 4,
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: FortuneWheel(
                        selected: _wheelNotifier.stream,
                        animateFirst: false,
                        items: _spinRewards.map((reward) {
                          return FortuneItem(
                            child: Transform.rotate(
                              angle: pi / 2,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      reward == 0
                                          ? Icons.refresh
                                          : Iconsax.coin,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      reward == 0
                                          ? 'Try Again'
                                          : '$reward\nCoins',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: reward == 0 ? 16 : 18,
                                        fontWeight: FontWeight.w600,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            style: FortuneItemStyle(
                              color: reward == 0
                                  ? Theme.of(context).colorScheme.error // Material 3 red color
                                  : Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                              borderWidth: 1,
                              borderColor: Theme.of(
                                context,
                              ).colorScheme.outline,
                            ),
                          );
                        }).toList(),
                        onAnimationEnd: () {
                          setState(() {
                            _isSpinning = false;
                          });
                          _showResult(_spinRewards[_currentSpinIndex]);
                        },
                        physics: CircularPanPhysics(
                          duration: const Duration(seconds: 5),
                          curve: Curves.decelerate,
                        ),
                        indicators: const <FortuneIndicator>[
                          FortuneIndicator(
                            alignment: Alignment.topCenter,
                            child: TriangleIndicator(
                              color: Colors.amber,
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ],
                        styleStrategy: UniformStyleStrategy(
                          borderWidth: 2,
                          borderColor: Colors.white24,
                        ),
                      ),
                    ),
                  ),
                  // Center decoration
                  GestureDetector(
                    onTap: _isSpinning ? null : _triggerWheelSpin,
                    child: Container(
                      width: 80, // Increased size for better tap target
                      height: 80, // Increased size for better tap target
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: _showSpinAnimation
                            ? TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 500),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Opacity(
                                      opacity: value,
                                      child: Text(
                                        '+$_availableSpins',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Text(
                                _availableSpins > 0 ? 'Spin' : '0',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _availableSpins > 0
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
