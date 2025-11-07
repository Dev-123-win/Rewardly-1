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

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 4,
          shadowColor: colorScheme.shadow.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withBlue(
                    (colorScheme.primary.blue * 0.8).round(),
                  ),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0),
              child: Column(
                children: [
                  // Title
                  Text(
                    'Today\'s Earnings',
                    style:
                        (isDesktop
                                ? Theme.of(context).textTheme.headlineSmall
                                : Theme.of(context).textTheme.titleMedium)
                            ?.copyWith(
                              fontFamily: 'Inter',
                              color: colorScheme.onPrimary.withOpacity(0.9),
                              letterSpacing: 0.5,
                            ),
                  ),
                  SizedBox(height: isDesktop ? 24 : 16),

                  // Coin Balance
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 24,
                      vertical: isDesktop ? 24 : 16,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.onPrimary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Iconsax.coin,
                            color: colorScheme.onPrimary,
                            size: isDesktop ? 36 : 28,
                          ),
                        ),
                        SizedBox(width: isDesktop ? 20 : 16),
                        Text(
                          '${userProvider.currentUser?.coins ?? 0}',
                          style:
                              (isDesktop
                                      ? Theme.of(
                                          context,
                                        ).textTheme.displayMedium
                                      : Theme.of(
                                          context,
                                        ).textTheme.displaySmall)
                                  ?.copyWith(
                                    fontFamily: 'Inter',
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isDesktop ? 32 : 24),

                  // Progress Section
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: isDesktop ? 16 : 14,
                              color: colorScheme.onPrimary.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$adsWatched of $dailyAdLimit ads',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: isDesktop ? 16 : 14,
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: adsWatched / dailyAdLimit,
                          backgroundColor: colorScheme.onPrimary.withOpacity(
                            0.2,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                          minHeight: isDesktop ? 10 : 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.secondaryContainer,
                  colorScheme.secondaryContainer.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
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
                        'Daily Limit: $dailyAdLimit ads',
                        style:
                            (isDesktop
                                    ? Theme.of(context).textTheme.titleMedium
                                    : Theme.of(context).textTheme.titleSmall)
                                ?.copyWith(
                                  fontFamily: 'Inter',
                                  color: colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Each ad earns you $adReward coins • Resets at midnight',
                        style:
                            (isDesktop
                                    ? Theme.of(context).textTheme.bodyMedium
                                    : Theme.of(context).textTheme.bodySmall)
                                ?.copyWith(
                                  fontFamily: 'Inter',
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
        SizedBox(height: isDesktop ? 32 : 24),
        Center(
          child: Card(
            elevation: adsWatched < dailyAdLimit ? 4 : 0,
            shadowColor: colorScheme.shadow.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              width: isDesktop ? 400 : double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: adsWatched < dailyAdLimit
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
                  onTap: adsWatched < dailyAdLimit
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
                            color: adsWatched < dailyAdLimit
                                ? colorScheme.onPrimary.withOpacity(0.2)
                                : colorScheme.onSurfaceVariant.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Iconsax.play_circle,
                            size: isDesktop ? 32 : 28,
                            color: adsWatched < dailyAdLimit
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(width: isDesktop ? 20 : 16),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              adsWatched < dailyAdLimit
                                  ? 'Watch Ad Now'
                                  : 'Daily Limit Reached',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: isDesktop ? 18 : 16,
                                fontWeight: FontWeight.w600,
                                color: adsWatched < dailyAdLimit
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (adsWatched < dailyAdLimit) ...[
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

    final int adsWatched = userProvider.getTodayStats()?['adsWatched'] ?? 0;
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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.symmetric(vertical: isDesktop ? 8 : 6),
      elevation: 2,
      shadowColor: colorScheme.shadow.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: isDesktop ? 56 : 48,
              height: isDesktop ? 56 : 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Iconsax.tick_circle,
                color: colorScheme.primary,
                size: isDesktop ? 32 : 28,
              ),
            ),
            SizedBox(width: isDesktop ? 20 : 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        (isDesktop
                                ? Theme.of(context).textTheme.titleLarge
                                : Theme.of(context).textTheme.titleMedium)
                            ?.copyWith(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style:
                        (isDesktop
                                ? Theme.of(context).textTheme.titleSmall
                                : Theme.of(context).textTheme.bodySmall)
                            ?.copyWith(
                              fontFamily: 'Inter',
                              color: colorScheme.onSurfaceVariant,
                            ),
                  ),
                ],
              ),
            ),
            // Coins
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 20 : 16,
                vertical: isDesktop ? 12 : 8,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.coin,
                    size: isDesktop ? 20 : 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    coins,
                    style:
                        (isDesktop
                                ? Theme.of(context).textTheme.titleMedium
                                : Theme.of(context).textTheme.titleSmall)
                            ?.copyWith(
                              fontFamily: 'Inter',
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
