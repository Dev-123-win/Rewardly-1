import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/config_provider.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _selectedMethod = 'UPI';
  bool _isLoading = false;

  Future<void> _requestWithdrawal() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final configProvider = Provider.of<ConfigProvider>(context, listen: false);
        final int amount = int.parse(_amountController.text);
        final int minWithdrawalCoins = configProvider.getConfig('minWithdrawalCoins', defaultValue: 10000);

        // In a real app, you would collect UPI/Bank details from the user
        // For this example, we'll use placeholder details
        final Map<String, dynamic> details = {
          'upiId': 'placeholder@upi',
          'bankAccount': '1234567890',
          'bankIfsc': 'ABCD0123456',
          'accountHolder': 'Placeholder Name',
        };

        await userProvider.requestWithdrawal(amount, _selectedMethod, details, minWithdrawalCoins);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Withdrawal request submitted!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit request: ${e.toString()}')),
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
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final int coinBalance = userProvider.userData?['coinBalance'] ?? 0;
    final int minWithdrawalCoins = configProvider.getConfig('minWithdrawalCoins', defaultValue: 10000);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw Coins'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your coin balance: $coinBalance'),
              Text('Minimum withdrawal: $minWithdrawalCoins coins'),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount to withdraw',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final int? amount = int.tryParse(value);
                  if (amount == null) {
                    return 'Please enter a valid number';
                  }
                  if (amount < minWithdrawalCoins) {
                    return 'Amount must be at least $minWithdrawalCoins';
                  }
                  if (amount > coinBalance) {
                    return 'Insufficient balance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _selectedMethod,
                items: ['UPI', 'Bank Transfer'].map((String method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMethod = newValue!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Withdrawal Method',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _requestWithdrawal,
                  child: const Text('Submit Request'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
