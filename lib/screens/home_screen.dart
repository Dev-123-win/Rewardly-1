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

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
            selectedIcon: Icon(Iconsax.home_2),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.profile_add),
            selectedIcon: Icon(Iconsax.profile_add),
            label: 'Invite',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.timer),
            selectedIcon: Icon(Iconsax.timer_1),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.profile_circle),
            selectedIcon: Icon(Iconsax.profile_circle),
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
    final padding = ResponsiveUtils.getResponsivePadding(context);
    final isTabletOrDesktop = !ResponsiveUtils.isMobile(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Earning App',
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Iconsax.coin),
                const SizedBox(width: 4),
                Text(userProvider.currentUser?.coinBalance.toString() ?? '0'),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Reward',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Claim your daily bonus!',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const DailyRewardModal(),
                        );
                      },
                      icon: const Icon(Iconsax.gift),
                      label: const Text('Claim'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Earning Methods',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (isTabletOrDesktop) {
                  // Grid layout for tablet and desktop
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: ResponsiveUtils.isDesktop(context) ? 3 : 2,
                    crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(
                      context,
                    ),
                    mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(
                      context,
                    ),
                    children: [
                      _buildEarningMethodCard(
                        context,
                        'Watch Ads',
                        Iconsax.video_play,
                        'Earn coins by watching video ads',
                        () => Navigator.pushNamed(
                          context,
                          WatchAdsScreen.routeName,
                        ),
                      ),
                      _buildEarningMethodCard(
                        context,
                        'Spin & Win',
                        Iconsax.refresh_circle,
                        'Try your luck on the wheel',
                        () => Navigator.pushNamed(
                          context,
                          SpinAndWinScreen.routeName,
                        ),
                      ),
                      _buildEarningMethodCard(
                        context,
                        'Tic-Tac-Toe',
                        Iconsax.game,
                        'Play and earn coins',
                        () => Navigator.pushNamed(
                          context,
                          TicTacToeScreen.routeName,
                        ),
                      ),
                      _buildEarningMethodCard(
                        context,
                        'Whack A Mole',
                        Iconsax.book1,
                        'Whack moles to earn coins',
                        () => Navigator.pushNamed(context, '/whack-a-mole'),
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
                            Iconsax.video_play,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            'Watch Ads',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: const Text(
                            'Earn coins by watching video ads',
                          ),
                          trailing: const Icon(Iconsax.arrow_right_3),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              WatchAdsScreen.routeName,
                            );
                          },
                        ),
                        Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        ListTile(
                          leading: Icon(
                            Iconsax.refresh_circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            'Spin & Win',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: const Text('Try your luck on the wheel'),
                          trailing: const Icon(Iconsax.arrow_right_3),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              SpinAndWinScreen.routeName,
                            );
                          },
                        ),
                        Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        ListTile(
                          leading: Icon(
                            Iconsax.game,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            'Tic-Tac-Toe',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: const Text('Play and earn coins'),
                          trailing: const Icon(Iconsax.arrow_right_3),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              TicTacToeScreen.routeName,
                            );
                          },
                        ),
                        Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        ListTile(
                          leading: Icon(
                            Iconsax.mouse_1,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            'Whack A Mole',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: const Text('Whack moles to earn coins'),
                          trailing: const Icon(Iconsax.arrow_right_3),
                          onTap: () {
                            Navigator.pushNamed(context, '/whack-a-mole');
                          },
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 32),
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
                  icon: const Icon(Iconsax.wallet),
                  label: const Text('Withdraw Earnings'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
