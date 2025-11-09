import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment_method.dart';
import '../providers/user_provider.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final _formKeyUPI = GlobalKey<FormState>();
  final _formKeyBank = GlobalKey<FormState>();

  final _upiController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountHolderNameController = TextEditingController();

  @override
  void dispose() {
    _upiController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _accountHolderNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedPaymentMethods();
    });
  }

  void _loadSavedPaymentMethods() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final paymentMethods = userProvider.currentUser?.paymentMethods ?? [];

    for (final methodJson in paymentMethods) {
      final method = PaymentMethod.fromJson(methodJson);
      if (method.type == 'upi') {
        _upiController.text = method.details['upiId'] ?? '';
      } else if (method.type == 'bank') {
        _accountNumberController.text = method.details['accountNumber'] ?? '';
        _ifscController.text = method.details['ifscCode'] ?? '';
        _accountHolderNameController.text =
            method.details['accountHolderName'] ?? '';
      }
    }
  }

  Future<void> _saveUPIDetails() async {
    if (_formKeyUPI.currentState?.validate() ?? false) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final upiMethod = PaymentMethod.createUPI(_upiController.text);

      await userProvider.updatePaymentMethod(upiMethod);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('UPI details saved successfully')),
        );
      }
    }
  }

  Future<void> _saveBankDetails() async {
    if (_formKeyBank.currentState?.validate() ?? false) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final bankMethod = PaymentMethod.createBankAccount(
        accountNumber: _accountNumberController.text,
        ifscCode: _ifscController.text,
        accountHolderName: _accountHolderNameController.text,
      );

      await userProvider.updatePaymentMethod(bankMethod);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank details saved successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payment Methods'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'UPI'),
              Tab(text: 'Bank Account'),
            ],
          ),
        ),
        body: TabBarView(children: [_buildUPIForm(), _buildBankForm()]),
      ),
    );
  }

  Widget _buildUPIForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeyUPI,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _upiController,
              decoration: const InputDecoration(
                labelText: 'UPI ID',
                hintText: 'username@bankname',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter UPI ID';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid UPI ID';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveUPIDetails,
              child: const Text('Save UPI Details'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeyBank,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _accountHolderNameController,
              decoration: const InputDecoration(
                labelText: 'Account Holder Name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter account holder name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accountNumberController,
              decoration: const InputDecoration(labelText: 'Account Number'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter account number';
                }
                if (value.length < 9 || value.length > 18) {
                  return 'Please enter a valid account number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ifscController,
              decoration: const InputDecoration(labelText: 'IFSC Code'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter IFSC code';
                }
                if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value)) {
                  return 'Please enter a valid IFSC code';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveBankDetails,
              child: const Text('Save Bank Details'),
            ),
          ],
        ),
      ),
    );
  }
}
