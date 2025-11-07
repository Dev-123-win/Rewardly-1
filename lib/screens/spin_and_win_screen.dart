import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import '../providers/ad_provider.dart';
import '../providers/user_provider.dart';
import '../providers/config_provider.dart';
import '../widgets/custom_app_bar.dart';

class SpinAndWinScreen extends StatefulWidget {
  static const String routeName = '/spin-and-win';

  const SpinAndWinScreen({super.key});

  @override
  State<SpinAndWinScreen> createState() => _SpinAndWinScreenState();
}

class _SpinAndWinScreenState extends State<SpinAndWinScreen> {
  final StreamController<int> _wheelNotifier = StreamController<int>();
  final List<int> _spinRewards = [5, 10, 20, 5, 30, 50, 10, 100];
  int _currentSpinIndex = 0;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdProvider>(context, listen: false).loadRewardedAd();
    });
  }

  @override
  void dispose() {
    _wheelNotifier.close();
    super.dispose();
  }

  void _startSpin() async {
    if (_isSpinning) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final adProvider = Provider.of<AdProvider>(context, listen: false);
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);

    final int spinsUsed = userProvider.getTodayStats()?['spinsUsed'] ?? 0;
    final int dailySpinLimit = configProvider.appConfig['dailySpinLimit'] ?? 3;

    if (spinsUsed >= dailySpinLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily spin limit reached. Resets at midnight.'),
        ),
      );
      return;
    }

    if (adProvider.rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad not ready. Please try again in a moment.'),
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
        final random = Random();
        _currentSpinIndex = random.nextInt(_spinRewards.length);
        _wheelNotifier.add(_currentSpinIndex);
      },
    );
  }

  void _showRewardDialog(int earnedCoins) {
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    final int spinsUsed = userProvider.getTodayStats()?['spinsUsed'] ?? 0;
    final int dailySpinLimit = configProvider.appConfig['dailySpinLimit'] ?? 3;

    final items = _spinRewards.map((reward) {
      final index = _spinRewards.indexOf(reward);
      return FortuneItem(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.coin, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              reward.toString(),
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        style: FortuneItemStyle(
          color: index % 2 == 0
              ? colorScheme.primary
              : colorScheme.primaryContainer,
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  shadowColor: colorScheme.shadow.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withOpacity(0.2),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primaryContainer.withOpacity(0.8),
                          colorScheme.primary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Iconsax.refresh,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Spins',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: colorScheme.primary,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: colorScheme.onPrimaryContainer,
                                        fontFamily: 'Inter',
                                      ),
                                  children: [
                                    TextSpan(
                                      text: '${dailySpinLimit - spinsUsed}',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' / $dailySpinLimit remaining',
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Resets at midnight',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onPrimaryContainer
                                          .withOpacity(0.7),
                                      fontFamily: 'Inter',
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: GestureDetector(
                    onTap: _isSpinning ? null : _startSpin,
                    child: FortuneWheel(
                      selected: _wheelNotifier.stream,
                      animateFirst: false,
                      items: items,
                      onAnimationEnd: () async {
                        if (!mounted) return;
                        setState(() {
                          _isSpinning = false;
                        });
                        final int earnedCoins = _spinRewards[_currentSpinIndex];
                        final adProvider = Provider.of<AdProvider>(
                          context,
                          listen: false,
                        );
                        await Provider.of<UserProvider>(
                          context,
                          listen: false,
                        ).spinAndEarnCoins(earnedCoins, dailySpinLimit);
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
                ),
                const SizedBox(height: 40),
                FilledButton(
                  onPressed: (spinsUsed < dailySpinLimit && !_isSpinning)
                      ? _startSpin
                      : null,
                  style:
                      FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.disabled)) {
                            return colorScheme.surfaceContainerHighest;
                          }
                          return colorScheme.primary;
                        }),
                      ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isSpinning ? Iconsax.timer_1 : Iconsax.play_circle,
                        color: _isSpinning || spinsUsed >= dailySpinLimit
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onPrimary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (spinsUsed < dailySpinLimit && !_isSpinning)
                                ? 'Watch Ad to Unlock Spin'
                                : 'Daily Spin Limit Reached',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color:
                                      _isSpinning || spinsUsed >= dailySpinLimit
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onPrimary,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (!_isSpinning && spinsUsed < dailySpinLimit) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Win 5-100 coins per spin',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onPrimary.withOpacity(
                                      0.9,
                                    ),
                                    fontFamily: 'Inter',
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (_isSpinning)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
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
      ),
    );
  }
}
