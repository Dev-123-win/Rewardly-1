import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ad_provider.dart';
import '../providers/user_provider.dart';
import '../providers/config_provider.dart';

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<AdProvider>(context, listen: false).loadRewardedAd();
  }

  @override
  Widget build(BuildContext context) {
    final adProvider = Provider.of<AdProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final int tictactoeRewardAmount = configProvider.getConfig('rewards.tictactoeReward', defaultValue: 4);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tic-Tac-Toe'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for the Tic-Tac-Toe game
            const Text('Tic-Tac-Toe game will be implemented here.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: adProvider.isRewardedAdReady
                  ? () {
                      adProvider.showRewardedAd(() {
                        userProvider.playTicTacToeAndEarnCoins(tictactoeRewardAmount);
                      });
                    }
                  : null,
              child: const Text('Claim Reward'),
            ),
            if (!adProvider.isRewardedAdReady)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Ad is loading...'),
              ),
          ],
        ),
      ),
    );
  }
}
