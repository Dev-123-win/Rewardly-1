import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:iconsax/iconsax.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int activeIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavigationBar(
      icons: const [
        Iconsax.home,
        Iconsax.receipt_1,
        Iconsax.profile_circle,
        Iconsax.share,
        Iconsax.wallet_money,
      ],
      activeIndex: activeIndex,
      gapLocation: GapLocation.none,
      notchSmoothness: NotchSmoothness.defaultEdge,
      leftCornerRadius: 32,
      rightCornerRadius: 32,
      onTap: onTap,
      iconSize: 24,
      elevation: 8,
      activeColor: Theme.of(context).primaryColor,
      inactiveColor: Colors.grey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
}
