import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ad_provider.dart';
import '../providers/user_provider.dart';
import '../providers/config_provider.dart';

class SpinAndWinScreen extends StatefulWidget {
  const SpinAndWinScreen({super.key});

  @override
  State<SpinAndWinScreen> createState() => _SpinAndWinScreenState();
}

class _SpinAndWinScreenState extends State<SpinAndWinScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<AdProvider>(context, listen: false).loadRewardedAd();
  }

  @override
  Widget build(BuildContext context) {
    final adProvider = Provider.of<AdProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final int spinRewardAmount = configProvider.getConfig('rewards.spinReward', defaultValue: 4);
    final int dailySpinLimit = configProvider.getConfig('dailySpinLimit', defaultValue: 3);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spin & Win'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: adProvider.isRewardedAdReady
                  ? () {
                      adProvider.showRewardedAd(() {
                        userProvider.spinAndEarnCoins(spinRewardAmount, dailySpinLimit);
                      });
                    }
                  : null,
              child: const Text('Spin to Earn Coins'),
            ),
            if (!adProvider.isRewardedAdReady)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Ad is loading...'),
              ),
          ],
        ),
      ),
    );
  }
}
