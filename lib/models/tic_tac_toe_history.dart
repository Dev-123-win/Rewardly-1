class TicTacToeHistory {
  final DateTime date;
  final String gameResult; // 'win', 'loss', 'draw'
  final int coinsEarned;
  final String opponent;

  TicTacToeHistory({
    required this.date,
    required this.gameResult,
    required this.coinsEarned,
    required this.opponent,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'gameResult': gameResult,
      'coinsEarned': coinsEarned,
      'opponent': opponent,
    };
  }

  factory TicTacToeHistory.fromMap(Map<String, dynamic> map) {
    return TicTacToeHistory(
      date: DateTime.parse(map['date']),
      gameResult: map['gameResult'],
      coinsEarned: map['coinsEarned'],
      opponent: map['opponent'],
    );
  }
}
