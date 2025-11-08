import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/ad_provider_new.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../core/utils/responsive_utils.dart';

class WatchAdsScreen extends StatefulWidget {
  static const String routeName = '/watch-ads';

  const WatchAdsScreen({super.key});

  @override
  State<WatchAdsScreen> createState() => _WatchAdsScreenState();
}

class _WatchAdsScreenState extends State<WatchAdsScreen> {
  // Define reward amount per ad watch
  static const int adReward = 10;

  @override
  void initState() {
    super.initState();
    // Pre-load ad when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdProviderNew>(context, listen: false).loadRewardedAd();
    });
  }

  Widget _buildMainContent(
    BuildContext context,
    UserProvider userProvider,
    AdProviderNew adProvider,
  ) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32.0 : 16.0,
        vertical: isDesktop ? 24.0 : 16.0,
      ),
      children: [
        // Today's Earnings Card
        Card(
          elevation: 4,
          shadowColor: colorScheme.shadow.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Earnings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.coin,
                        color: colorScheme.primary,
                        size: isDesktop ? 32 : 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${adProvider.totalEarnedToday}',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  '${adProvider.adsWatchedToday} of 10 ads finished',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: adProvider.adsWatchedToday / 10,
                  backgroundColor: colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                  minHeight: 8,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isDesktop ? 32 : 24),
        Card(
          elevation: 2,
          shadowColor: colorScheme.shadow.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        SizedBox(height: isDesktop ? 32 : 24),
        ...adProvider.milestones.map((milestone) {
          final bool canWatch = !milestone.isCompleted && !milestone.isLocked;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: canWatch ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: isDesktop ? 400 : double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: !milestone.isCompleted && !milestone.isLocked
                        ? [colorScheme.primaryContainer, colorScheme.primary]
                        : [
                            colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            colorScheme.surfaceContainerHighest,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: adProvider.adsWatchedToday < milestone.requiredWatches
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
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  backgroundColor: colorScheme.surfaceContainer,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                              adProvider.loadRewardedAd();
                            }
                          }
                        : null,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 32 : 24,
                        vertical: isDesktop ? 28 : 24,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: adProvider.adsWatchedToday < adProvider.dailyAdLimit
                                  ? colorScheme.onPrimary.withOpacity(0.2)
                                  : colorScheme.onSurfaceVariant.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Iconsax.play_circle,
                              size: isDesktop ? 32 : 28,
                              color: adProvider.adsWatchedToday < adProvider.dailyAdLimit
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(width: isDesktop ? 20 : 16),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                adProvider.adsWatchedToday < adProvider.dailyAdLimit
                                    ? 'Watch Ad Now'
                                    : 'Daily Limit Reached',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: isDesktop ? 18 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: adProvider.adsWatchedToday < adProvider.dailyAdLimit
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (adProvider.adsWatchedToday < adProvider.dailyAdLimit) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '+$adReward coins per ad',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: isDesktop ? 14 : 12,
                                    color: colorScheme.onPrimary.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        if (!isDesktop && !ResponsiveUtils.isTablet(context)) ...[
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
          _buildActivityList(context, adReward),
        ],
      ],
    );
  }

  Widget _buildActivityList(BuildContext context, int adReward) {
    // Placeholder implementation for _buildActivityList
    // You would typically fetch and display actual activity data here.
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: const Text('No activity to display yet.'),
    );
  }

  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final adProvider = Provider.of<AdProviderNew>(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = isDesktop ? 800.0 : screenWidth;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Watch & Earn',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: _buildMainContent(context, userProvider, adProvider),
        ),
      ),
    );
  }
}
