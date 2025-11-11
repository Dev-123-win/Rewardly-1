import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ad_provider_new.dart';
import '../providers/local_user_provider.dart'; // Import LocalUserProvider
import '../widgets/custom_app_bar.dart';

class DailyBonusScreen extends StatefulWidget {
  static const String routeName = '/daily-bonus';

  const DailyBonusScreen({super.key});

  @override
  State<DailyBonusScreen> createState() => _DailyBonusScreenState();
}

class _DailyBonusScreenState extends State<DailyBonusScreen> {
  bool _isClaimingReward = false;

  @override
  void initState() {
    super.initState();
    // Removed ad loading from initState as per user feedback.
    // Will re-evaluate ad loading after functionality changes.
  }

  bool _getHasClaimedToday(LocalUserProvider localUserProvider) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return localUserProvider.currentUser?.dailyStats[today]?['dailyBonusClaimed'] ?? false;
  }

  // Helper to determine if a specific day (1-7) in the streak cycle is claimed
  bool _getHasClaimedForDisplayDay(int displayDay, LocalUserProvider localUserProvider, int currentStreak) {
    final currentUser = localUserProvider.currentUser;
    if (currentUser == null) return false;

    final today = DateTime.now();
    final todayString = today.toIso8601String().substring(0, 10);

    // Check if the bonus for the *actual current day* has been claimed
    final bool hasClaimedToday = currentUser.dailyStats[todayString]?['dailyBonusClaimed'] ?? false;

    if (displayDay < currentStreak) {
      // For past days in the streak, they are considered claimed.
      // This assumes the streak is correctly maintained by LocalUserProvider.
      return true;
    } else if (displayDay == currentStreak) {
      // For the current day in the streak, it's claimed if hasClaimedToday is true.
      return hasClaimedToday;
    }
    // For future days in the streak, they are not claimed.
    return false;
  }

  Future<void> _claimDailyReward(int dayToClaim) async {
    // Only allow claiming if it's the current streak day and not already claimed today
    final localUserProvider = Provider.of<LocalUserProvider>(context, listen: false);
    final currentStreak = localUserProvider.currentUser?.dailyStreak ?? 1;
    final hasClaimedToday = _getHasClaimedToday(localUserProvider);

    if (_isClaimingReward || dayToClaim != currentStreak || hasClaimedToday) return;

    setState(() {
      _isClaimingReward = true;
    });

    final adProvider = Provider.of<AdProviderNew>(context, listen: false);
    const int coinsToAward = 10; // Daily reward amount

    try {
      // 1. Collect coins and update streak immediately via LocalUserProvider
      await localUserProvider.claimDailyReward(coinsToAward);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You claimed $coinsToAward coins for Day $dayToClaim!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // 2. After snackbar, show rewarded ad. AdProviderNew handles preloading.
      await adProvider.showRewardedAd(
        onAdEarned: (reward) {
          // Ad earned, but coins are already given by claimDailyReward.
          // This callback can be used for additional rewards if needed.
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error claiming reward: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isClaimingReward = false;
      });
      // AdProviderNew handles preloading internally, no need to explicitly call loadRewardedAd here.
    }
  }

  Widget _buildStreakCard(ColorScheme colorScheme, int currentStreak) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer.withOpacity(0.3),
                    colorScheme.surfaceVariant.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Streak',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Day $currentStreak ',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                                TextSpan(
                                  text: 'of 7',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Stack(
                  children: [
                    // Background progress
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: colorScheme.surfaceVariant.withOpacity(0.5),
                      ),
                    ),
                    // Animated progress
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      tween: Tween(
                        begin: 0,
                        end: currentStreak / 7,
                      ),
                      builder: (context, value, _) => Container(
                        height: 12,
                        width: MediaQuery.of(context).size.width * value * 0.7,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withBlue(
                                ((colorScheme.primary.blue * 1.2).clamp(0, 255)).toInt(),
                              ),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(
    BuildContext context,
    int day,
    bool isCurrent,
    bool isClaimed,
    bool hasClaimedToday, // Add hasClaimedToday parameter
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isCompleted = isClaimed && !isCurrent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.transparent, // Make the card background transparent
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isClaimed ? colorScheme.primaryContainer.withOpacity(0.7) : null, // Filled if claimed
            gradient: isCurrent && !isClaimed
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      colorScheme.primaryContainer.withOpacity(0.7),
                      colorScheme.primaryContainer.withOpacity(0.3),
                    ],
                  )
                : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: isCurrent && !hasClaimedToday && !_isClaimingReward
                ? () => _claimDailyReward(day)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Left side - Day indicator and status
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isCurrent
                              ? colorScheme.primary
                              : colorScheme.surfaceVariant)
                          .withOpacity(0.15),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated container for current day
                        if (isCurrent)
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.easeInOut,
                            tween: Tween(begin: 0.8, end: 1.2),
                            builder: (context, value, _) => Transform.scale(
                              scale: value,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.primary.withOpacity(0.2),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'DAY',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isCurrent
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                            ),
                            Text(
                              day.toString(),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: isCurrent
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Middle - Reward info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: (isCurrent
                                        ? colorScheme.primary
                                        : colorScheme.surfaceVariant)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.monetization_on_rounded,
                                    size: 16,
                                    color: isCurrent
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '10 coins',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                          color: isCurrent
                                              ? colorScheme.primary
                                              : colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCompleted
                              ? 'Completed'
                              : (isCurrent
                                  ? 'Available to claim'
                                  : 'Unlock by maintaining streak'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isCompleted
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Right side - Status icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? colorScheme.primaryContainer
                          : (isCurrent
                              ? colorScheme.primary
                              : colorScheme.surfaceVariant.withOpacity(0.5)),
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle_outline_rounded
                          : (isCurrent
                              ? Icons.card_giftcard_rounded
                              : Icons.lock_outline_rounded),
                      color: isCompleted
                          ? colorScheme.primary
                          : (isCurrent
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localUserProvider = Provider.of<LocalUserProvider>(context); // Listen to changes
    final currentStreak = localUserProvider.currentUser?.dailyStreak ?? 1;
    final hasClaimedToday = _getHasClaimedToday(localUserProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Daily Bonus',
        onBack: () => Navigator.pop(context),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceVariant.withOpacity(0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStreakCard(colorScheme, currentStreak),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: colorScheme.surface,
                    border: Border.all(
                      color: colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weekly Rewards',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Complete daily tasks to earn rewards',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: List.generate(7, (index) {
                            final day = index + 1;
                            final bool isCurrentDayInStreak = day == currentStreak;
                            final bool isDayClaimed = _getHasClaimedForDisplayDay(day, localUserProvider, currentStreak);

                            return _buildRewardCard(
                              context,
                              day,
                              isCurrentDayInStreak,
                              isDayClaimed,
                              hasClaimedToday,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
