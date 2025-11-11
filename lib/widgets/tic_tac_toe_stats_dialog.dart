import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../models/tic_tac_toe_history.dart';

class TicTacToeStatsDialog extends StatelessWidget {
  final int totalGames;
  final int winStreak;
  final int xScore;
  final int oScore;
  final int totalCoinsEarned;
  final List<TicTacToeHistory> gameHistory;

  const TicTacToeStatsDialog({
    super.key,
    required this.totalGames,
    required this.winStreak,
    required this.xScore,
    required this.oScore,
    required this.totalCoinsEarned,
    required this.gameHistory,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('MMM d, h:mm a');

    int totalWins = gameHistory.where((game) => game.gameResult == 'win').length;
    int totalLosses = gameHistory.where((game) => game.gameResult == 'loss').length;
    int totalDraws = gameHistory.where((game) => game.gameResult == 'draw').length;
    int calculatedTotalGames = totalWins + totalLosses + totalDraws;
    double winRate = calculatedTotalGames > 0 ? (totalWins / calculatedTotalGames) * 100 : 0.0;

    return Dialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Iconsax.chart_2, color: colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Game Statistics',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  context,
                  Iconsax.game,
                  'Total Games',
                  calculatedTotalGames.toString(),
                ),
                _buildStatCard(
                  context,
                  Iconsax.flash,
                  'Win Streak',
                  winStreak.toString(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  context,
                  Iconsax.chart_success,
                  'Win Rate',
                  '${winRate.toStringAsFixed(1)}%',
                ),
                _buildStatCard(
                  context,
                  Iconsax.coin,
                  'Total Coins',
                  totalCoinsEarned.toString(),
                  isHighlighted: true,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Icon(Iconsax.timer_1, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Recent Games',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (gameHistory.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.chart_square,
                        size: 48,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No games played yet',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Play your first game to see history',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: gameHistory.length,
                  itemBuilder: (context, index) {
                    final game = gameHistory[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: game.gameResult == 'win'
                            ? colorScheme.primaryContainer
                            : game.gameResult == 'draw'
                                ? colorScheme.surfaceContainerHighest
                                : colorScheme.errorContainer,
                        child: Icon(
                          game.gameResult == 'win'
                              ? Iconsax.medal_star
                              : game.gameResult == 'draw'
                                  ? Iconsax.refresh
                                  : Iconsax.close_circle,
                          color: game.gameResult == 'win'
                              ? colorScheme.primary
                              : game.gameResult == 'draw'
                                  ? colorScheme.outline
                                  : colorScheme.error,
                        ),
                      ),
                      title: Text(
                        game.gameResult == 'win'
                            ? 'Victory!'
                            : game.gameResult == 'draw'
                                ? 'Draw'
                                : 'Defeat',
                        style: textTheme.titleSmall?.copyWith(
                          color: game.gameResult == 'win'
                              ? colorScheme.primary
                              : game.gameResult == 'draw'
                                  ? colorScheme.outline
                                  : colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'vs ${game.opponent} • ${dateFormat.format(game.date)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${game.coinsEarned}',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: isHighlighted
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isHighlighted
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: isHighlighted
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                color: isHighlighted
                    ? colorScheme.primary
                    : colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
