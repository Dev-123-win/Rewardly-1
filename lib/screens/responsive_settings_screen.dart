import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/settings_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../core/utils/responsive_utils.dart';

class SettingsScreen extends StatelessWidget {
  static const String routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = ResponsiveUtils.getResponsivePadding(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Settings',
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
                    child: Column(
                      children: [
                        _buildSwitchListTile(
                          context,
                          'Enable Notifications',
                          Iconsax.notification,
                          settingsProvider.notificationsEnabled,
                          (value) =>
                              settingsProvider.toggleNotifications(value),
                        ),
                        Divider(indent: isDesktop ? 72 : 56),
                        _buildSwitchListTile(
                          context,
                          'Dark Mode',
                          Iconsax.moon,
                          settingsProvider.darkModeEnabled,
                          (value) => settingsProvider.toggleDarkMode(value),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isDesktop ? 32 : 24),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 24 : 16,
                    ),
                    child: Text(
                      'App Version 1.0.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
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

  Widget _buildSwitchListTile(
    BuildContext context,
    String title,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return SwitchListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: isDesktop ? 8 : 4,
      ),
      title: Text(
        title,
        style: isDesktop
            ? Theme.of(context).textTheme.titleMedium
            : Theme.of(context).textTheme.bodyLarge,
      ),
      secondary: Icon(icon, size: isDesktop ? 28 : 24),
      value: value,
      onChanged: onChanged,
    );
  }
}
