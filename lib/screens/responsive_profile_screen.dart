import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider_new.dart';
import '../widgets/custom_app_bar.dart';
import '../core/utils/responsive_utils.dart';

import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  static const String routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProvider = Provider.of<UserProviderNew>(context);
    final currentUser = userProvider.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = ResponsiveUtils.getResponsivePadding(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Profile',
        onBack: () => Navigator.of(context).pop(),
      ),
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
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: Padding(
                      padding: EdgeInsets.all(
                        ResponsiveUtils.isDesktop(context) ? 24 : 16,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: ResponsiveUtils.isDesktop(context)
                                ? 48
                                : 32,
                            backgroundImage: NetworkImage(
                              currentUser?.photoURL ??
                                  'https://via.placeholder.com/150',
                            ),
                          ),
                          SizedBox(
                            width: ResponsiveUtils.isDesktop(context) ? 24 : 16,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentUser?.displayName ?? 'No Name',
                                  style: ResponsiveUtils.isDesktop(context)
                                      ? Theme.of(
                                          context,
                                        ).textTheme.headlineMedium
                                      : Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentUser?.email ?? 'No Email',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
                                      ),
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
                    elevation: 0,
                    child: Column(
                      children: [
                        _buildListTile(
                          context,
                          'Edit Profile',
                          Iconsax.edit,
                          () => Navigator.pushNamed(
                            context,
                            EditProfileScreen.routeName,
                          ),
                        ),
                        _buildListTile(
                          context,
                          'Payment Methods',
                          Iconsax.wallet_3,
                          () {
                            /* TODO: Navigate to Payment Methods screen */
                          },
                        ),
                        _buildListTile(
                          context,
                          'Settings',
                          Iconsax.setting_2,
                          () => Navigator.pushNamed(
                            context,
                            SettingsScreen.routeName,
                          ),
                        ),
                        _buildListTile(
                          context,
                          'Help & Support',
                          Iconsax.message_question,
                          () => Navigator.pushNamed(
                            context,
                            HelpSupportScreen.routeName,
                          ),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isError = false,
  }) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: isDesktop ? 8 : 4,
      ),
      leading: Icon(
        icon,
        color: isError ? Theme.of(context).colorScheme.error : null,
        size: isDesktop ? 28 : 24,
      ),
      title: Text(
        title,
        style:
            (isDesktop
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.bodyLarge)
                ?.copyWith(
                  color: isError ? Theme.of(context).colorScheme.error : null,
                ),
      ),
      onTap: onTap,
    );
  }
}
