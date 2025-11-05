import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart'; // Import CustomAppBar

class TransactionHistoryScreen extends StatefulWidget {
  static const String routeName = '/transaction-history';

  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    // In a real app, you would fetch transactions from Firestore.
    // For this example, we'll use a placeholder list.
    final List<Map<String, dynamic>> transactions = [
      {
        'type': 'earning',
        'subType': 'daily_reward',
        'amount': 10,
        'timestamp': '2025-01-15',
      },
      {
        'type': 'earning',
        'subType': 'ad',
        'amount': 4,
        'timestamp': '2025-01-15',
      },
      {
        'type': 'withdrawal',
        'subType': 'upi',
        'amount': -100,
        'timestamp': '2025-01-14',
      },
    ];

    final filteredTransactions = _selectedFilter == 'All'
        ? transactions
        : transactions
              .where((t) => t['type'] == _selectedFilter.toLowerCase())
              .toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Transaction History',
        onBack: () => Navigator.of(context).pop(),
        actions: [
          DropdownButton<String>(
            value: _selectedFilter,
            items: ['All', 'Earning', 'Withdrawal'].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedFilter = newValue!;
              });
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: filteredTransactions.length,
        itemBuilder: (context, index) {
          final transaction = filteredTransactions[index];
          final bool isEarning = transaction['type'] == 'earning';
          final amount = transaction['amount'];
          final color = isEarning ? Colors.green : Colors.red;
          final icon = isEarning ? Icons.arrow_upward : Icons.arrow_downward;

          return ListTile(
            leading: Icon(icon, color: color),
            title: Text(
              transaction['subType'].replaceAll('_', ' ').toUpperCase(),
            ),
            subtitle: Text(transaction['timestamp']),
            trailing: Text(
              '${isEarning ? '+' : ''}$amount coins',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}
