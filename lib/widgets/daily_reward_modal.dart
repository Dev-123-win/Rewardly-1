import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/local_user_provider.dart';
import '../providers/config_provider.dart';

class DailyRewardModal extends StatefulWidget {
  const DailyRewardModal({super.key});

  @override
  State<DailyRewardModal> createState() => _DailyRewardModalState();
}

class _DailyRewardModalState extends State<DailyRewardModal> {
  bool _isLoading = false;

  Future<void> _claimReward() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<LocalUserProvider>(context, listen: false);
      final configProvider = Provider.of<ConfigProvider>(context, listen: false);
      final int dailyRewardAmount = configProvider.getConfig('rewards.dailyReward', defaultValue: 10);

      await userProvider.recordGameReward(
        gameType: 'dailyBonus',
        amount: dailyRewardAmount,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You have claimed $dailyRewardAmount coins!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to claim reward: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final int dailyRewardAmount = configProvider.getConfig('rewards.dailyReward', defaultValue: 10);

    return AlertDialog(
      title: const Text('Daily Reward'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Claim your daily reward of $dailyRewardAmount coins!'),
          const SizedBox(height: 20),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed: _claimReward,
              child: const Text('Claim'),
            ),
        ],
      ),
    );
  }
}
