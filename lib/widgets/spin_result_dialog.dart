import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class SpinResultDialog extends StatelessWidget {
  final int coins;

  const SpinResultDialog({super.key, required this.coins});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isWin = coins > 0;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isWin
              ? colorScheme.primaryContainer
              : colorScheme.errorContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isWin ? Iconsax.medal_star : Iconsax.emoji_sad,
          size: 32,
          color: isWin ? colorScheme.primary : colorScheme.error,
        ),
      ),
      title: Text(
        isWin ? 'Congratulations!' : 'Try Again!',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isWin ? 'You won' : 'Better luck next time!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (isWin) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.coin, color: colorScheme.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '$coins',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'coins',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            isWin ? 'Collect Reward' : 'Try Again',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    );
  }
}
