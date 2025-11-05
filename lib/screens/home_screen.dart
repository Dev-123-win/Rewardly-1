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
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Invite',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
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
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const DailyRewardModal(),
                );
              },
              child: const Text('Claim Daily Reward'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Earning Methods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.movie),
              title: const Text('Watch Ads'),
              onTap: () {
                Navigator.pushNamed(context, WatchAdsScreen.routeName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.casino),
              title: const Text('Spin & Win'),
              onTap: () {
                Navigator.pushNamed(context, SpinAndWinScreen.routeName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.gamepad),
              title: const Text('Tic-Tac-Toe'),
              onTap: () {
                Navigator.pushNamed(context, TicTacToeScreen.routeName);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, WithdrawScreen.routeName);
              },
              child: const Text('Withdraw'),
            ),
          ],
        ),
      ),
    );
  }
}
