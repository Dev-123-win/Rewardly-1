import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/custom_app_bar.dart'; // Import CustomAppBar

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
        children: [
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: settingsProvider.notificationsEnabled,
            onChanged: (bool value) {
              settingsProvider.toggleNotifications(value);
            },
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: settingsProvider.darkModeEnabled,
            onChanged: (bool value) {
              settingsProvider.toggleDarkMode(value);
            },
          ),
        ],
      ),
    );
  }
}
