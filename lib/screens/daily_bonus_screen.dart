import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/user_provider.dart';
import '../providers/ad_provider_new.dart';
import '../widgets/custom_app_bar.dart';

class DailyBonusScreen extends StatefulWidget {
  static const String routeName = '/daily-bonus';

  const DailyBonusScreen({super.key});

  @override
  State<DailyBonusScreen> createState() => _DailyBonusScreenState();
}

class _DailyBonusScreenState extends State<DailyBonusScreen> {
  bool _isClaimingReward = false;

  Future<void> _claimDailyReward(int currentStreak) async {
    if (_isClaimingReward) return;

    setState(() {
      _isClaimingReward = true;
    });

    final adProvider = Provider.of<AdProviderNew>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Show rewarded ad
    if (adProvider.rewardedAd != null) {
      await adProvider.showRewardedAd(
        onAdEarned: (reward) async {
          // Update user's coins and streak
          await userProvider.recordGameReward(
            gameType: 'dailyBonus',
            amount: 10, // 10 coins per day
          );

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You claimed 10 coins for Day $currentStreak!'),
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Reset streak if completed 7 days
          if (currentStreak >= 7) {
            await userProvider.resetDailyStreak();
          } else {
            await userProvider.incrementDailyStreak();
          }

          setState(() {
            _isClaimingReward = false;
          });
          adProvider.loadRewardedAd(); // Load next ad
        },
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait while we prepare your reward...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      adProvider.loadRewardedAd();
      setState(() {
        _isClaimingReward = false;
      });
    }
  }

  Widget _buildStreakCard(ColorScheme colorScheme, int currentStreak) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.timer_1,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Streak',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Day $currentStreak of 7',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: currentStreak / 7,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard(
    BuildContext context,
    int day,
    bool isCurrent,
    bool isClaimed,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: isCurrent
          ? colorScheme.primaryContainer.withOpacity(0.7)
          : colorScheme.surface,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrent
                    ? colorScheme.primary.withOpacity(0.1)
                    : colorScheme.surfaceVariant.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isClaimed ? Iconsax.tick_circle : Iconsax.gift,
                color: isClaimed
                    ? colorScheme.primary
                    : isCurrent
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Day $day',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isCurrent
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.coin,
                  size: 14,
                  color: isCurrent
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '10',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isCurrent
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final userProvider = Provider.of<UserProvider>(context);
    final currentStreak = userProvider.currentUser?.dailyStreak ?? 1;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final hasClaimedToday =
        userProvider.currentUser?.dailyStats[today]?['dailyBonusClaimed'] ??
        false;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Daily Bonus',
        onBack: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStreakCard(colorScheme, currentStreak),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '7 Day Rewards',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(7, (index) {
                          final day = index + 1;
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index < 6 ? 12.0 : 0,
                            ),
                            child: _buildRewardCard(
                              context,
                              day,
                              day == currentStreak,
                              day < currentStreak || hasClaimedToday,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: hasClaimedToday || _isClaimingReward
                          ? null
                          : () => _claimDailyReward(currentStreak),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(
                        _isClaimingReward
                            ? Icons.hourglass_empty
                            : hasClaimedToday
                            ? Iconsax.tick_circle
                            : Iconsax.gift,
                      ),
                      label: Text(
                        _isClaimingReward
                            ? 'Claiming...'
                            : hasClaimedToday
                            ? 'Already Claimed'
                            : 'Claim Daily Reward',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
