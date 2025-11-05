import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ad_provider.dart';
import '../providers/user_provider.dart';
import '../providers/config_provider.dart'; // Import ConfigProvider
import '../widgets/custom_app_bar.dart'; // Assuming a custom app bar for consistency

class WatchAdsScreen extends StatefulWidget {
  static const String routeName = '/watch-ads';

  const WatchAdsScreen({super.key});

  @override
  State<WatchAdsScreen> createState() => _WatchAdsScreenState();
}

class _WatchAdsScreenState extends State<WatchAdsScreen> {
  @override
  void initState() {
    super.initState();
    // Pre-load ad when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdProvider>(context, listen: false).loadRewardedAd();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final adProvider = Provider.of<AdProvider>(context);

    final int adsWatched =
        userProvider.currentUser?.todayStats['adsWatched'] ?? 0;
    final configProvider = Provider.of<ConfigProvider>(context);
    final int dailyAdLimit = configProvider.appConfig['dailyAdLimit'] ?? 10;
    final int adReward = configProvider.appConfig['rewards']?['adReward'] ?? 4;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Watch & Earn',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Today's Earnings Card
            Card(
              color: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      'Today\'s Earnings',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${userProvider.currentUser?.coinBalance ?? 0} coins', // Display current balance
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: adsWatched / dailyAdLimit,
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$adsWatched of $dailyAdLimit ads watched',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Daily Limit Info
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade800),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Daily Limit: $dailyAdLimit ads\nEach ad earns you $adReward coins • Resets at midnight',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Watch Ad Now Button
            ElevatedButton.icon(
              onPressed: adsWatched < dailyAdLimit
                  ? () async {
                      if (adProvider.rewardedAd != null) {
                        adProvider.showRewardedAd(
                          onAdEarned: (reward) async {
                            await userProvider.recordAdWatch(adReward);
                            // Reload ad for next watch
                            adProvider.loadRewardedAd();
                          },
                        );
                      } else {
                        // Ad not loaded, try loading again and show a message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Ad not ready. Please try again in a moment.',
                            ),
                          ),
                        );
                        adProvider.loadRewardedAd();
                      }
                    }
                  : null, // Disable button if limit reached
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
                adsWatched < dailyAdLimit
                    ? 'Watch Ad Now\n+$adReward coins per ad'
                    : 'Daily Limit Reached',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Today\'s Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // List of recent ad watches (mock data for now)
            Expanded(
              child: ListView(
                children: [
                  _buildActivityItem(
                    'Ad Watched',
                    '2 minutes ago',
                    '+$adReward',
                  ),
                  _buildActivityItem(
                    'Ad Watched',
                    '8 minutes ago',
                    '+$adReward',
                  ),
                  _buildActivityItem(
                    'Ad Watched',
                    '15 minutes ago',
                    '+$adReward',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, String coins) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              coins,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
