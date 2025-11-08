class TicTacToeHistory {
  final DateTime date;
  final bool isWin;
  final int coinsEarned;
  final String opponent;

  TicTacToeHistory({
    required this.date,
    required this.isWin,
    required this.coinsEarned,
    required this.opponent,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'isWin': isWin,
      'coinsEarned': coinsEarned,
      'opponent': opponent,
    };
  }

  factory TicTacToeHistory.fromMap(Map<String, dynamic> map) {
    return TicTacToeHistory(
      date: DateTime.parse(map['date']),
      isWin: map['isWin'],
      coinsEarned: map['coinsEarned'],
      opponent: map['opponent'],
    );
  }
}
