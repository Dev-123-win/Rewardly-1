import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../core/utils/responsive_utils.dart';
import 'help_support_screen.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  static const String routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = ResponsiveUtils.getResponsivePadding(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Profile'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: ResponsiveUtils.isDesktop(context)
                    ? 800
                    : ResponsiveUtils.isTablet(context)
                    ? 600
                    : screenWidth,
              ),
              child: ListView(
                padding: padding,
                children: [
                  Card(
                    elevation: 2,
                    shadowColor: Theme.of(
                      context,
                    ).colorScheme.shadow.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withOpacity(0.2),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(
                              context,
                            ).colorScheme.primaryContainer.withOpacity(0.7),
                            Theme.of(context).colorScheme.surface,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: EdgeInsets.all(
                        ResponsiveUtils.isDesktop(context) ? 32 : 24,
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.1),
                                      Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.2),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.shadow.withOpacity(0.1),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(4),
                                child: CircleAvatar(
                                  radius: ResponsiveUtils.isDesktop(context)
                                      ? 48
                                      : 36,
                                  backgroundImage: NetworkImage(
                                    currentUser?.photoURL ??
                                        'https://via.placeholder.com/150',
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Iconsax.verify5,
                                    size: ResponsiveUtils.isDesktop(context)
                                        ? 20
                                        : 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: ResponsiveUtils.isDesktop(context) ? 32 : 24,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentUser?.displayName ?? 'No Name',
                                  style:
                                      (ResponsiveUtils.isDesktop(context)
                                              ? Theme.of(
                                                  context,
                                                ).textTheme.headlineMedium
                                              : Theme.of(
                                                  context,
                                                ).textTheme.titleLarge)
                                          ?.copyWith(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currentUser?.email ?? 'No Email',
                                  style:
                                      (ResponsiveUtils.isDesktop(context)
                                              ? Theme.of(
                                                  context,
                                                ).textTheme.titleMedium
                                              : Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge)
                                          ?.copyWith(
                                            fontFamily: 'Inter',
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondaryContainer
                                            .withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Iconsax.star1,
                                            size:
                                                ResponsiveUtils.isDesktop(
                                                  context,
                                                )
                                                ? 20
                                                : 16,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Premium User',
                                            style:
                                                (ResponsiveUtils.isDesktop(
                                                          context,
                                                        )
                                                        ? Theme.of(
                                                            context,
                                                          ).textTheme.titleSmall
                                                        : Theme.of(context)
                                                              .textTheme
                                                              .bodyMedium)
                                                    ?.copyWith(
                                                      fontFamily: 'Inter',
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.secondary,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveUtils.isDesktop(context) ? 24 : 16,
                  ),
                  Card(
                    elevation: 2,
                    shadowColor: Theme.of(
                      context,
                    ).colorScheme.shadow.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withOpacity(0.2),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.isDesktop(context) ? 16 : 12,
                      ),
                      child: Column(
                        children: <Widget>[
                          _buildSwitchListTile(
                            context,
                            'Enable Notifications',
                            Iconsax.notification,
                            Provider.of<SettingsProvider>(
                              context,
                            ).notificationsEnabled,
                            (value) => Provider.of<SettingsProvider>(
                              context,
                              listen: false,
                            ).toggleNotifications(value),
                            showDivider: true,
                          ),
                          _buildListTile(
                            context,
                            'Payment Methods',
                            Iconsax.wallet_3,
                            () {
                              /* TODO: Navigate to Payment Methods screen */
                            },
                            showDivider: true,
                          ),
                          _buildListTile(
                            context,
                            'Help & Support',
                            Iconsax.message_question,
                            () => Navigator.pushNamed(
                              context,
                              HelpSupportScreen.routeName,
                            ),
                            showDivider: true,
                          ),
                          _buildListTile(
                            context,
                            'Logout',
                            Iconsax.logout,
                            () async {
                              await authProvider.signOut();
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) => const AuthScreen(),
                                  ),
                                  (Route<dynamic> route) => false,
                                );
                              }
                            },
                            isError: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.isDesktop(context) ? 32 : 16),
          child: Text(
            'Version 1.0.0',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchListTile(
    BuildContext context,
    String title,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged, {
    bool showDivider = false,
  }) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 24,
            vertical: isDesktop ? 12 : 8,
          ),
          secondary: Container(
            width: isDesktop ? 48 : 40,
            height: isDesktop ? 48 : 40,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: isDesktop ? 24 : 20,
            ),
          ),
          title: Text(
            title,
            style:
                (isDesktop
                        ? Theme.of(context).textTheme.titleMedium
                        : Theme.of(context).textTheme.bodyLarge)
                    ?.copyWith(
                      color: colorScheme.onSurface,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
          ),
          value: value,
          onChanged: onChanged,
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 24),
            child: Divider(
              color: colorScheme.outlineVariant.withOpacity(0.2),
              height: 1,
            ),
          ),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isError = false,
    bool showDivider = false,
  }) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 24,
            vertical: isDesktop ? 12 : 8,
          ),
          leading: Container(
            width: isDesktop ? 48 : 40,
            height: isDesktop ? 48 : 40,
            decoration: BoxDecoration(
              color: isError
                  ? Theme.of(
                      context,
                    ).colorScheme.errorContainer.withOpacity(0.2)
                  : Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isError
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              size: isDesktop ? 24 : 20,
            ),
          ),
          title: Text(
            title,
            style:
                (isDesktop
                        ? Theme.of(context).textTheme.titleMedium
                        : Theme.of(context).textTheme.bodyLarge)
                    ?.copyWith(
                      color: isError
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurface,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
          ),
          trailing: Icon(
            Iconsax.arrow_right_3,
            size: isDesktop ? 24 : 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 24),
            child: Divider(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withOpacity(0.2),
              height: 1,
            ),
          ),
      ],
    );
  }
}
