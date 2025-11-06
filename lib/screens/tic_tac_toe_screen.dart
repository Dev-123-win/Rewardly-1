import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/ad_provider.dart';
import '../providers/user_provider.dart';
import '../providers/config_provider.dart';
import '../widgets/custom_app_bar.dart';

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
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final todayStats = userProvider.currentUser?.dailyStats[today] ?? {};
    final todayGames = todayStats['tictactoeGames'] ?? 0;

    setState(() {
      totalGames = todayGames;
      xScore = todayStats['tictactoeWins'] ?? 0;
      oScore = todayStats['tictatoeLosses'] ?? 0;
      winStreak = todayStats['tictactoeStreak'] ?? 0;
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
    final today = DateTime.now().toIso8601String().substring(0, 10);
    Map<String, dynamic> todayStats = Map<String, dynamic>.from(
      provider.currentUser?.dailyStats[today] ?? {},
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
    } else {
      currentStreak = 0;
      todayStats['tictactoeStreak'] = currentStreak;
      setState(() {
        winStreak = 0;
        totalGames = currentGames + 1;
      });
    }

    todayStats['tictactoeGames'] = currentGames + 1;

    // Show rewarded ad to claim coins
    final adProvider = Provider.of<AdProvider>(context, listen: false);
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final int tictactoeReward =
        configProvider.appConfig['rewards']?['tictactoeReward'] ?? 4;

    if (adProvider.rewardedAd != null) {
      adProvider.showRewardedAd(
        onAdEarned: (reward) async {
          await provider.playTicTacToeAndEarnCoins(tictactoeReward);
          if (!mounted) return;
          // Optionally show a toast/snackbar for coins earned
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You earned $tictactoeReward coins!')),
          );
          adProvider.loadRewardedAd(); // Load next ad
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
    final configProvider = Provider.of<ConfigProvider>(context);
    final int tictactoeReward =
        configProvider.appConfig['rewards']?['tictactoeReward'] ?? 4;

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'You',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'X',
                          style: TextStyle(
                            color: Colors.blue.shade200,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$xScore - $oScore',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Column(
                      children: [
                        const Text(
                          'AI',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'O',
                          style: TextStyle(
                            color: Colors.red.shade200,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              winner.isNotEmpty
                  ? (winner == 'Draw' ? 'It\'s a Draw!' : '$winner Wins!')
                  : (currentPlayer == 'X'
                        ? 'Your Turn! Tap a cell to play'
                        : 'AI\'s Turn...'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: winner.isNotEmpty
                    ? (winner == 'X' ? Colors.green : Colors.red)
                    : Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
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
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Center(
                        child: Text(
                          board[index],
                          style: TextStyle(
                            fontSize: 60,
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'New Game',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement hint logic
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(
                      Icons.lightbulb_outline,
                      color: Colors.blue.shade700,
                    ),
                    label: Text(
                      'Get Hint',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Games: $totalGames',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Win Rate: ${totalGames > 0 ? (xScore / totalGames * 100).toStringAsFixed(0) : 0}%',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Longest Streak: $winStreak',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '+$tictactoeReward coins',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
