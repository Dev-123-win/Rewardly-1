import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/user_provider.dart';
import '../widgets/daily_reward_modal.dart';
import '../widgets/custom_app_bar.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/color_utils.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: Card(
        elevation: 8,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface,
                ColorUtils.blend(
                  colorScheme.surface,
                  colorScheme.surfaceContainerHighest,
                  0.5,
                ),
              ],
            ),
          ),
          child: NavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            animationDuration: const Duration(milliseconds: 500),
            destinations: <NavigationDestination>[
              NavigationDestination(
                icon: Icon(
                  Iconsax.home,
                  color: _selectedIndex == 0
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                selectedIcon: Icon(Iconsax.home_2, color: colorScheme.primary),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(
                  Iconsax.profile_add,
                  color: _selectedIndex == 1
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                selectedIcon: Icon(
                  Iconsax.profile_add,
                  color: colorScheme.primary,
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
                selectedIcon: Icon(Iconsax.timer_1, color: colorScheme.primary),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(
                  Iconsax.profile_circle,
                  color: _selectedIndex == 3
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                selectedIcon: Icon(
                  Iconsax.profile_circle,
                  color: colorScheme.primary,
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shadowColor: colorScheme.shadow.withPreciseOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface,
                colorScheme.surfaceContainerHighest.withOpacity(0.5),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withPreciseOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'Inter',
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'EarnPlay',
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 0,
              color: colorScheme.primaryContainer.withPreciseOpacity(0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.coin, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      userProvider.currentUser?.coins.toString() ?? '0',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Reward Card
            Card(
              elevation: 2,
              shadowColor: colorScheme.shadow.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withPreciseOpacity(0.2),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface,
                      ColorUtils.blend(
                        colorScheme.surface,
                        colorScheme.primaryContainer,
                        0.3,
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Reward',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Claim your daily bonus coins and keep the streak going!',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontFamily: 'Inter',
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const DailyRewardModal(),
                        );
                      },
                      icon: const Icon(Iconsax.gift),
                      label: const Text(
                        'Claim',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Earning Methods',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your preferred way to earn coins',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontFamily: 'Inter',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 32),
            // Withdraw Card
            Card(
              elevation: 2,
              shadowColor: colorScheme.shadow.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.2),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColorUtils.blend(
                        colorScheme.surface,
                        colorScheme.secondaryContainer,
                        0.5,
                      ),
                      colorScheme.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to Cash Out?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Convert your coins to real money and withdraw instantly',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFamily: 'Inter',
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            WithdrawScreen.routeName,
                          );
                        },
                        icon: Icon(
                          Iconsax.wallet,
                          color: colorScheme.onPrimary,
                        ),
                        label: Text(
                          'Withdraw Earnings',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
