import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/custom_app_bar.dart';

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
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SegmentedButton<String>(
              segments: ['All', 'Earning', 'Withdrawal'].map((String value) {
                return ButtonSegment<String>(value: value, label: Text(value));
              }).toList(),
              selected: {_selectedFilter},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedFilter = newSelection.first;
                });
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context).colorScheme.secondaryContainer;
                  }
                  return Theme.of(context).colorScheme.surface;
                }),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: filteredTransactions.length,
        itemBuilder: (context, index) {
          final transaction = filteredTransactions[index];
          final bool isEarning = transaction['type'] == 'earning';
          final amount = transaction['amount'];
          final icon = isEarning ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1;

          return Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isEarning
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isEarning
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
              ),
              title: Text(
                transaction['subType'].replaceAll('_', ' ').toUpperCase(),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(
                transaction['timestamp'],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              trailing: Text(
                '${isEarning ? '+' : ''}$amount coins',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isEarning
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
