import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import '../providers/user_provider_new.dart';
import '../providers/ad_provider_new.dart';
import '../providers/config_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/spin_welcome_dialog.dart';

class SpinAndWinScreen extends StatefulWidget {
  static const String routeName = '/spin-and-win';

  const SpinAndWinScreen({super.key});

  @override
  State<SpinAndWinScreen> createState() => _SpinAndWinScreenState();
}

class _SpinAndWinScreenState extends State<SpinAndWinScreen> {
  final StreamController<int> _wheelNotifier = StreamController<int>();
  final List<int> _spinRewards = [3, 6, 9, 10, 30, 0];
  int _currentSpinIndex = 0;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdProviderNew>(context, listen: false).loadRewardedAd();
      _showWelcomeDialog();
    });
  }

  @override
  void dispose() {
    _wheelNotifier.close();
    super.dispose();
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const SpinWelcomeDialog(),
    );
  }

  void _startSpin() async {
    if (_isSpinning) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final adProvider = Provider.of<AdProviderNew>(context, listen: false);
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final int spinsUsed =
        userProvider.currentUser?.dailyStats[today]?['spinPlayed'] ?? 0;
    final int dailySpinLimit = configProvider.appConfig['dailySpinLimit'] ?? 3;

    if (spinsUsed >= dailySpinLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily spin limit reached. Come back tomorrow!'),
        ),
      );
      return;
    }

    if (adProvider.rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait while we prepare your reward...'),
        ),
      );
      adProvider.loadRewardedAd();
      return;
    }

    setState(() {
      _isSpinning = true;
    });

  
    adProvider.showRewardedAd(
      onAdEarned: (reward) {
        final random = Random();
        _currentSpinIndex = random.nextInt(_spinRewards.length);
        _wheelNotifier.add(_currentSpinIndex);
      },
    );
  }

  void _showRewardDialog(int earnedCoins) {
    if (earnedCoins == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Better luck next time! Try again for a chance to win coins.',
          ),
        ),
      );
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.medal_star,
              size: 32,
              color: colorScheme.primary,
            ),
          ),
          title: Text(
            'Congratulations!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You won',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.coin, color: colorScheme.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '$earnedCoins',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: colorScheme.primary,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'coins',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary.withOpacity(0.8),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Collect Reward',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        );
      },
    );
  }

  Widget _buildSpinProgress(int spinsUsed, int dailySpinLimit) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Spins',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${dailySpinLimit - spinsUsed}/$dailySpinLimit remaining',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (dailySpinLimit - spinsUsed) / dailySpinLimit,
            minHeight: 8,
            backgroundColor: colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Resets at midnight',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final int spinsUsed =
        userProvider.currentUser?.dailyStats[today]?['spinPlayed'] ?? 0;
    final int dailySpinLimit = configProvider.appConfig['dailySpinLimit'] ?? 3;

    final items = _spinRewards.map((reward) {
      final index = _spinRewards.indexOf(reward);
      return FortuneItem(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (reward > 0) ...[
              Icon(Iconsax.coin, color: Colors.white, size: 24),
              const SizedBox(height: 4),
            ],
            Text(
              reward > 0 ? reward.toString() : 'Try Again',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        style: FortuneItemStyle(
          color: reward > 0
              ? (index % 2 == 0
                    ? colorScheme.primary
                    : colorScheme.primaryContainer)
              : colorScheme.surfaceVariant,
          borderColor: colorScheme.primary.withOpacity(0.3),
          borderWidth: 2,
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
              Card(
                elevation: 2,
                shadowColor: colorScheme.shadow.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildSpinProgress(spinsUsed, dailySpinLimit),
                ),
              ),
              const SizedBox(height: 30),
              Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: FortuneWheel(
                      selected: _wheelNotifier.stream,
                      animateFirst: false,
                      items: items,
                      onAnimationEnd: () async {
                        setState(() {
                          _isSpinning = false;
                        });
                        final int earnedCoins = _spinRewards[_currentSpinIndex];
                        final adProvider = Provider.of<AdProviderNew>(
                          context,
                          listen: false,
                        );
                        final userProvider = Provider.of<UserProvider>(
                          context,
                          listen: false,
                        );

                        await userProvider.recordGameReward(
                          gameType: 'spin',
                          amount: earnedCoins,
                          dailyLimit: dailySpinLimit,
                        );

                        if (!mounted) return;
                        _showRewardDialog(earnedCoins);
                        adProvider.loadRewardedAd();
                      },
                      indicators: const <FortuneIndicator>[
                        FortuneIndicator(
                          alignment: Alignment.topCenter,
                          child: TriangleIndicator(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: (spinsUsed < dailySpinLimit && !_isSpinning)
                          ? _startSpin
                          : null,
                      borderRadius: BorderRadius.circular(32),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (spinsUsed < dailySpinLimit && !_isSpinning)
                              ? colorScheme.primary
                              : colorScheme.surfaceVariant,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isSpinning
                              ? Icons.hourglass_empty
                              : Icons.play_arrow,
                          size: 32,
                          color: (spinsUsed < dailySpinLimit && !_isSpinning)
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isSpinning)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    'Spinning...',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
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
