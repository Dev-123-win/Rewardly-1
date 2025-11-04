import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        children: const [
          ExpansionTile(
            title: Text('How do I earn coins?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                    'You can earn coins by claiming your daily reward, watching ads, spinning the wheel, and playing Tic-Tac-Toe.'),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('How do I withdraw my earnings?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                    'You can withdraw your earnings once you have reached the minimum withdrawal amount. Go to the Withdraw screen and follow the instructions.'),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('How does the referral system work?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                    'Share your referral code with your friends. When they sign up using your code, you will both receive bonus coins.'),
              ),
            ],
          ),
          ListTile(
            leading: Icon(Icons.email),
            title: Text('Contact Support'),
            onTap: null,
          ),
        ],
      ),
    );
  }
}
