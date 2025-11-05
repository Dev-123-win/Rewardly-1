import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    final int spinsUsed =
        userProvider.currentUser?.todayStats['spinsUsed'] ?? 0;
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Congratulations!'),
          content: Text('You won $earnedCoins coins!'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);

    final int spinsUsed =
        userProvider.currentUser?.todayStats['spinsUsed'] ?? 0;
    final int dailySpinLimit = configProvider.appConfig['dailySpinLimit'] ?? 3;

    final items = _spinRewards.map((reward) {
      return FortuneItem(
        child: Text(
          reward.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: FortuneItemStyle(
          color: _spinRewards.indexOf(reward) % 2 == 0
              ? Colors.blue.shade400
              : Colors.blue.shade600,
          borderColor: Colors.blue.shade800,
          borderWidth: 3,
        ),
      );
    }).toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Spin & Win',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.refresh, color: Colors.orange.shade800),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Spins Remaining Today: ${dailySpinLimit - spinsUsed} / $dailySpinLimit\nResets at midnight',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                ],
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
                    await Provider.of<UserProvider>(
                      context,
                      listen: false,
                    ).spinAndEarnCoins(earnedCoins, dailySpinLimit);
                    if (!mounted) return;
                    _showRewardDialog(earnedCoins);
                    Provider.of<AdProvider>(
                      context,
                      listen: false,
                    ).loadRewardedAd();
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
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: (spinsUsed < dailySpinLimit && !_isSpinning)
                  ? _startSpin
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 30,
              ),
              label: Text(
                (spinsUsed < dailySpinLimit && !_isSpinning)
                    ? 'Watch Ad to Unlock Spin\nWin 5-100 coins per spin'
                    : 'Daily Spin Limit Reached',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
