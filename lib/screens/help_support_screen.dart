import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart'; // Import CustomAppBar

class HelpSupportScreen extends StatelessWidget {
  static const String routeName = '/help-support';

  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Help & Support',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Frequently Asked Questions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ExpansionTile(
              leading: Icon(
                Icons.monetization_on_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'How do I earn coins?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'You can earn coins by:\n\n'
                    '• Claiming your daily reward\n'
                    '• Watching video ads\n'
                    '• Spinning the wheel\n'
                    '• Playing Tic-Tac-Toe\n',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ExpansionTile(
              leading: Icon(
                Icons.account_balance_wallet_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'How do I withdraw my earnings?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'You can withdraw your earnings once you have reached the minimum withdrawal amount. Go to the Withdraw screen and follow the instructions.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ExpansionTile(
              leading: Icon(
                Icons.people_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'How does the referral system work?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Share your referral code with your friends. When they sign up using your code, you will both receive bonus coins.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Contact Us',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Icon(
                Icons.email_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Contact Support',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: const Text('We\'re here to help you'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Add contact support functionality
              },
            ),
          ),
        ],
      ),
    );
  }
}
