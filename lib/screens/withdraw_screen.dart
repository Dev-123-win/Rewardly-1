import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/local_user_provider.dart';
import '../providers/config_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../core/utils/responsive_utils.dart';
import '../models/payment_method.dart';

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
    final userProvider = Provider.of<LocalUserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    if (user != null) {
      // Try to find saved UPI payment method
      final upiMethod = user.paymentMethods.firstWhere(
        (m) => m['type'] == 'upi',
        orElse: () => {},
      );
      if (upiMethod.isNotEmpty) {
        _upiController.text = upiMethod['details']['upiId'] ?? '';
      }

      // Try to find saved bank account payment method
      final bankMethod = user.paymentMethods.firstWhere(
        (m) => m['type'] == 'bank',
        orElse: () => {},
      );
      if (bankMethod.isNotEmpty) {
        _accountNumberController.text =
            bankMethod['details']['accountNumber'] ?? '';
        _ifscController.text = bankMethod['details']['ifscCode'] ?? '';
        _nameController.text = bankMethod['details']['accountHolderName'] ?? '';
      }
    }
  }

  Future<void> _requestWithdrawal() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userProvider = Provider.of<LocalUserProvider>(context, listen: false);
        final configProvider = Provider.of<ConfigProvider>(
          context,
          listen: false,
        );
        final int amount = int.parse(_amountController.text);
        final int minWithdrawalCoins = configProvider.getConfig(
          'minWithdrawalCoins',
          defaultValue: 10000,
        );

        // Create payment method before withdrawal
        if (_selectedMethod == 'UPI') {
          await userProvider.updatePaymentMethod(
            PaymentMethod.createUPI(_upiController.text),
          );
        } else {
          await userProvider.updatePaymentMethod(
            PaymentMethod.createBankAccount(
              accountNumber: _accountNumberController.text,
              ifscCode: _ifscController.text,
              accountHolderName: _nameController.text,
            ),
          );
        }

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
    final userProvider = Provider.of<LocalUserProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final int coinBalance = userProvider.currentUser?.coins ?? 0;
    final int minWithdrawalCoins = configProvider.getConfig(
      'minWithdrawalCoins',
      defaultValue: 10000,
    );

    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = isDesktop
        ? 800.0
        : isTablet
        ? 600.0
        : screenWidth;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Withdraw Coins',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Card(
                      elevation: 2,
                      shadowColor: Theme.of(
                        context,
                      ).colorScheme.shadow.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primaryContainer
                                  .withValues(alpha: 0.7),
                              Theme.of(context).colorScheme.surface,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: isDesktop ? 32 : 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Balance',
                                      style:
                                          (isDesktop
                                                  ? Theme.of(
                                                      context,
                                                    ).textTheme.titleLarge
                                                  : Theme.of(
                                                      context,
                                                    ).textTheme.titleMedium)
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w600,
                                              ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.monetization_on,
                                          size: isDesktop ? 24 : 20,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '$coinBalance',
                                          style:
                                              (isDesktop
                                                      ? Theme.of(context)
                                                            .textTheme
                                                            .headlineLarge
                                                      : Theme.of(context)
                                                            .textTheme
                                                            .headlineSmall)
                                                  ?.copyWith(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'coins',
                                          style:
                                              (isDesktop
                                                      ? Theme.of(
                                                          context,
                                                        ).textTheme.titleLarge
                                                      : Theme.of(
                                                          context,
                                                        ).textTheme.titleMedium)
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withValues(alpha: 0.8),
                                                    fontFamily: 'Inter',
                                                  ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.secondary
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: isDesktop ? 24 : 20,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Minimum withdrawal: ',
                                      style:
                                          (isDesktop
                                                  ? Theme.of(
                                                      context,
                                                    ).textTheme.titleMedium
                                                  : Theme.of(
                                                      context,
                                                    ).textTheme.bodyLarge)
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSecondaryContainer,
                                                fontFamily: 'Inter',
                                              ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '$minWithdrawalCoins coins',
                                      style:
                                          (isDesktop
                                                  ? Theme.of(
                                                      context,
                                                    ).textTheme.titleMedium
                                                  : Theme.of(
                                                      context,
                                                    ).textTheme.bodyLarge)
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.secondary,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.bold,
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: isDesktop ? 32 : 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.shadow.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style:
                            (isDesktop
                                    ? Theme.of(context).textTheme.titleMedium
                                    : Theme.of(context).textTheme.bodyLarge)
                                ?.copyWith(fontFamily: 'Inter'),
                        decoration: InputDecoration(
                          labelText: 'Amount to withdraw',
                          labelStyle: TextStyle(
                            fontFamily: 'Inter',
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          prefixIcon: Icon(
                            Icons.monetization_on,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 24 : 16,
                            vertical: isDesktop ? 20 : 16,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
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
                    ),
                    SizedBox(height: isDesktop ? 32 : 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.shadow.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedMethod,
                        items: [
                          DropdownMenuItem(
                            value: 'UPI',
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.payment,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: isDesktop ? 24 : 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'UPI',
                                  style:
                                      (isDesktop
                                              ? Theme.of(
                                                  context,
                                                ).textTheme.titleMedium
                                              : Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge)
                                          ?.copyWith(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                          ),
                                ),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Bank Transfer',
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.account_balance,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: isDesktop ? 24 : 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Bank Transfer',
                                  style:
                                      (isDesktop
                                              ? Theme.of(
                                                  context,
                                                ).textTheme.titleMedium
                                              : Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge)
                                          ?.copyWith(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                          ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedMethod = newValue!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Withdrawal Method',
                          labelStyle: TextStyle(
                            fontFamily: 'Inter',
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 24 : 16,
                            vertical: isDesktop ? 20 : 16,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        style:
                            (isDesktop
                                    ? Theme.of(context).textTheme.titleMedium
                                    : Theme.of(context).textTheme.bodyLarge)
                                ?.copyWith(fontFamily: 'Inter'),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_selectedMethod == 'UPI')
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.shadow.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _upiController,
                          style:
                              (isDesktop
                                      ? Theme.of(context).textTheme.titleMedium
                                      : Theme.of(context).textTheme.bodyLarge)
                                  ?.copyWith(fontFamily: 'Inter'),
                          decoration: InputDecoration(
                            labelText: 'UPI ID',
                            labelStyle: TextStyle(
                              fontFamily: 'Inter',
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            prefixIcon: Icon(
                              Icons.payment,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 24 : 16,
                              vertical: isDesktop ? 20 : 16,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                          ),
                          validator: (value) {
                            if (_selectedMethod == 'UPI' &&
                                (value == null || value.isEmpty)) {
                              return 'Please enter your UPI ID';
                            }
                            return null;
                          },
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.shadow.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _accountNumberController,
                              style:
                                  (isDesktop
                                          ? Theme.of(
                                              context,
                                            ).textTheme.titleMedium
                                          : Theme.of(
                                              context,
                                            ).textTheme.bodyLarge)
                                      ?.copyWith(fontFamily: 'Inter'),
                              decoration: InputDecoration(
                                labelText: 'Bank Account Number',
                                labelStyle: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                prefixIcon: Icon(
                                  Icons.account_balance,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline.withOpacity(0.2),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline.withOpacity(0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 24 : 16,
                                  vertical: isDesktop ? 20 : 16,
                                ),
                                filled: true,
                                fillColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                              ),
                              validator: (value) {
                                if (_selectedMethod == 'Bank Transfer' &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please enter your account number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _ifscController,
                              style:
                                  (isDesktop
                                          ? Theme.of(
                                              context,
                                            ).textTheme.titleMedium
                                          : Theme.of(
                                              context,
                                            ).textTheme.bodyLarge)
                                      ?.copyWith(fontFamily: 'Inter'),
                              decoration: InputDecoration(
                                labelText: 'IFSC Code',
                                labelStyle: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                prefixIcon: Icon(
                                  Icons.receipt_long,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline.withOpacity(0.2),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline.withOpacity(0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 24 : 16,
                                  vertical: isDesktop ? 20 : 16,
                                ),
                                filled: true,
                                fillColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                              ),
                              validator: (value) {
                                if (_selectedMethod == 'Bank Transfer' &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please enter the IFSC code';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              style:
                                  (isDesktop
                                          ? Theme.of(
                                              context,
                                            ).textTheme.titleMedium
                                          : Theme.of(
                                              context,
                                            ).textTheme.bodyLarge)
                                      ?.copyWith(fontFamily: 'Inter'),
                              decoration: InputDecoration(
                                labelText: 'Account Holder Name',
                                labelStyle: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline.withOpacity(0.2),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline.withOpacity(0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 24 : 16,
                                  vertical: isDesktop ? 20 : 16,
                                ),
                                filled: true,
                                fillColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
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
                        ),
                      ),
                    const SizedBox(height: 32),
                    Center(
                      child: Container(
                        width: isDesktop ? 300 : double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: _isLoading
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: SizedBox(
                                    width: isDesktop ? 32 : 24,
                                    height: isDesktop ? 32 : 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: isDesktop ? 3 : 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : FilledButton.icon(
                                onPressed: _requestWithdrawal,
                                icon: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: isDesktop ? 24 : 20,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                                label: Text(
                                  'Submit Withdrawal Request',
                                  style:
                                      (isDesktop
                                              ? Theme.of(
                                                  context,
                                                ).textTheme.titleLarge
                                              : Theme.of(
                                                  context,
                                                ).textTheme.titleMedium)
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                          ),
                                ),
                                style:
                                    FilledButton.styleFrom(
                                      minimumSize: Size(
                                        double.infinity,
                                        isDesktop ? 64 : 56,
                                      ),
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ).copyWith(
                                      elevation:
                                          WidgetStateProperty.resolveWith<
                                            double
                                          >((states) {
                                            if (states.contains(
                                              WidgetState.pressed,
                                            )) {
                                              return 0;
                                            }
                                            return 0;
                                          }),
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
      ),
    );
  }
}
