import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'home_screen_new.dart' show HomeScreen;
import 'transaction_history_screen.dart';
import 'profile_screen.dart';
import 'invite_screen.dart';
import 'withdraw_screen.dart';

class MainContainerScreen extends StatefulWidget {
  const MainContainerScreen({super.key});

  @override
  State<MainContainerScreen> createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<MainContainerScreen> {
  int _activeIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TransactionHistoryScreen(),
    const ProfileScreen(),
    const InviteScreen(),
    const WithdrawScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_activeIndex],
      bottomNavigationBar: CustomBottomNavBar(
        activeIndex: _activeIndex,
        onTap: (index) {
          setState(() {
            _activeIndex = index;
          });
        },
      ),
    );
  }
}
