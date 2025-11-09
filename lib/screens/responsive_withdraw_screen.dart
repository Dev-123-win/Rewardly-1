import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider_new.dart';
import '../providers/config_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../core/utils/responsive_utils.dart';

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
    final user = Provider.of<UserProviderNew>(context, listen: false).currentUser;
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
        final userProvider = Provider.of<UserProviderNew>(context, listen: false);
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
          amount: amount,
          method: _selectedMethod,
          details: details,
          minWithdrawalCoins: minWithdrawalCoins,
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
    final userProvider = Provider.of<UserProviderNew>(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = isDesktop
        ? 800.0
        : isTablet
        ? 600.0
        : screenWidth;

    final int coinBalance = userProvider.currentUser?.coins ?? 0;
    final int minWithdrawalCoins = configProvider.getConfig(
      'minWithdrawalCoins',
      defaultValue: 10000,
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Withdraw Coins',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Balance',
                            style: isDesktop
                                ? Theme.of(context).textTheme.headlineSmall
                                : Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: isDesktop ? 16 : 8),
                          Text(
                            '$coinBalance coins',
                            style:
                                (isDesktop
                                        ? Theme.of(
                                            context,
                                          ).textTheme.headlineLarge
                                        : Theme.of(
                                            context,
                                          ).textTheme.headlineSmall)
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          SizedBox(height: isDesktop ? 16 : 8),
                          Text(
                            'Minimum withdrawal: $minWithdrawalCoins coins',
                            style: isDesktop
                                ? Theme.of(context).textTheme.titleMedium
                                : Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isDesktop ? 32 : 20),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Withdrawal Details',
                            style: isDesktop
                                ? Theme.of(context).textTheme.headlineSmall
                                : Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: isDesktop ? 24 : 16),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: isDesktop
                                ? Theme.of(context).textTheme.titleMedium
                                : Theme.of(context).textTheme.bodyLarge,
                            decoration: InputDecoration(
                              labelText: 'Amount to withdraw',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  isDesktop ? 12 : 8,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 24 : 16,
                                vertical: isDesktop ? 20 : 16,
                              ),
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
                          SizedBox(height: isDesktop ? 24 : 16),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedMethod,
                            items: ['UPI', 'Bank Transfer'].map((
                              String method,
                            ) {
                              return DropdownMenuItem<String>(
                                value: method,
                                child: Text(
                                  method,
                                  style: isDesktop
                                      ? Theme.of(context).textTheme.titleMedium
                                      : Theme.of(context).textTheme.bodyLarge,
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedMethod = newValue!;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Withdrawal Method',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  isDesktop ? 12 : 8,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 24 : 16,
                                vertical: isDesktop ? 20 : 16,
                              ),
                            ),
                            style: isDesktop
                                ? Theme.of(context).textTheme.titleMedium
                                : Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (_selectedMethod == 'UPI') ...[
                            SizedBox(height: isDesktop ? 24 : 16),
                            TextFormField(
                              controller: _upiController,
                              style: isDesktop
                                  ? Theme.of(context).textTheme.titleMedium
                                  : Theme.of(context).textTheme.bodyLarge,
                              decoration: InputDecoration(
                                labelText: 'UPI ID',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    isDesktop ? 12 : 8,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 24 : 16,
                                  vertical: isDesktop ? 20 : 16,
                                ),
                              ),
                              validator: (value) {
                                if (_selectedMethod == 'UPI' &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please enter your UPI ID';
                                }
                                return null;
                              },
                            ),
                          ] else ...[
                            SizedBox(height: isDesktop ? 24 : 16),
                            TextFormField(
                              controller: _accountNumberController,
                              style: isDesktop
                                  ? Theme.of(context).textTheme.titleMedium
                                  : Theme.of(context).textTheme.bodyLarge,
                              decoration: InputDecoration(
                                labelText: 'Bank Account Number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    isDesktop ? 12 : 8,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 24 : 16,
                                  vertical: isDesktop ? 20 : 16,
                                ),
                              ),
                              validator: (value) {
                                if (_selectedMethod == 'Bank Transfer' &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please enter your account number';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: isDesktop ? 24 : 16),
                            TextFormField(
                              controller: _ifscController,
                              style: isDesktop
                                  ? Theme.of(context).textTheme.titleMedium
                                  : Theme.of(context).textTheme.bodyLarge,
                              decoration: InputDecoration(
                                labelText: 'IFSC Code',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    isDesktop ? 12 : 8,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 24 : 16,
                                  vertical: isDesktop ? 20 : 16,
                                ),
                              ),
                              validator: (value) {
                                if (_selectedMethod == 'Bank Transfer' &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please enter the IFSC code';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: isDesktop ? 24 : 16),
                            TextFormField(
                              controller: _nameController,
                              style: isDesktop
                                  ? Theme.of(context).textTheme.titleMedium
                                  : Theme.of(context).textTheme.bodyLarge,
                              decoration: InputDecoration(
                                labelText: 'Account Holder Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    isDesktop ? 12 : 8,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 24 : 16,
                                  vertical: isDesktop ? 20 : 16,
                                ),
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
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isDesktop ? 48 : 32),
                  Center(
                    child: SizedBox(
                      width: isDesktop ? 300 : double.infinity,
                      child: _isLoading
                          ? Center(
                              child: SizedBox(
                                width: isDesktop ? 32 : 24,
                                height: isDesktop ? 32 : 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: isDesktop ? 3 : 2,
                                ),
                              ),
                            )
                          : FilledButton.icon(
                              onPressed: _requestWithdrawal,
                              icon: Icon(
                                Icons.account_balance_wallet_outlined,
                                size: isDesktop ? 24 : 20,
                              ),
                              label: Text(
                                'Submit Request',
                                style: TextStyle(fontSize: isDesktop ? 18 : 16),
                              ),
                              style: FilledButton.styleFrom(
                                minimumSize: Size(
                                  double.infinity,
                                  isDesktop ? 64 : 56,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
