import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/config_provider.dart';
import '../widgets/custom_app_bar.dart'; // Import CustomAppBar

class WithdrawScreen extends StatefulWidget {
  static const String routeName = '/withdraw';

  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _upiController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedMethod = 'UPI';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user?.withdrawalInfo != null) {
      final info = user!.withdrawalInfo!;
      _upiController.text = info['upiId'] ?? '';
      _accountNumberController.text = info['bankAccount'] ?? '';
      _ifscController.text = info['bankIfsc'] ?? '';
      _nameController.text = info['accountHolder'] ?? '';
    }
  }

  Future<void> _requestWithdrawal() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final configProvider = Provider.of<ConfigProvider>(
          context,
          listen: false,
        );
        final int amount = int.parse(_amountController.text);
        final int minWithdrawalCoins = configProvider.getConfig(
          'minWithdrawalCoins',
          defaultValue: 10000,
        );

        final Map<String, dynamic> details = _selectedMethod == 'UPI'
            ? {'upiId': _upiController.text}
            : {
                'bankAccount': _accountNumberController.text,
                'bankIfsc': _ifscController.text,
                'accountHolder': _nameController.text,
              };

        await userProvider.saveWithdrawalInfo(details);

        await userProvider.requestWithdrawal(
          amount,
          _selectedMethod,
          details,
          minWithdrawalCoins,
        );

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Withdrawal request submitted!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit request: ${e.toString()}'),
            ),
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
    final int coinBalance = userProvider.currentUser?.coinBalance ?? 0;
    final int minWithdrawalCoins = configProvider.getConfig(
      'minWithdrawalCoins',
      defaultValue: 10000,
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Withdraw Coins',
        onBack: () => Navigator.of(context).pop(),
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
              if (_selectedMethod == 'UPI')
                TextFormField(
                  controller: _upiController,
                  decoration: const InputDecoration(
                    labelText: 'UPI ID',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_selectedMethod == 'UPI' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter your UPI ID';
                    }
                    return null;
                  },
                )
              else ...[
                TextFormField(
                  controller: _accountNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Account Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_selectedMethod == 'Bank Transfer' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter your account number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _ifscController,
                  decoration: const InputDecoration(
                    labelText: 'IFSC Code',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_selectedMethod == 'Bank Transfer' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter the IFSC code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Holder Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_selectedMethod == 'Bank Transfer' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter the account holder name';
                    }
                    return null;
                  },
                ),
              ],
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
