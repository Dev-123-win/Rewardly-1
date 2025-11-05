import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/ad_provider.dart';
import '../providers/user_provider.dart';
import '../providers/config_provider.dart';
import '../widgets/custom_app_bar.dart';

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
              elevation: 0,
              color: Theme.of(context).colorScheme.primary,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Today\'s Earnings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withAlpha(204),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.coin,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${userProvider.currentUser?.coinBalance ?? 0}',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: adsWatched / dailyAdLimit,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withAlpha(51),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$adsWatched of $dailyAdLimit ads watched',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withAlpha(204),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Daily Limit Info
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.info_circle,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Daily Limit: $dailyAdLimit ads\nEach ad earns you $adReward coins • Resets at midnight',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Watch Ad Now Button
            FilledButton.icon(
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
                          SnackBar(
                            content: Text(
                              'Ad not ready. Please try again in a moment.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainer,
                          ),
                        );
                        adProvider.loadRewardedAd();
                      }
                    }
                  : null, // Disable button if limit reached
              style: FilledButton.styleFrom(
                textStyle: Theme.of(context).textTheme.titleMedium,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
              ),
              icon: const Icon(Iconsax.play_circle, size: 24),
              label: Text(
                adsWatched < dailyAdLimit
                    ? 'Watch Ad Now\n+$adReward coins per ad'
                    : 'Daily Limit Reached',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Today\'s Activity',
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Iconsax.tick_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  Text(
                    time,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              coins,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
