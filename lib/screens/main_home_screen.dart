import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'home_screen_new.dart';
import 'invite_screen.dart';
import 'transaction_history_screen.dart';
import 'profile_screen.dart';

class MainHomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        elevation: 0,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: colorScheme.surface,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(
              Iconsax.home,
              color: _selectedIndex == 0
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Iconsax.profile_add,
              color: _selectedIndex == 1
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            label: 'Invite',
          ),
          NavigationDestination(
            icon: Icon(
              Iconsax.timer,
              color: _selectedIndex == 2
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(
              Iconsax.profile_circle,
              color: _selectedIndex == 3
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
