import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/ad_provider.dart';
import '../providers/user_provider.dart';
import '../providers/config_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../core/utils/responsive_utils.dart';
import '../data/repositories/local_transaction_repository.dart';

class WatchAdsScreen extends StatefulWidget {
  static const String routeName = '/watch-ads';

  const WatchAdsScreen({super.key});

  @override
  State<WatchAdsScreen> createState() => _WatchAdsScreenState();
}

class _WatchAdsScreenState extends State<WatchAdsScreen> {
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    }
  }

  @override
  void initState() {
    super.initState();
    // Pre-load ad when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdProvider>(context, listen: false).loadRewardedAd();
    });
  }

  Widget _buildMainContent(
    BuildContext context,
    int adsWatched,
    int dailyAdLimit,
    int adReward,
    UserProvider userProvider,
    AdProvider adProvider,
  ) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.primary,
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 32.0 : 20.0),
            child: Column(
              children: [
                Text(
                  'Today\'s Earnings',
                  style:
                      (isDesktop
                              ? Theme.of(context).textTheme.headlineSmall
                              : Theme.of(context).textTheme.titleMedium)
                          ?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withAlpha(204),
                          ),
                ),
                SizedBox(height: isDesktop ? 20 : 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.coin,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: isDesktop ? 48 : 32,
                    ),
                    SizedBox(width: isDesktop ? 16 : 8),
                    Text(
                      '${userProvider.currentUser?.coinBalance ?? 0}',
                      style:
                          (isDesktop
                                  ? Theme.of(context).textTheme.displayMedium
                                  : Theme.of(context).textTheme.displaySmall)
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 24 : 16),
                LinearProgressIndicator(
                  value: adsWatched / dailyAdLimit,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withAlpha(51),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                  minHeight: isDesktop ? 8 : 4,
                ),
                SizedBox(height: isDesktop ? 16 : 8),
                Text(
                  '$adsWatched of $dailyAdLimit ads watched',
                  style:
                      (isDesktop
                              ? Theme.of(context).textTheme.titleLarge
                              : Theme.of(context).textTheme.bodyMedium)
                          ?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withAlpha(204),
                          ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isDesktop ? 32 : 20),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Row(
              children: [
                Icon(
                  Iconsax.info_circle,
                  color: Theme.of(context).colorScheme.secondary,
                  size: isDesktop ? 28 : 24,
                ),
                SizedBox(width: isDesktop ? 16 : 12),
                Expanded(
                  child: Text(
                    'Daily Limit: $dailyAdLimit ads\nEach ad earns you $adReward coins • Resets at midnight',
                    style:
                        (isDesktop
                                ? Theme.of(context).textTheme.titleMedium
                                : Theme.of(context).textTheme.bodyMedium)
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isDesktop ? 32 : 20),
        Center(
          child: SizedBox(
            width: isDesktop ? 400 : double.infinity,
            child: FilledButton.icon(
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
                  : null,
              style: FilledButton.styleFrom(
                textStyle: isDesktop
                    ? Theme.of(context).textTheme.titleLarge
                    : Theme.of(context).textTheme.titleMedium,
                padding: EdgeInsets.symmetric(
                  vertical: isDesktop ? 24 : 16,
                  horizontal: isDesktop ? 32 : 24,
                ),
              ),
              icon: Icon(Iconsax.play_circle, size: isDesktop ? 32 : 24),
              label: Text(
                adsWatched < dailyAdLimit
                    ? 'Watch Ad Now\n+$adReward coins per ad'
                    : 'Daily Limit Reached',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        if (!isDesktop && !isTablet) ...[
          SizedBox(height: isDesktop ? 32 : 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 8 : 4),
            child: Text(
              'Today\'s Activity',
              style: isDesktop
                  ? Theme.of(context).textTheme.headlineSmall
                  : Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SizedBox(height: isDesktop ? 16 : 10),
          Expanded(child: _buildActivityList(context, adReward)),
        ],
      ],
    );
  }

  Widget _buildActivityList(BuildContext context, int adReward) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDesktop) ...[
          Text(
            'Today\'s Activity',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
        ],
        Expanded(
          child: Builder(
            builder: (context) {
              final transactions =
                  LocalTransactionRepository(
                        Provider.of<UserProvider>(
                          context,
                          listen: false,
                        ).sharedPreferences,
                      )
                      .getTransactionsByType('earning')
                      .where(
                        (t) =>
                            t.subType == 'ad' &&
                            t.userId == FirebaseAuth.instance.currentUser?.uid,
                      )
                      .toList()
                    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

              if (transactions.isEmpty) {
                return const Center(child: Text('No ads watched yet today'));
              }

              return ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  final String timeAgo = _getTimeAgo(transaction.timestamp);
                  return _buildActivityItem(
                    'Ad Watched',
                    timeAgo,
                    '+${transaction.amount}',
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final adProvider = Provider.of<AdProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);

    final int adsWatched =
        userProvider.currentUser?.todayStats['adsWatched'] ?? 0;
    final int dailyAdLimit = configProvider.appConfig['dailyAdLimit'] ?? 10;
    final int adReward = configProvider.appConfig['rewards']?['adReward'] ?? 4;

    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = isDesktop
        ? 1200.0
        : isTablet
        ? 800.0
        : screenWidth;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Watch & Earn',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
            child: isDesktop || isTablet
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildMainContent(
                          context,
                          adsWatched,
                          dailyAdLimit,
                          adReward,
                          userProvider,
                          adProvider,
                        ),
                      ),
                      SizedBox(width: isDesktop ? 32 : 24),
                      Expanded(
                        flex: 2,
                        child: _buildActivityList(context, adReward),
                      ),
                    ],
                  )
                : _buildMainContent(
                    context,
                    adsWatched,
                    dailyAdLimit,
                    adReward,
                    userProvider,
                    adProvider,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, String coins) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Card(
      margin: EdgeInsets.symmetric(vertical: isDesktop ? 8 : 4),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Row(
          children: [
            Container(
              width: isDesktop ? 48 : 40,
              height: isDesktop ? 48 : 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
              ),
              child: Icon(
                Iconsax.tick_circle,
                color: Theme.of(context).colorScheme.primary,
                size: isDesktop ? 28 : 24,
              ),
            ),
            SizedBox(width: isDesktop ? 16 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: isDesktop
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    time,
                    style:
                        (isDesktop
                                ? Theme.of(context).textTheme.titleSmall
                                : Theme.of(context).textTheme.bodySmall)
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                  ),
                ],
              ),
            ),
            Text(
              coins,
              style:
                  (isDesktop
                          ? Theme.of(context).textTheme.headlineSmall
                          : Theme.of(context).textTheme.titleMedium)
                      ?.copyWith(
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
