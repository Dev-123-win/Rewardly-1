import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/user_provider.dart';
import '../widgets/daily_reward_modal.dart';
import '../widgets/custom_app_bar.dart';
import '../core/utils/responsive_utils.dart';
import 'invite_screen.dart';
import 'transaction_history_screen.dart';
import 'profile_screen.dart';
import 'watch_ads_screen.dart';
import 'spin_and_win_screen.dart';
import 'tic_tac_toe_screen.dart';
import 'withdraw_screen.dart';

class ResponsiveHomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const ResponsiveHomeScreen({super.key});

  @override
  State<ResponsiveHomeScreen> createState() => _ResponsiveHomeScreenState();
}

class _ResponsiveHomeScreenState extends State<ResponsiveHomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeTab(),
    InviteScreen(),
    TransactionHistoryScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Iconsax.home),
            selectedIcon: Icon(Iconsax.home_1),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_add_outlined),
            selectedIcon: Icon(Icons.person_add),
            label: 'Invite',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  Widget _buildEarningMethodCard(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isTabletOrDesktop = !ResponsiveUtils.isMobile(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Earning App',
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.monetization_on),
                const SizedBox(width: 4),
                Text(userProvider.currentUser?.coinBalance.toString() ?? '0'),
              ],
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = ResponsiveUtils.getResponsivePadding(context);

          return SingleChildScrollView(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Daily Reward Card with responsive width
                Center(
                  child: SizedBox(
                    width: ResponsiveUtils.getResponsiveWidth(context),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Daily Reward',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Claim your daily bonus!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      const DailyRewardModal(),
                                );
                              },
                              icon: const Icon(Icons.card_giftcard),
                              label: const Text('Claim'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                Text(
                  'Earning Methods',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      24,
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),

                // Earning Methods Section with responsive layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (isTabletOrDesktop) {
                      // Grid layout for tablet and desktop
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: ResponsiveUtils.isDesktop(context)
                            ? 3
                            : 2,
                        crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(
                          context,
                        ),
                        mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(
                          context,
                        ),
                        childAspectRatio: 1.2,
                        children: [
                          _buildEarningMethodCard(
                            context,
                            'Watch Ads',
                            Icons.movie_outlined,
                            'Earn coins by watching video ads',
                            () => Navigator.pushNamed(
                              context,
                              WatchAdsScreen.routeName,
                            ),
                          ),
                          _buildEarningMethodCard(
                            context,
                            'Spin & Win',
                            Icons.casino_outlined,
                            'Try your luck on the wheel',
                            () => Navigator.pushNamed(
                              context,
                              SpinAndWinScreen.routeName,
                            ),
                          ),
                          _buildEarningMethodCard(
                            context,
                            'Tic-Tac-Toe',
                            Icons.gamepad_outlined,
                            'Play and earn coins',
                            () => Navigator.pushNamed(
                              context,
                              TicTacToeScreen.routeName,
                            ),
                          ),
                        ],
                      );
                    } else {
                      // List layout for mobile
                      return Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.movie_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(
                                'Watch Ads',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              subtitle: const Text(
                                'Earn coins by watching video ads',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  WatchAdsScreen.routeName,
                                );
                              },
                            ),
                            Divider(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.casino_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(
                                'Spin & Win',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              subtitle: const Text(
                                'Try your luck on the wheel',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  SpinAndWinScreen.routeName,
                                );
                              },
                            ),
                            Divider(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.gamepad_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(
                                'Tic-Tac-Toe',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              subtitle: const Text('Play and earn coins'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  TicTacToeScreen.routeName,
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),

                // Withdraw Button with responsive width
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: ResponsiveUtils.getResponsiveWidth(
                      context,
                      fraction: 0.8,
                    ),
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, WithdrawScreen.routeName);
                      },
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: const Text('Withdraw Earnings'),
                      style: FilledButton.styleFrom(
                        minimumSize: Size(
                          double.infinity,
                          ResponsiveUtils.isMobile(context) ? 56 : 64,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
              ],
            ),
          );
        },
      ),
    );
  }
}
