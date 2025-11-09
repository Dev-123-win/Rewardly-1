import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class TicTacToeResultDialog extends StatelessWidget {
  final String result; // 'win', 'lose', or 'draw'
  final VoidCallback onClaimCoins;

  const TicTacToeResultDialog({
    Key? key,
    required this.result,
    required this.onClaimCoins,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    IconData icon;
    Color iconColor;
    String title;
    String message;
    String buttonText;
    int coins;

    switch (result) {
      case 'win':
        icon = Iconsax.medal_star;
        iconColor = colorScheme.primary;
        title = 'Congratulations!';
        message = 'You won the game!';
        buttonText = 'Claim 4 Coins';
        coins = 4;
        break;
      case 'draw':
        icon = Iconsax.refresh;
        iconColor = colorScheme.tertiary;
        title = 'It\'s a Draw!';
        message = 'Well played!';
        buttonText = 'Claim 2 Coins';
        coins = 2;
        break;
      case 'lose':
        icon = Iconsax.emoji_sad;
        iconColor = colorScheme.error;
        title = 'Better Luck Next Time!';
        message = 'Don\'t give up!';
        buttonText = 'Try Again';
        coins = 0;
        break;
      default:
        icon = Iconsax.close_circle;
        iconColor = colorScheme.error;
        title = 'Game Over';
        message = '';
        buttonText = 'Close';
        coins = 0;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: colorScheme.surface,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: result == 'win'
                  ? colorScheme.primaryContainer
                  : result == 'draw'
                  ? colorScheme.tertiaryContainer
                  : colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: iconColor),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (coins > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.coin, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$coins',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onClaimCoins,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}
