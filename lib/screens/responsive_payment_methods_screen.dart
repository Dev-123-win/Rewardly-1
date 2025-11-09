import 'package:flutter/material.dart';
import '../screens/payment_methods_screen.dart';
import '../core/utils/responsive_utils.dart';

class ResponsivePaymentMethodsScreen extends StatelessWidget {
  const ResponsivePaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isMobile(context)) {
      return const PaymentMethodsScreen();
    }

    // For tablet and desktop, show a centered container with max width
    return Scaffold(
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: ResponsiveUtils.isDesktop(context) ? 800 : 600,
          ),
          child: const PaymentMethodsScreen(),
        ),
      ),
    );
  }
}
