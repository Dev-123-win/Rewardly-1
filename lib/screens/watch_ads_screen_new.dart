import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../models/ad_milestone.dart';
import '../providers/ad_provider_new.dart';
import '../providers/local_user_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../core/utils/responsive_utils.dart';

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
      Provider.of<AdProviderNew>(context, listen: false).loadRewardedAd();
    });
  }

  Widget _buildMilestoneItem(
    BuildContext context,
    AdMilestone milestone,
    AdProviderNew adProvider,
    LocalUserProvider userProvider,
    bool isDesktop,
    ColorScheme colorScheme,
  ) {
    final bool canWatch = !milestone.isCompleted && !milestone.isLocked;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: canWatch ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            color: canWatch
                ? colorScheme.primaryContainer.withOpacity(0.1)
                : colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: milestone.isCompleted
                      ? colorScheme.primary.withOpacity(0.1)
                      : colorScheme.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  milestone.isCompleted
                      ? Iconsax.tick_circle
                      : Iconsax.video_play,
                  color: milestone.isCompleted
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Iconsax.coin,
                      color: milestone.isCompleted
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+${milestone.reward}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: milestone.isCompleted
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (canWatch)
                ElevatedButton(
                  onPressed: () {
                    if (adProvider.rewardedAd != null) {
                      adProvider.showRewardedAd(
                        onAdEarned: (reward) async {
                          await userProvider.recordAdWatch(reward);
                          adProvider.loadRewardedAd();
                        },
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Ad not ready. Please wait a moment.',
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                          backgroundColor: colorScheme.surfaceVariant,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      adProvider.loadRewardedAd();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Watch Ad'),
                )
              else if (milestone.isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.lock,
                        color: colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Locked',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    LocalUserProvider userProvider,
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
        const SizedBox(height: 24),
        // Info Card
        Card(
          elevation: 2,
          shadowColor: colorScheme.shadow.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: colorScheme.surfaceVariant.withOpacity(0.5),
            ),
            padding: EdgeInsets.all(isDesktop ? 28 : 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.info_circle,
                    color: colorScheme.secondary,
                    size: isDesktop ? 28 : 24,
                  ),
                ),
                SizedBox(width: isDesktop ? 20 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Milestones',
                        style:
                            (isDesktop
                                    ? Theme.of(context).textTheme.titleMedium
                                    : Theme.of(context).textTheme.titleSmall)
                                ?.copyWith(
                                  color: colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete all milestones to maximize your earnings',
                        style:
                            (isDesktop
                                    ? Theme.of(context).textTheme.bodyMedium
                                    : Theme.of(context).textTheme.bodySmall)
                                ?.copyWith(
                                  color: colorScheme.secondary.withOpacity(0.8),
                                  height: 1.5,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Milestones List
        ...adProvider.milestones.map(
          (milestone) => _buildMilestoneItem(
            context,
            milestone,
            adProvider,
            userProvider,
            isDesktop,
            colorScheme,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<LocalUserProvider>(context);
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
