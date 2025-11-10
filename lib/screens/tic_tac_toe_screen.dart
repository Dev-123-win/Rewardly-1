import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../providers/local_user_provider.dart';
import '../providers/ad_provider_new.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/tic_tac_toe_stats_dialog.dart';
import '../widgets/tic_tac_toe_result_dialog.dart';
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
      Provider.of<AdProviderNew>(context, listen: false).loadRewardedAd();
    });
  }

  Future<void> _loadGameStats() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final userJson = prefs.getString('current_user');
    if (userJson == null) return;

    final userProvider = Provider.of<LocalUserProvider>(context, listen: false);
    final todayString = DateTime.now().toIso8601String().substring(0, 10);
    final todayStats = userProvider.currentUser?.dailyStats[todayString] ?? {};
    final todayGames = todayStats['tictactoePlayed'] ?? 0;
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
    // More beatable AI implementation
    final random = Random();
    int? bestMove;

    // 40% chance to make a random move
    if (random.nextDouble() < 0.4) {
      List<int> availableMoves = [];
      for (int i = 0; i < 9; i++) {
        if (board[i] == '') {
          availableMoves.add(i);
        }
      }
      if (availableMoves.isNotEmpty) {
        bestMove = availableMoves[random.nextInt(availableMoves.length)];
      }
    } else {
      // Smart move with 60% chance
      bestMove = _getSmartMove();
    }

    if (bestMove != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            board[bestMove!] = 'O';
            _isAITurn = false;
          });
          _checkWinner();
          if (!_isGameOver) {
            _togglePlayer();
          }
        }
      });
    }
  }

  int? _getSmartMove() {
    // Check for winning move
    int? move = _getWinningMove('O');
    if (move != null) return move;

    // Block opponent's winning move
    move = _getWinningMove('X');
    if (move != null) return move;

    // Take center if available
    if (board[4] == '') return 4;

    // Take a random corner
    final corners = [0, 2, 6, 8];
    corners.shuffle();
    for (int corner in corners) {
      if (board[corner] == '') return corner;
    }

    // Take any available spot
    for (int i = 0; i < 9; i++) {
      if (board[i] == '') return i;
    }

    return null;
  }

  int? _getWinningMove(String player) {
    final winPatterns = [
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

  Future<void> _handleRewardEarned(int reward, bool isWin) async {
    if (!mounted) return;

    setState(() {
      totalCoinsEarned += reward;
      gameHistory.insert(
        0,
        TicTacToeHistory(
          date: DateTime.now(),
          isWin: isWin,
          coinsEarned: reward,
          opponent: 'AI',
        ),
      );
      if (gameHistory.length > 10) {
        gameHistory.removeLast();
      }
    });

    if (!mounted) return;

    // Show reward message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You earned $reward coins!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _resetGame();
  }

  void _checkWinner() {
    // Check rows
    for (int i = 0; i < 9; i += 3) {
      if (board[i] != '' &&
          board[i] == board[i + 1] &&
          board[i] == board[i + 2]) {
        _showGameResult(board[i]);
        return;
      }
    }

    // Check columns
    for (int i = 0; i < 3; i++) {
      if (board[i] != '' &&
          board[i] == board[i + 3] &&
          board[i] == board[i + 6]) {
        _showGameResult(board[i]);
        return;
      }
    }

    // Check diagonals
    if (board[0] != '' && board[0] == board[4] && board[0] == board[8]) {
      _showGameResult(board[0]);
      return;
    }
    if (board[2] != '' && board[2] == board[4] && board[2] == board[6]) {
      _showGameResult(board[2]);
      return;
    }

    // Check for draw
    if (!board.contains('')) {
      _showGameResult('Draw');
      return;
    }
  }

  void _showGameResult(String result) async {
    setState(() {
      winner = result;
      _isGameOver = true;
    });

    // Update stats before showing dialog
    final provider = Provider.of<LocalUserProvider>(context, listen: false);
    final todayString = DateTime.now().toIso8601String().substring(0, 10);
    final todayStats = provider.currentUser?.dailyStats[todayString] ?? {};

    int currentWins = todayStats['tictactoeWins'] ?? 0;
    int currentLosses = todayStats['tictatoeLosses'] ?? 0;
    int currentStreak = todayStats['tictactoeStreak'] ?? 0;
    int currentGames = todayStats['tictactoeGames'] ?? 0;

    // Update statistics based on result
    if (result == 'X') {
      currentWins++;
      currentStreak++;
      todayStats['tictactoeWins'] = currentWins;
      todayStats['tictactoeStreak'] = currentStreak;
      setState(() {
        xScore = currentWins;
        winStreak = currentStreak;
      });
    } else if (result == 'O') {
      currentLosses++;
      currentStreak = 0;
      todayStats['tictatoeLosses'] = currentLosses;
      todayStats['tictactoeStreak'] = currentStreak;
      setState(() {
        oScore = currentLosses;
        winStreak = 0;
      });
    } else {
      currentStreak = 0;
      todayStats['tictactoeStreak'] = currentStreak;
      setState(() {
        winStreak = 0;
      });
    }

    todayStats['tictactoeGames'] = currentGames + 1;
    setState(() {
      totalGames = currentGames + 1;
    });

    if (!mounted) return;

    // Show result dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TicTacToeResultDialog(
        result: result == 'X' ? 'win' : (result == 'O' ? 'lose' : 'draw'),
        onClaimCoins: () async {
          if (!mounted) return; // Check mounted here
          Navigator.of(context).pop();

          if (result == 'O') {
            // No coins for losing
            _resetGame();
            return;
          }

          final adProvider = Provider.of<AdProviderNew>(context, listen: false);
          final int reward = result == 'X' ? 4 : 2; // 4 for win, 2 for draw

          if (adProvider.rewardedAd != null) {
            adProvider.showRewardedAd(
              onAdEarned: (rewardItem) async {
                await provider.recordGameReward(
                  gameType: 'tictactoe',
                  amount: reward,
                );

                if (!mounted) return;

                // Use a separate function to update state and show messages
                await _handleRewardEarned(reward, result == 'X');

                adProvider.loadRewardedAd(); // Load next ad
              },
            );
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ad not ready. Try again later.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            adProvider.loadRewardedAd();
            _resetGame();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            SizedBox(
              width: double.infinity,
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
