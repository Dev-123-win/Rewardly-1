import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/custom_app_bar.dart';
import '../core/utils/responsive_utils.dart';

class HelpSupportScreen extends StatelessWidget {
  static const String routeName = '/help-support';

  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: 'Help & Support',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: EdgeInsets.symmetric(
              vertical: isDesktop ? 24 : 16,
              horizontal: padding.horizontal,
            ),
            children: [
              Text(
                'Frequently Asked Questions',
                style: isDesktop
                    ? Theme.of(context).textTheme.headlineSmall
                    : Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: isDesktop ? 16 : 8),
              Card(
                margin: EdgeInsets.symmetric(vertical: isDesktop ? 8 : 4),
                child: ExpansionTile(
                  leading: Icon(
                    Iconsax.coin,
                    color: Theme.of(context).colorScheme.primary,
                    size: isDesktop ? 28 : 24,
                  ),
                  title: Text(
                    'How do I earn coins?',
                    style: isDesktop
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.titleMedium,
                  ),
                  iconColor: Theme.of(context).colorScheme.primary,
                  collapsedIconColor: Theme.of(context).colorScheme.primary,
                  tilePadding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                    vertical: isDesktop ? 8 : 4,
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(isDesktop ? 24 : 16),
                      child: Text(
                        'You can earn coins by:\n\n'
                        '• Claiming your daily reward\n'
                        '• Watching video ads\n'
                        '• Spinning the wheel\n'
                        '• Playing Tic-Tac-Toe\n',
                        style:
                            (isDesktop
                                    ? Theme.of(context).textTheme.titleMedium
                                    : Theme.of(context).textTheme.bodyLarge)
                                ?.copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                margin: EdgeInsets.symmetric(vertical: isDesktop ? 8 : 4),
                child: ExpansionTile(
                  leading: Icon(
                    Iconsax.wallet,
                    color: Theme.of(context).colorScheme.primary,
                    size: isDesktop ? 28 : 24,
                  ),
                  title: Text(
                    'How do I withdraw my earnings?',
                    style: isDesktop
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.titleMedium,
                  ),
                  iconColor: Theme.of(context).colorScheme.primary,
                  collapsedIconColor: Theme.of(context).colorScheme.primary,
                  tilePadding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                    vertical: isDesktop ? 8 : 4,
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(isDesktop ? 24 : 16),
                      child: Text(
                        'You can withdraw your earnings once you have reached the minimum withdrawal amount. Go to the Withdraw screen and follow the instructions.',
                        style:
                            (isDesktop
                                    ? Theme.of(context).textTheme.titleMedium
                                    : Theme.of(context).textTheme.bodyLarge)
                                ?.copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                margin: EdgeInsets.symmetric(vertical: isDesktop ? 8 : 4),
                child: ExpansionTile(
                  leading: Icon(
                    Iconsax.people,
                    color: Theme.of(context).colorScheme.primary,
                    size: isDesktop ? 28 : 24,
                  ),
                  title: Text(
                    'How does the referral system work?',
                    style: isDesktop
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.titleMedium,
                  ),
                  iconColor: Theme.of(context).colorScheme.primary,
                  collapsedIconColor: Theme.of(context).colorScheme.primary,
                  tilePadding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                    vertical: isDesktop ? 8 : 4,
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(isDesktop ? 24 : 16),
                      child: Text(
                        'Share your referral code with your friends. When they sign up using your code, you will both receive bonus coins.',
                        style:
                            (isDesktop
                                    ? Theme.of(context).textTheme.titleMedium
                                    : Theme.of(context).textTheme.bodyLarge)
                                ?.copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isDesktop ? 48 : 32),
              Text(
                'Contact Us',
                style: isDesktop
                    ? Theme.of(context).textTheme.headlineSmall
                    : Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: isDesktop ? 16 : 8),
              Card(
                margin: EdgeInsets.symmetric(vertical: isDesktop ? 8 : 4),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                    vertical: isDesktop ? 8 : 4,
                  ),
                  leading: Icon(
                    Iconsax.message,
                    color: Theme.of(context).colorScheme.primary,
                    size: isDesktop ? 28 : 24,
                  ),
                  title: Text(
                    'Contact Support',
                    style: isDesktop
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'We\'re here to help you',
                    style: isDesktop
                        ? Theme.of(context).textTheme.titleMedium
                        : Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Icon(
                    Iconsax.arrow_right_3,
                    size: isDesktop ? 28 : 24,
                  ),
                  onTap: () {
                    // Add contact support functionality
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
