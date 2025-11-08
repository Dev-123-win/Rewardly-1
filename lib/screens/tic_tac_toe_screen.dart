import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/ad_provider.dart';
import '../providers/user_provider.dart';
import '../providers/config_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/tic_tac_toe_stats_dialog.dart';
import '../models/tic_tac_toe_history.dart';

class TicTacToeScreen extends StatefulWidget {
  static const String routeName = '/tic-tac-toe';

  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  List<String> board = List.filled(9, '');
  String currentPlayer = 'X';
  String winner = '';
  int xScore = 0;
  int oScore = 0;
  int totalGames = 0;
  int winStreak = 0;
  int totalCoinsEarned = 0;
  List<TicTacToeHistory> gameHistory = [];
  bool _isGameOver = false;
  bool _isAITurn = false;

  @override
  void initState() {
    super.initState();
    _loadGameStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdProvider>(context, listen: false).loadRewardedAd();
    });
  }

  Future<void> _loadGameStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final todayStats = userProvider.todayStats;
    final todayGames = todayStats['tictactoeGames'] ?? 0;
    final coins = todayStats['tictactoeCoins'] ?? 0;

    // Load game history from shared preferences or local storage
    // TODO: Implement persistent storage for game history

    setState(() {
      totalGames = todayGames;
      xScore = todayStats['tictactoeWins'] ?? 0;
      oScore = todayStats['tictatoeLosses'] ?? 0;
      winStreak = todayStats['tictactoeStreak'] ?? 0;
      totalCoinsEarned = coins;
    });
  }

  void _resetGame() {
    setState(() {
      board = List.filled(9, '');
      currentPlayer = 'X';
      winner = '';
      _isGameOver = false;
      _isAITurn = false;
    });
  }

  void _handleTap(int index) {
    if (_isGameOver || board[index] != '' || _isAITurn) return;

    setState(() {
      board[index] = currentPlayer;
    });

    _checkWinner();
    if (!_isGameOver) {
      _togglePlayer();
      if (currentPlayer == 'O') {
        _isAITurn = true;
        _aiMove();
      }
    }
  }

  void _togglePlayer() {
    currentPlayer = (currentPlayer == 'X') ? 'O' : 'X';
  }

  void _aiMove() {
    // Simple AI: find first empty spot
    int? bestMove;
    // 1. Check for winning move
    bestMove = _getWinningMove('O');
    // 2. Block opponent's winning move
    bestMove ??= _getWinningMove('X');
    // 3. Take center
    bestMove ??= board[4] == '' ? 4 : null;
    // 4. Take a corner
    bestMove ??= _getCornerMove();
    // 5. Take any available spot
    bestMove ??= board.indexOf('');

    if (bestMove != -1) {
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          board[bestMove!] = 'O';
          _isAITurn = false;
        });
        _checkWinner();
        if (!_isGameOver) {
          _togglePlayer();
        }
      });
    }
  }

  int? _getWinningMove(String player) {
    // Check rows, columns, and diagonals for a winning move
    final List<List<int>> winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6], // Diagonals
    ];

    for (var pattern in winPatterns) {
      int count = 0;
      int emptyIndex = -1;
      for (int index in pattern) {
        if (board[index] == player) {
          count++;
        } else if (board[index] == '') {
          emptyIndex = index;
        }
      }
      if (count == 2 && emptyIndex != -1) {
        return emptyIndex;
      }
    }
    return null;
  }

  int? _getCornerMove() {
    final List<int> corners = [0, 2, 6, 8];
    for (int corner in corners) {
      if (board[corner] == '') {
        return corner;
      }
    }
    return null;
  }

  void _checkWinner() {
    // Check rows
    for (int i = 0; i < 9; i += 3) {
      if (board[i] != '' &&
          board[i] == board[i + 1] &&
          board[i] == board[i + 2]) {
        _setWinner(board[i]);
        return;
      }
    }

    // Check columns
    for (int i = 0; i < 3; i++) {
      if (board[i] != '' &&
          board[i] == board[i + 3] &&
          board[i] == board[i + 6]) {
        _setWinner(board[i]);
        return;
      }
    }

    // Check diagonals
    if (board[0] != '' && board[0] == board[4] && board[0] == board[8]) {
      _setWinner(board[0]);
      return;
    }
    if (board[2] != '' && board[2] == board[4] && board[2] == board[6]) {
      _setWinner(board[2]);
      return;
    }

    // Check for draw
    if (!board.contains('')) {
      _setWinner('Draw');
      return;
    }
  }

  void _setWinner(String result) async {
    final provider = Provider.of<UserProvider>(context, listen: false);
    Map<String, dynamic> todayStats = Map<String, dynamic>.from(
      provider.todayStats,
    );

    int currentWins = todayStats['tictactoeWins'] ?? 0;
    int currentLosses = todayStats['tictatoeLosses'] ?? 0;
    int currentStreak = todayStats['tictactoeStreak'] ?? 0;
    int currentGames = todayStats['tictactoeGames'] ?? 0;

    setState(() {
      winner = result;
      _isGameOver = true;
    });

    if (result == 'X') {
      currentWins++;
      currentStreak++;
      todayStats['tictactoeWins'] = currentWins;
      todayStats['tictactoeStreak'] = currentStreak;
      setState(() {
        xScore = currentWins;
        winStreak = currentStreak;
        totalGames = currentGames + 1;
      });

      // Show rewarded ad to claim coins
      final adProvider = Provider.of<AdProvider>(context, listen: false);
      final configProvider = Provider.of<ConfigProvider>(
        context,
        listen: false,
      );
      final int tictactoeReward =
          configProvider.appConfig['rewards']?['tictactoeReward'] ?? 4;

      if (adProvider.rewardedAd != null) {
        adProvider.showRewardedAd(
          onAdEarned: (reward) async {
            await provider.playTicTacToeAndEarnCoins(tictactoeReward);
            if (!mounted) return;
            setState(() {
              totalCoinsEarned += tictactoeReward;
              // Add to game history
              gameHistory.insert(
                0,
                TicTacToeHistory(
                  date: DateTime.now(),
                  isWin: true,
                  coinsEarned: tictactoeReward,
                  opponent: 'AI',
                ),
              );
              // Keep only last 10 games in history
              if (gameHistory.length > 10) {
                gameHistory.removeLast();
              }
            });

            // Show reward message
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You earned $tictactoeReward coins!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            adProvider.loadRewardedAd(); // Load next ad
          },
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad not ready. No coins awarded.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        adProvider.loadRewardedAd();
      }
    } else if (result == 'O') {
      currentLosses++;
      currentStreak = 0;
      todayStats['tictatoeLosses'] = currentLosses;
      todayStats['tictactoeStreak'] = currentStreak;
      setState(() {
        oScore = currentLosses;
        winStreak = 0;
        totalGames = currentGames + 1;
      });

      // Add loss to history
      gameHistory.insert(
        0,
        TicTacToeHistory(
          date: DateTime.now(),
          isWin: false,
          coinsEarned: 0,
          opponent: 'AI',
        ),
      );
      if (gameHistory.length > 10) {
        gameHistory.removeLast();
      }
    } else {
      currentStreak = 0;
      todayStats['tictactoeStreak'] = currentStreak;
      setState(() {
        winStreak = 0;
        totalGames = currentGames + 1;
      });

      // Add draw to history
      gameHistory.insert(
        0,
        TicTacToeHistory(
          date: DateTime.now(),
          isWin: false,
          coinsEarned: 0,
          opponent: 'AI',
        ),
      );
      if (gameHistory.length > 10) {
        gameHistory.removeLast();
      }
    }

    todayStats['tictactoeGames'] = currentGames + 1;
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHighlighted
                ? colorScheme.primaryContainer.withOpacity(0.7)
                : colorScheme.surfaceContainerHighest.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isHighlighted
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isHighlighted ? colorScheme.primary : colorScheme.onSurface,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final int tictactoeReward =
        configProvider.appConfig['rewards']?['tictactoeReward'] ?? 4;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'TicTacToe',
        onBack: () => Navigator.of(context).pop(),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.info_circle),
            tooltip: 'View Stats',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => TicTacToeStatsDialog(
                  totalGames: totalGames,
                  winStreak: winStreak,
                  xScore: xScore,
                  oScore: oScore,
                  totalCoinsEarned: totalCoinsEarned,
                  gameHistory: gameHistory,
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Player X (You)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'You',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'X',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: colorScheme.primary,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Score
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$xScore - $oScore',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Game ${totalGames + 1}',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                    // Player O (AI)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.cpu,
                                size: 16,
                                color: colorScheme.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'AI',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: colorScheme.error,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'O',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: colorScheme.error,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: winner.isNotEmpty
                    ? (winner == 'X'
                          ? colorScheme.primaryContainer
                          : winner == 'Draw'
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.errorContainer)
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: winner.isNotEmpty
                      ? (winner == 'X'
                            ? colorScheme.primary.withOpacity(0.2)
                            : winner == 'Draw'
                            ? colorScheme.outline.withOpacity(0.2)
                            : colorScheme.error.withOpacity(0.2))
                      : colorScheme.outlineVariant.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (winner.isEmpty && currentPlayer == 'X')
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.arrow_right_1,
                        color: colorScheme.primary,
                      ),
                    ),
                  if (winner.isEmpty && currentPlayer == 'O')
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Iconsax.cpu, color: colorScheme.error),
                    ),
                  if (winner.isNotEmpty)
                    Icon(
                      winner == 'X'
                          ? Iconsax.medal_star
                          : winner == 'Draw'
                          ? Iconsax.refresh
                          : Iconsax.emoji_sad,
                      color: winner == 'X'
                          ? colorScheme.primary
                          : winner == 'Draw'
                          ? colorScheme.outline
                          : colorScheme.error,
                      size: 24,
                    ),
                  const SizedBox(width: 12),
                  Text(
                    winner.isNotEmpty
                        ? (winner == 'Draw'
                              ? 'It\'s a Draw!'
                              : winner == 'X'
                              ? 'You Win!'
                              : 'AI Wins!')
                        : (currentPlayer == 'X'
                              ? 'Your Turn!'
                              : 'AI is thinking...'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: winner.isNotEmpty
                          ? (winner == 'X'
                                ? colorScheme.primary
                                : winner == 'Draw'
                                ? colorScheme.outline
                                : colorScheme.error)
                          : colorScheme.onSurface,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _handleTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: board[index].isEmpty
                            ? colorScheme.surface
                            : board[index] == 'X'
                            ? colorScheme.primaryContainer.withOpacity(0.7)
                            : colorScheme.errorContainer.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: board[index].isEmpty
                              ? colorScheme.outlineVariant.withOpacity(0.2)
                              : board[index] == 'X'
                              ? colorScheme.primary.withOpacity(0.2)
                              : colorScheme.error.withOpacity(0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: board[index].isNotEmpty
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (board[index] == 'X')
                                    Icon(
                                      Iconsax.close_circle,
                                      size: 64,
                                      color: colorScheme.primary,
                                    )
                                  else
                                    Icon(
                                      Iconsax.record_circle,
                                      size: 64,
                                      color: colorScheme.error,
                                    ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _resetGame,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Iconsax.refresh_circle),
                    label: Text(
                      'New Game',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      // TODO: Implement hint logic
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Iconsax.lamp_on),
                    label: Text(
                      'Get Hint',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          icon: Iconsax.game,
                          label: 'Total Games',
                          value: totalGames.toString(),
                          context: context,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: colorScheme.outlineVariant.withOpacity(0.2),
                        ),
                        _buildStatItem(
                          icon: Iconsax.chart_success,
                          label: 'Win Rate',
                          value:
                              '${totalGames > 0 ? (xScore / totalGames * 100).toStringAsFixed(0) : 0}%',
                          context: context,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          icon: Iconsax.flash,
                          label: 'Win Streak',
                          value: winStreak.toString(),
                          context: context,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: colorScheme.outlineVariant.withOpacity(0.2),
                        ),
                        _buildStatItem(
                          icon: Iconsax.coin,
                          label: 'Reward',
                          value: '+$tictactoeReward',
                          isHighlighted: true,
                          context: context,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
