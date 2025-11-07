import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import '../providers/ad_provider.dart';
import '../providers/user_provider.dart';
import '../providers/config_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../core/utils/responsive_utils.dart';

class ResponsiveSpinAndWinScreen extends StatefulWidget {
  static const String routeName = '/spin-and-win';

  const ResponsiveSpinAndWinScreen({super.key});

  @override
  State<ResponsiveSpinAndWinScreen> createState() =>
      _ResponsiveSpinAndWinScreenState();
}

class _ResponsiveSpinAndWinScreenState
    extends State<ResponsiveSpinAndWinScreen> {
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

  void _startSpin() {
    if (_isSpinning) return;

    final adProvider = Provider.of<AdProvider>(context, listen: false);
    if (!adProvider.isRewardedAdReady) {
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
      _currentSpinIndex = Fortune.randomInt(0, _spinRewards.length);
      _wheelNotifier.add(_currentSpinIndex);
    });
  }

  void _onSpinEnd() {
    final reward = _spinRewards[_currentSpinIndex];
    final adProvider = Provider.of<AdProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final dailySpinLimit = configProvider.appConfig['dailySpinLimit'] ?? 3;

    if (adProvider.isRewardedAdReady) {
      adProvider.showRewardedAd(
        onAdEarned: (adReward) async {
          try {
            await userProvider.spinAndEarnCoins(reward, dailySpinLimit);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Congratulations! You won $reward coins!'),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
          }
        },
      );
    }

    setState(() {
      _isSpinning = false;
    });
    adProvider.loadRewardedAd();
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final dailySpinLimit = configProvider.appConfig['dailySpinLimit'] ?? 3;
    final spinsUsed = userProvider.getTodayStats()?['spinsUsed'] ?? 0;
    final isTabletOrDesktop = !ResponsiveUtils.isMobile(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Spin & Win',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (isTabletOrDesktop) {
            // Tablet and Desktop layout
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildSpinWheel(constraints.maxWidth * 0.5),
                ),
                Expanded(
                  flex: 2,
                  child: _buildSpinInfo(dailySpinLimit, spinsUsed),
                ),
              ],
            );
          } else {
            // Mobile layout
            return SingleChildScrollView(
              padding: ResponsiveUtils.getResponsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSpinInfo(dailySpinLimit, spinsUsed),
                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context),
                  ),
                  _buildSpinWheel(constraints.maxWidth * 0.9),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSpinInfo(int dailySpinLimit, int spinsUsed) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Iconsax.refresh,
                  color: Theme.of(context).colorScheme.secondary,
                  size: ResponsiveUtils.getResponsiveFontSize(context, 24),
                ),
                SizedBox(
                  width: ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
                ),
                Expanded(
                  child: Text(
                    'Spins Remaining Today: ${dailySpinLimit - spinsUsed} / $dailySpinLimit\nResets at midnight',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (spinsUsed >= dailySpinLimit) ...[
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
              Text(
                'You\'ve used all your spins for today. Come back tomorrow!',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpinWheel(double size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: FortuneWheel(
              physics: CircularPanPhysics(
                duration: const Duration(seconds: 5),
                curve: Curves.decelerate,
              ),
              selected: _wheelNotifier.stream,
              items: _spinRewards.map((value) {
                return FortuneItem(
                  style: FortuneItemStyle(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderColor: Theme.of(context).colorScheme.primary,
                    borderWidth: 2,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '$value\ncoins',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          16,
                        ),
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }).toList(),
              onAnimationEnd: _onSpinEnd,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
          FilledButton.icon(
            onPressed: _isSpinning ? null : _startSpin,
            icon: const Icon(Iconsax.play),
            label: Text(
              _isSpinning ? 'Spinning...' : 'Spin Now',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
              ),
            ),
            style: FilledButton.styleFrom(
              minimumSize: Size(
                200,
                ResponsiveUtils.getResponsiveFontSize(context, 56),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
