import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';
import 'dart:math';
import '../providers/user_provider_new.dart';
import '../providers/ad_provider_new.dart';
import '../providers/config_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../core/utils/responsive_utils.dart';

class ResponsiveTicTacToeScreen extends StatefulWidget {
  static const String routeName = '/tic-tac-toe';

  const ResponsiveTicTacToeScreen({super.key});

  @override
  State<ResponsiveTicTacToeScreen> createState() =>
      _ResponsiveTicTacToeScreenState();
}

class _ResponsiveTicTacToeScreenState extends State<ResponsiveTicTacToeScreen> {
  List<String> board = List.filled(9, '');
  String currentPlayer = 'X';
  String winner = '';
  int xScore = 0;
  int oScore = 0;
  int totalGames = 0;
  int winStreak = 0;
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

  void _loadGameStats() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    setState(() {
      totalGames =
          userProvider.currentUser?.dailyStats[today]?['tictactoePlayed'] ?? 0;
      winStreak = userProvider.currentUser?.dailyStats[today]?['winStreak'] ?? 0;
    });
  }

  void _handleTap(int index) {
    if (board[index].isNotEmpty || _isGameOver || _isAITurn) {
      return;
    }

    setState(() {
      board[index] = currentPlayer;
      if (_checkWinner(board, currentPlayer)) {
        winner = currentPlayer;
        _isGameOver = true;
        if (winner == 'X') {
          xScore++;
          _showWinDialog();
        } else {
          oScore++;
        }
        return;
      }

      if (_isBoardFull()) {
        winner = 'Draw';
        _isGameOver = true;
        return;
      }

      currentPlayer = currentPlayer == 'X' ? 'O' : 'X';

      if (currentPlayer == 'O' && !_isGameOver) {
        _isAITurn = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          _makeAIMove();
        });
      }
    });
  }

  void _makeAIMove() {
    if (_isGameOver) return;

    // First, check if AI can win
    for (int i = 0; i < 9; i++) {
      if (board[i].isEmpty) {
        board[i] = 'O';
        if (_checkWinner(board, 'O')) {
          setState(() {
            winner = 'O';
            _isGameOver = true;
            oScore++;
            _isAITurn = false;
          });
          return;
        }
        board[i] = ''; // Undo move
      }
    }

    // Then, check if player can win and block
    for (int i = 0; i < 9; i++) {
      if (board[i].isEmpty) {
        board[i] = 'X';
        if (_checkWinner(board, 'X')) {
          board[i] = 'O'; // Block the winning move
          setState(() {
            currentPlayer = 'X';
            _isAITurn = false;
          });
          return;
        }
        board[i] = ''; // Undo move
      }
    }

    // If no winning moves, choose a random empty spot
    List<int> emptySpots = [];
    for (int i = 0; i < 9; i++) {
      if (board[i].isEmpty) {
        emptySpots.add(i);
      }
    }

    if (emptySpots.isNotEmpty) {
      final random = Random();
      int randomIndex = emptySpots[random.nextInt(emptySpots.length)];
      setState(() {
        board[randomIndex] = 'O';
        if (_checkWinner(board, 'O')) {
          winner = 'O';
          _isGameOver = true;
          oScore++;
        } else if (_isBoardFull()) {
          winner = 'Draw';
          _isGameOver = true;
        } else {
          currentPlayer = 'X';
        }
        _isAITurn = false;
      });
    }
  }

  bool _checkWinner(List<String> board, String player) {
    // Check rows
    for (int i = 0; i < 9; i += 3) {
      if (board[i] == player &&
          board[i + 1] == player &&
          board[i + 2] == player) {
        return true;
      }
    }

    // Check columns
    for (int i = 0; i < 3; i++) {
      if (board[i] == player &&
          board[i + 3] == player &&
          board[i + 6] == player) {
        return true;
      }
    }

    // Check diagonals
    if (board[0] == player && board[4] == player && board[8] == player) {
      return true;
    }
    if (board[2] == player && board[4] == player && board[6] == player) {
      return true;
    }

    return false;
  }

  bool _isBoardFull() {
    return !board.contains('');
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

  void _showWinDialog() async {
    final adProvider = Provider.of<AdProviderNew>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final tictactoeReward =
        configProvider.appConfig['rewards']?['tictactoeReward'] ?? 4;

    if (adProvider.rewardedAd != null) {
      adProvider.showRewardedAd(
        onAdEarned: (reward) async {
          try {
            await userProvider.recordGameReward(
              gameType: 'tictactoe',
              amount: tictactoeReward,
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Congratulations! You earned $tictactoeReward coins!',
                ),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
          }
        },
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad not ready. No coins awarded.')),
      );
      adProvider.loadRewardedAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTabletOrDesktop = !ResponsiveUtils.isMobile(context);
    final responsivePadding = ResponsiveUtils.getResponsivePadding(context);
    final boardSize = ResponsiveUtils.getResponsiveWidth(
      context,
      fraction: isTabletOrDesktop ? 0.4 : 0.9,
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: 'TicTacToe',
        onBack: () => Navigator.of(context).pop(),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.info_circle),
            onPressed: () {
              // TODO: Show game rules/info
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (isTabletOrDesktop) {
            // Tablet and Desktop layout
            return Row(
              children: [
                Expanded(child: _buildGameBoard(boardSize)),
              ],
            );
          } else {
            // Mobile layout
            return SingleChildScrollView(
              padding: responsivePadding,
              child: Column(
                children: [
                  _buildGameBoard(boardSize),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildGameBoard(double size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            winner.isNotEmpty
                ? (winner == 'Draw' ? 'It\'s a Draw!' : '$winner Wins!')
                : (currentPlayer == 'X'
                      ? 'Your Turn! Tap a cell to play'
                      : 'AI\'s Turn...'),
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
              fontWeight: FontWeight.bold,
              color: winner.isNotEmpty
                  ? (winner == 'X' ? Colors.green : Colors.red)
                  : Colors.blue.shade700,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
          SizedBox(
            width: size,
            height: size,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _handleTap(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        board[index],
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            40,
                          ),
                          fontWeight: FontWeight.bold,
                          color: board[index] == 'X'
                              ? Colors.blue.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isGameOver)
            Padding(
              padding: EdgeInsets.only(top: ResponsiveUtils.getResponsiveSpacing(context)),
              child: FilledButton.icon(
                onPressed: _resetGame,
                icon: const Icon(Iconsax.refresh),
                label: Text(
                  'Play Again',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      16,
                    ),
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveUtils.getResponsiveSpacing(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  }

