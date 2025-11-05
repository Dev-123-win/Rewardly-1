import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/settings_provider.dart';
import '../widgets/custom_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  static const String routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Settings',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Enable Notifications',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  secondary: const Icon(Iconsax.notification),
                  value: settingsProvider.notificationsEnabled,
                  onChanged: (bool value) {
                    settingsProvider.toggleNotifications(value);
                  },
                ),
                const Divider(indent: 56),
                SwitchListTile(
                  title: Text(
                    'Dark Mode',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  secondary: const Icon(Iconsax.moon),
                  value: settingsProvider.darkModeEnabled,
                  onChanged: (bool value) {
                    settingsProvider.toggleDarkMode(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'App Version 1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
