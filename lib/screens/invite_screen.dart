import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/user_provider.dart';

class InviteScreen extends StatelessWidget {
  const InviteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final String referralCode = userProvider.referralCode ?? 'Generating...';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite & Earn'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Referral Code:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SelectableText(
              referralCode,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Share.share('Join our app and get 200 bonus coins! Use my referral code: $referralCode');
              },
              icon: const Icon(Icons.share),
              label: const Text('Share Code'),
            ),
            const SizedBox(height: 30),
            const Text(
              'Referred Users:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: userProvider.referredUsers.isEmpty
                  ? const Text('You haven\'t referred anyone yet.')
                  : ListView.builder(
                      itemCount: userProvider.referredUsers.length,
                      itemBuilder: (context, index) {
                        final referredUser = userProvider.referredUsers[index];
                        final int activeDays = referredUser['refereeActiveDays'] ?? 0;
                        final bool rewarded = referredUser['referrerRewarded'] ?? false;

                        return ListTile(
                          title: Text(referredUser['refereeId'] ?? 'Unknown User'),
                          subtitle: Text('Active Days: $activeDays / 3'),
                          trailing: rewarded
                              ? const Text('Rewarded', style: TextStyle(color: Colors.green))
                              : const Text('Pending'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
