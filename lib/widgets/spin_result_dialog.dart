import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class SpinResultDialog extends StatelessWidget {
  final int coins;

  const SpinResultDialog({super.key, required this.coins});

  @override
  Widget build(BuildContext context) {
    final bool isWin = coins > 0;
    final bool isJackpot = coins == 30;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isJackpot
                ? [const Color(0xFF6200EA), const Color(0xFF3700B3)]
                : (isWin
                      ? [const Color(0xFF1565C0), const Color(0xFF0D47A1)]
                      : [const Color(0xFF424242), const Color(0xFF212121)]),
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color:
                  (isJackpot
                          ? Colors.purple
                          : (isWin ? Colors.blue : Colors.grey))
                      .withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isJackpot) ...[
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 48),
              const Text(
                'JACKPOT!',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ] else ...[
              Icon(
                isWin ? Icons.celebration : Icons.mood_bad,
                color: isWin ? Colors.amber : Colors.white54,
                size: 48,
              ),
              Text(
                isWin ? 'Congratulations!' : 'Try Again!',
                style: TextStyle(
                  color: isWin ? Colors.white : Colors.white70,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (isWin) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isJackpot ? Colors.amber : Colors.white24,
                    width: isJackpot ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.coin,
                      color: isJackpot ? Colors.amber : Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$coins',
                      style: TextStyle(
                        color: isJackpot ? Colors.amber : Colors.white,
                        fontSize: isJackpot ? 36 : 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'COINS',
                      style: TextStyle(
                        color: (isJackpot ? Colors.amber : Colors.white)
                            .withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isJackpot
                    ? 'Amazing win!'
                    : (coins >= 10 ? 'Great spin!' : 'Nice one!'),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ] else ...[
              Text(
                'Better luck next time!',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isJackpot
                      ? [Colors.amber.shade400, Colors.orange.shade600]
                      : [Colors.blue.shade400, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isJackpot ? Colors.amber : Colors.blue).withOpacity(
                      0.3,
                    ),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    child: Text(
                      isWin ? 'Collect Reward' : 'Spin Again',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
