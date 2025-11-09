import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/user_provider.dart';
import 'watch_ads_screen_new.dart';
import 'spin_and_win_screen_v2.dart';
import 'tic_tac_toe_screen.dart';
import 'withdraw_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                  Row(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              const Icon(Iconsax.coin, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '₹${userProvider.currentUser?.coins.toString() ?? '0'}',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_outlined),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Welcome Text
              Text(
                'Hello, ${userProvider.currentUser?.displayName ?? 'User'}!',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Balance Card
              Card(
                elevation: 0,
                color: colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Balance',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${userProvider.currentUser?.coins ?? 0} coins',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                WithdrawScreen.routeName,
                              );
                            },
                            child: const Text('Withdraw'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Daily Bonus Card
              Card(
                elevation: 0,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Iconsax.calendar, color: colorScheme.primary),
                  ),
                  title: Text(
                    'Daily Bonus Claim',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text('Come back tomorrow!'),
                  trailing: OutlinedButton(
                    onPressed: null,
                    child: const Text('Claimed'),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Games Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildGameCard(
                      context,
                      'Watch ads',
                      Iconsax.video_play,
                      'Earn coins by watching video ads',
                      () => Navigator.pushNamed(
                        context,
                        WatchAdsScreen.routeName,
                      ),
                    ),
                    _buildGameCard(
                      context,
                      'Spin and Win',
                      Iconsax.refresh_circle,
                      'Try your luck on the wheel',
                      () => Navigator.pushNamed(
                        context,
                        SpinAndWinScreen.routeName,
                      ),
                    ),
                    _buildGameCard(
                      context,
                      'Whack a Mole',
                      Iconsax.gameboy,
                      'Whack the mole to earn coins',
                      () => Navigator.pushNamed(context, '/whack-a-mole'),
                    ),
                    _buildGameCard(
                      context,
                      'Tic Tac Toe',
                      Iconsax.grid_2,
                      'Play and earn coins',
                      () => Navigator.pushNamed(
                        context,
                        TicTacToeScreen.routeName,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
