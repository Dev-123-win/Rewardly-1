import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/daily_reward_modal.dart';
import '../widgets/custom_app_bar.dart'; // Import CustomAppBar
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
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                      icon: const Icon(Icons.card_giftcard),
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
            Card(
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
                    subtitle: const Text('Earn coins by watching video ads'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pushNamed(context, WatchAdsScreen.routeName);
                    },
                  ),
                  Divider(color: Theme.of(context).colorScheme.outlineVariant),
                  ListTile(
                    leading: Icon(
                      Icons.casino_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      'Spin & Win',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: const Text('Try your luck on the wheel'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pushNamed(context, SpinAndWinScreen.routeName);
                    },
                  ),
                  Divider(color: Theme.of(context).colorScheme.outlineVariant),
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
                      Navigator.pushNamed(context, TicTacToeScreen.routeName);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, WithdrawScreen.routeName);
              },
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Withdraw Earnings'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
