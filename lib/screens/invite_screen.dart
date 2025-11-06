import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../core/utils/responsive_utils.dart';

class InviteScreen extends StatelessWidget {
  static const String routeName = '/invite';

  const InviteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final String referralCode = userProvider.referralCode ?? 'Generating...';

    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = isDesktop
        ? 1200.0
        : isTablet
        ? 800.0
        : screenWidth;
    final padding = ResponsiveUtils.getResponsivePadding(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Invite & Earn',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isDesktop ? 24 : 16,
              horizontal: padding.horizontal,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.card_giftcard,
                              color: Theme.of(context).colorScheme.primary,
                              size: isDesktop ? 32 : 24,
                            ),
                            SizedBox(width: isDesktop ? 16 : 12),
                            Text(
                              'Your Referral Code',
                              style: isDesktop
                                  ? Theme.of(context).textTheme.headlineSmall
                                  : Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        SizedBox(height: isDesktop ? 24 : 16),
                        Container(
                          width: isDesktop ? 400 : double.infinity,
                          padding: EdgeInsets.all(isDesktop ? 24 : 16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(
                              isDesktop ? 16 : 12,
                            ),
                          ),
                          child: SelectableText(
                            referralCode,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isDesktop ? 36 : null,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: isDesktop ? 32 : 24),
                        SizedBox(
                          width: isDesktop ? 400 : double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: () {
                              Share.share(
                                'Join our app and get 200 bonus coins! Use my referral code: $referralCode',
                              );
                            },
                            icon: Icon(Iconsax.share, size: isDesktop ? 24 : 20),
                            label: Text('Share Code'),
                            style: FilledButton.styleFrom(
                              minimumSize: Size(
                                double.infinity,
                                isDesktop ? 64 : 56,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 32 : 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isDesktop ? 32 : 24),
                Padding(
                  padding: EdgeInsets.zero,
                  child: Text(
                    'Referred Users',
                    style: isDesktop
                        ? Theme.of(context).textTheme.headlineSmall
                        : Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                SizedBox(height: isDesktop ? 16 : 8),
                Expanded(
                  child: userProvider.referredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: isDesktop ? 64 : 48,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              SizedBox(height: isDesktop ? 24 : 16),
                              Text(
                                'No referrals yet',
                                style:
                                    (isDesktop
                                            ? Theme.of(
                                                context,
                                              ).textTheme.headlineSmall
                                            : Theme.of(
                                                context,
                                              ).textTheme.titleMedium)
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                              ),
                              SizedBox(height: isDesktop ? 12 : 8),
                              Text(
                                'Share your code to start earning rewards',
                                style:
                                    (isDesktop
                                            ? Theme.of(
                                                context,
                                              ).textTheme.titleMedium
                                            : Theme.of(
                                                context,
                                              ).textTheme.bodyMedium)
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: userProvider.referredUsers.length,
                          itemBuilder: (context, index) {
                            final referredUser =
                                userProvider.referredUsers[index];
                            final int activeDays =
                                referredUser['refereeActiveDays'] ?? 0;
                            final bool rewarded =
                                referredUser['referrerRewarded'] ?? false;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer,
                                  child: Text(
                                    (referredUser['refereeId'] ?? 'U')[0]
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  referredUser['refereeId'] ?? 'Unknown User',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                subtitle: Text(
                                  'Active Days: $activeDays / 3',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: rewarded
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer
                                        : Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    rewarded ? 'Rewarded' : 'Pending',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: rewarded
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.onPrimaryContainer
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              ),
                            );
                          },
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
