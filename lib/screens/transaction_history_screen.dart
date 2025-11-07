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

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Transaction History',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<String>(
                      segments: ['All', 'Earning', 'Withdrawal'].map((
                        String value,
                      ) {
                        IconData icon;
                        switch (value) {
                          case 'All':
                            icon = Iconsax.clipboard_text;
                            break;
                          case 'Earning':
                            icon = Iconsax.arrow_circle_up;
                            break;
                          case 'Withdrawal':
                            icon = Iconsax.arrow_circle_down;
                            break;
                          default:
                            icon = Iconsax.document;
                        }
                        return ButtonSegment<String>(
                          value: value,
                          icon: Icon(icon, size: 20),
                          label: Text(
                            value,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      selected: {_selectedFilter},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _selectedFilter = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.resolveWith<Color>((states) {
                              if (states.contains(WidgetState.selected)) {
                                return colorScheme.primaryContainer;
                              }
                              return colorScheme.surfaceContainerHighest.withOpacity(
                                0.3,
                              );
                            }),
                        foregroundColor:
                            WidgetStateProperty.resolveWith<Color>((states) {
                              if (states.contains(WidgetState.selected)) {
                                return colorScheme.onPrimaryContainer;
                              }
                              return colorScheme.onSurfaceVariant;
                            }),
                        side: WidgetStateProperty.resolveWith<BorderSide>((
                          states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return BorderSide(
                              color: colorScheme.primary.withOpacity(0.5),
                            );
                          }
                          return BorderSide(
                            color: colorScheme.outline.withOpacity(0.2),
                          );
                        }),
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final transaction = filteredTransactions[index];
                final bool isEarning = transaction['type'] == 'earning';
                final amount = transaction['amount'];
                final icon = isEarning
                    ? Iconsax.money_recive
                    : Iconsax.money_send;
                final subType = transaction['subType'].replaceAll('_', ' ');

                return Card(
                  elevation: 2,
                  shadowColor: colorScheme.shadow.withOpacity(0.08),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withOpacity(0.2),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.surface,
                          colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isEarning
                                    ? [
                                        colorScheme.primaryContainer,
                                        colorScheme.primary.withOpacity(0.1),
                                      ]
                                    : [
                                        colorScheme.errorContainer,
                                        colorScheme.error.withOpacity(0.1),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.shadow.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              color: isEarning
                                  ? colorScheme.primary
                                  : colorScheme.error,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      subType.toUpperCase(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurface,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isEarning
                                            ? colorScheme.primaryContainer
                                                  .withOpacity(0.4)
                                            : colorScheme.errorContainer
                                                  .withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Iconsax.coin,
                                            size: 16,
                                            color: isEarning
                                                ? colorScheme.primary
                                                : colorScheme.error,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${isEarning ? '+' : ''}$amount',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: isEarning
                                                      ? colorScheme.primary
                                                      : colorScheme.error,
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Iconsax.calendar,
                                      size: 14,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      transaction['timestamp'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            fontFamily: 'Inter',
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
