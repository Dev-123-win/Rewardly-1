import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/navigation/navigation_service.dart';
import '../../core/services/game_service.dart';
import '../../providers/ad_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_app_bar.dart';

// Reward constants
const int normalMoleCoins = 5; // 5 coins per normal mole
const int bomberPenalty = -3; // -3 coins for bomber mole
const int comboBonus = 2; // Extra coins for consecutive hits

enum MoleType { normal, bomber, none }

class MoleModel {
  MoleModel({this.index = 0, this.type = MoleType.none, this.isTapped = false});

  MoleType type;
  int index;
  bool isTapped;
}

class WhackAMoleGame extends StatelessWidget {
  const WhackAMoleGame({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WhackAMoleController(
        initialDuration: const Duration(minutes: 1),
        totalMoles: 9,
      ),
      child: const WhackAMolePage(),
    );
  }
}

class WhackAMolePage extends StatelessWidget {
  const WhackAMolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Whack A Mole',
        actions: [
          Consumer<WhackAMoleController>(
            builder: (context, controller, _) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    'Coins: ${controller.currentGameCoins}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: const SafeArea(child: WhackAMoleLevelView()),
    );
  }
}

class WhackAMoleController extends ChangeNotifier {
  WhackAMoleController({
    Duration initialDuration = const Duration(minutes: 1),
    int totalMoles = 9,
  }) : _duration = initialDuration,
       _length = totalMoles {
    _initGame();
  }

  final Duration _duration;
  final int _length;
  int currentGameCoins = 0;
  int consecutiveHits = 0;

  late Duration countdown = _duration;
  late List<MoleModel> moles = List.generate(
    _length,
    (i) => MoleModel(index: i),
  );

  DateTime? _startedAt;
  DateTime? _stoppedAt;

  bool get isGameOver => countdown.inSeconds <= 0;

  Duration? get result {
    if (_startedAt == null || _stoppedAt == null) return null;
    return _stoppedAt!.difference(_startedAt!);
  }

  void _initGame() {
    currentGameCoins = 0;
    consecutiveHits = 0;
    countdown = _duration;
    _startedAt = DateTime.now();
    _stoppedAt = null;
  }

  Future<void> start({bool isFirstTime = true}) async {
    if (isFirstTime) {
      _initGame();
    }

    if (!isGameOver) {
      await Future.delayed(const Duration(seconds: 1));
      countdown = countdown - const Duration(seconds: 1);

      // Update moles
      for (var mole in moles) {
        moles[mole.index] = mole
          ..isTapped = false
          ..type = MoleType.values
              .where((e) => e != mole.type)
              .toList()[Random().nextInt(2)];
      }

      notifyListeners();
      await start(isFirstTime: false);
    } else {
      _stoppedAt = DateTime.now();
      _handleGameOver();
    }
  }

  Future<void> _handleGameOver() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Get providers and data before async operations
    final gameData = {
      'consecutiveHits': consecutiveHits,
      'duration': result?.inSeconds ?? 0,
    };
    final coinsToAward = currentGameCoins;

    // Access providers and cache necessary values before async gap
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final adProvider = Provider.of<AdProvider>(context, listen: false);
    final isRewardedAdReady = adProvider.isRewardedAdReady;

    // Handle coin awards if any
    if (coinsToAward > 0) {
      await GameService.handleGameEarnings(
        userProvider: userProvider,
        amount: coinsToAward,
        gameType: 'whack_a_mole',
        metadata: gameData,
      );
    }

    // Cache the context check in a local variable
    if (!context.mounted) return;

    // Check if we should show ad
    if (!context.mounted) return;

    // Show ad if ready
    if (isRewardedAdReady) {
      adProvider.showRewardedAd(
        onAdEarned: (reward) async {
          final bonusAmount = 10;
          currentGameCoins += bonusAmount;
          await GameService.handleAdReward(
            userProvider: userProvider,
            amount: bonusAmount,
            source: 'whack_a_mole',
          );
        },
      );
    }
  }

  Future<void> onTap(MoleModel value) async {
    if (!isGameOver && !value.isTapped) {
      if (value.type == MoleType.bomber) {
        countdown -= const Duration(seconds: 5);
        currentGameCoins += bomberPenalty;
        consecutiveHits = 0;
      } else if (value.type == MoleType.normal) {
        countdown += const Duration(seconds: 1);
        consecutiveHits++;

        // Calculate coins with combo bonus
        int coinsEarned = normalMoleCoins;
        if (consecutiveHits > 2) {
          coinsEarned += comboBonus;
        }
        currentGameCoins += coinsEarned;
      }

      moles[value.index] = value..isTapped = true;
      notifyListeners();
    }
  }

  void restart() {
    _initGame();
    start();
  }
}

class WhackAMoleLevelView extends StatefulWidget {
  const WhackAMoleLevelView({super.key});

  @override
  State<WhackAMoleLevelView> createState() => _WhackAMoleLevelViewState();
}

class _WhackAMoleLevelViewState extends State<WhackAMoleLevelView> {
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (_mounted) {
        context.read<WhackAMoleController>().start();
      }
    });
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WhackAMoleController>(
      builder: (context, controller, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Time: ${controller.countdown.inSeconds}s',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: controller.moles
                    .map(
                      (e) =>
                          _MoleView(mole: e, onTap: () => controller.onTap(e)),
                    )
                    .toList(),
              ),
            ),
            if (controller.isGameOver) _GameOverPanel(controller: controller),
          ],
        );
      },
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
      child: Container(
        decoration: BoxDecoration(
          color: _getColor(),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: mole.isTapped
              ? const Icon(Icons.done, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  Color _getColor() {
    if (mole.isTapped) return Colors.grey;
    switch (mole.type) {
      case MoleType.normal:
        return Colors.brown;
      case MoleType.bomber:
        return Colors.red;
      case MoleType.none:
        return Colors.green.shade100;
    }
  }
}

class _GameOverPanel extends StatelessWidget {
  const _GameOverPanel({required this.controller});

  final WhackAMoleController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Game Over!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Coins Earned: ${controller.currentGameCoins}',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.restart,
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }
}
