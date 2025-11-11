import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/ad_provider_new.dart';
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
  late SharedPreferences _prefs;
  int _spinsUsedToday = 0;
  int _coins = 0;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    // AdProviderNew now preloads ads in its constructor, so no need to call loadRewardedAd here.
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSpinData();
  }

  void _loadSpinData() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    setState(() {
      _spinsUsedToday = _prefs.getInt('spinsUsed_$today') ?? 0;
      _coins = _prefs.getInt('coins') ?? 0;
    });
  }

  Future<void> _updateSpinsUsed(int count) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _prefs.setInt('spinsUsed_$today', count);
    _loadSpinData();
  }

  Future<void> _updateCoins(int amount) async {
    _coins += amount;
    await _prefs.setInt('coins', _coins);
    _loadSpinData();
  }

  @override
  void dispose() {
    _wheelNotifier.close();
    super.dispose();
  }

  void _startSpin() {
    if (_isSpinning) return;

    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final dailySpinLimit = configProvider.appConfig['dailySpinLimit'] ?? 3;

    if (_spinsUsedToday >= dailySpinLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have used all your spins for today!'),
        ),
      );
      return;
    }

    final adProvider = Provider.of<AdProviderNew>(context, listen: false);
    if (adProvider.rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait while we prepare your reward...'),
        ),
      );
      // AdProviderNew now handles preloading internally.
      // adProvider.loadRewardedAd(); // No longer needed here
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
    final adProvider = Provider.of<AdProviderNew>(context, listen: false);

    if (adProvider.rewardedAd != null) {
      adProvider.showRewardedAd(
        onAdEarned: (adReward) async {
          try {
            await _updateCoins(reward);
            await _updateSpinsUsed(_spinsUsedToday + 1);
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
    // AdProviderNew handles preloading internally, no need to explicitly call loadRewardedAd here.
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    final dailySpinLimit = configProvider.appConfig['dailySpinLimit'] ?? 3;
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
                  child: _buildSpinInfo(dailySpinLimit, _spinsUsedToday),
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
                  _buildSpinInfo(dailySpinLimit, _spinsUsedToday),
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
