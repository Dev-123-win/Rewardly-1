import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ad_provider.dart';
import '../providers/user_provider.dart';
import '../providers/config_provider.dart';

class WatchAdsScreen extends StatefulWidget {
  const WatchAdsScreen({super.key});

  @override
  State<WatchAdsScreen> createState() => _WatchAdsScreenState();
}

class _WatchAdsScreenState extends State<WatchAdsScreen> {
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
    final int adRewardAmount = configProvider.getConfig('rewards.adReward', defaultValue: 4);
    final int dailyAdLimit = configProvider.getConfig('dailyAdLimit', defaultValue: 10);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch Ads'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: adProvider.isRewardedAdReady
                  ? () {
                      adProvider.showRewardedAd(() {
                        userProvider.watchAdAndEarnCoins(adRewardAmount, dailyAdLimit);
                      });
                    }
                  : null,
              child: const Text('Watch Ad to Earn Coins'),
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
