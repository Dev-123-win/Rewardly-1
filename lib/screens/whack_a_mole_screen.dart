import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/whack_a_mole_provider.dart';
import '../widgets/custom_app_bar.dart';

class WhackAMoleScreen extends StatelessWidget {
  const WhackAMoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WhackAMoleProvider(context),
      child: const _WhackAMoleScreenContent(),
    );
  }
}

class _WhackAMoleScreenContent extends StatelessWidget {
  const _WhackAMoleScreenContent();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(
      context,
    ).textTheme.apply(fontFamily: 'WhackAMole');

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Whack A Mole',
        actions: [
          Consumer<WhackAMoleProvider>(
            builder: (context, provider, _) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    'Coins: ${provider.currentGameCoins}',
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/games/whack_a_mole/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Consumer<WhackAMoleProvider>(
                builder: (context, provider, _) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Time: ${provider.countdown.inSeconds}s',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              const Shadow(
                                blurRadius: 4,
                                color: Colors.black54,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Combo: ${provider.consecutiveHits}',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            shadows: [
                              const Shadow(
                                blurRadius: 4,
                                color: Colors.black54,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Expanded(
                child: Consumer<WhackAMoleProvider>(
                  builder: (context, provider, _) {
                    if (!provider.isPlaying) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 230),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 51),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                provider.gameResult == null
                                    ? 'Ready to Play?'
                                    : 'Game Over!',
                                style: textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown,
                                ),
                              ),
                              if (provider.gameResult != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Total Coins: ${provider.currentGameCoins}',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Max Combo: ${provider.maxCombo}',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 32),
                              ElevatedButton(
                                onPressed: provider.startGame,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  backgroundColor: Colors.brown,
                                ),
                                child: Text(
                                  provider.gameResult == null
                                      ? 'Start Game'
                                      : 'Play Again',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return GridView.count(
                      crossAxisCount: 3,
                      padding: const EdgeInsets.all(16),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: provider.moles.map((mole) {
                        return _MoleView(
                          mole: mole,
                          onTap: () => provider.onMoleHit(mole),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoleView extends StatelessWidget {
  const _MoleView({required this.mole, required this.onTap});

  final MoleModel mole;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Background hole
          Image.asset(
            'assets/games/whack_a_mole/bg_hole.png',
            fit: BoxFit.contain,
          ),
          // Mole character
          if (mole.type != MoleType.none)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: mole.isTapped ? 0.5 : 1.0,
              child: Image.asset(
                mole.type == MoleType.normal
                    ? 'assets/games/whack_a_mole/char_normal_mole.png'
                    : 'assets/games/whack_a_mole/char_bomber_mole.png',
                fit: BoxFit.contain,
              ),
            ),
          // Foreground hole
          Image.asset(
            'assets/games/whack_a_mole/fg_hole.png',
            fit: BoxFit.contain,
          ),
          // Hit effect
          if (mole.isTapped)
            Image.asset(_getEffectAsset(), fit: BoxFit.contain),
        ],
      ),
    );
  }

  String _getEffectAsset() {
    switch (mole.type) {
      case MoleType.normal:
        return 'assets/games/whack_a_mole/fx_normal.png';
      case MoleType.bomber:
        return 'assets/games/whack_a_mole/fx_bomber.png';
      case MoleType.none:
        return 'assets/games/whack_a_mole/fx_none.png';
    }
  }
}
