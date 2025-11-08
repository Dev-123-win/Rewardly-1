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
      appBar: const CustomAppBar(title: 'Invite & Earn'),
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
                  elevation: 2,
                  shadowColor: Theme.of(
                    context,
                  ).colorScheme.shadow.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.shadow
                                        .withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Iconsax.gift,
                                color: Theme.of(context).colorScheme.primary,
                                size: isDesktop ? 32 : 24,
                              ),
                            ),
                            SizedBox(width: isDesktop ? 16 : 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Referral Code',
                                  style:
                                      (isDesktop
                                              ? Theme.of(
                                                  context,
                                                ).textTheme.headlineSmall
                                              : Theme.of(
                                                  context,
                                                ).textTheme.titleMedium)
                                          ?.copyWith(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Share with friends to earn rewards',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontFamily: 'Inter',
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: isDesktop ? 24 : 16),
                        Container(
                          width: isDesktop ? 400 : double.infinity,
                          padding: EdgeInsets.all(isDesktop ? 24 : 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).colorScheme.primaryContainer
                                    .withValues(alpha: 0.7),
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.2),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.shadow.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.document_copy,
                                    size: isDesktop ? 24 : 20,
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tap to copy',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.7),
                                          fontFamily: 'Inter',
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SelectableText(
                                referralCode,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.bold,
                                      fontSize: isDesktop ? 36 : 32,
                                      letterSpacing: 1.2,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
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
                            icon: Icon(
                              Iconsax.share,
                              size: isDesktop ? 24 : 20,
                            ),
                            label: Text('Share Code'),
                            style:
                                FilledButton.styleFrom(
                                  minimumSize: Size(
                                    double.infinity,
                                    isDesktop ? 64 : 56,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isDesktop ? 32 : 24,
                                    vertical: isDesktop ? 20 : 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ).copyWith(
                                  elevation:
                                      WidgetStateProperty.resolveWith<double>((
                                        states,
                                      ) {
                                        if (states.contains(
                                          WidgetState.pressed,
                                        )) {
                                          return 0;
                                        }
                                        return 2;
                                      }),
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
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withOpacity(0.5),
                                      Theme.of(context).colorScheme.surface,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .shadow
                                          .withValues(alpha: 0.05),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Iconsax.people,
                                  size: isDesktop ? 64 : 48,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.5),
                                ),
                              ),
                              SizedBox(height: isDesktop ? 32 : 24),
                              Text(
                                'No referrals yet',
                                style:
                                    (isDesktop
                                            ? Theme.of(
                                                context,
                                              ).textTheme.headlineSmall
                                            : Theme.of(
                                                context,
                                              ).textTheme.titleLarge)
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold,
                                        ),
                              ),
                              SizedBox(height: isDesktop ? 12 : 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Iconsax.share,
                                      size: 20,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Share your code to start earning rewards',
                                      style:
                                          (isDesktop
                                                  ? Theme.of(
                                                      context,
                                                    ).textTheme.titleMedium
                                                  : Theme.of(
                                                      context,
                                                    ).textTheme.bodyLarge)
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                                fontFamily: 'Inter',
                                              ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: userProvider.referredUsers.length,
                          itemBuilder: (context, index) {
                            final Map<String, dynamic> referredUser =
                                userProvider.referredUsers[index];
                            final int activeDays =
                                referredUser['refereeActiveDays'] ?? 0;
                            final bool rewarded =
                                referredUser['referrerRewarded'] ?? false;

                            return Card(
                              margin: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 0 : 16,
                                vertical: 8,
                              ),
                              elevation: 2,
                              shadowColor: Theme.of(
                                context,
                              ).colorScheme.shadow.withOpacity(0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Theme.of(context).colorScheme.surface,
                                      Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withOpacity(0.5),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(isDesktop ? 20 : 16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: isDesktop ? 56 : 48,
                                        height: isDesktop ? 56 : 48,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Theme.of(
                                                context,
                                              ).colorScheme.secondaryContainer,
                                              Theme.of(context)
                                                  .colorScheme
                                                  .secondary
                                                  .withOpacity(0.1),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .shadow
                                                  .withValues(alpha: 0.05),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            (referredUser['refereeId'] ??
                                                    'U')[0]
                                                .toUpperCase(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.secondary,
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              referredUser['refereeId'] ??
                                                  'Unknown User',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Iconsax.calendar,
                                                  size: 16,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Active Days: ',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                        fontFamily: 'Inter',
                                                      ),
                                                ),
                                                Text(
                                                  '$activeDays / 3',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                        fontFamily: 'Inter',
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: rewarded
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primaryContainer
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              rewarded
                                                  ? Iconsax.tick_circle
                                                  : Iconsax.timer_1,
                                              size: 16,
                                              color: rewarded
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              rewarded ? 'Rewarded' : 'Pending',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                                  ?.copyWith(
                                                    color: rewarded
                                                        ? Theme.of(
                                                            context,
                                                          ).colorScheme.primary
                                                        : Theme.of(context)
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w600,
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
