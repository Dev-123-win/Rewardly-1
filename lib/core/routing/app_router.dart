import 'package:flutter/material.dart';
import '../../screens/main_container_screen.dart';
import '../../screens/main_home_screen.dart';
import '../../screens/invite_screen.dart';
import '../../screens/transaction_history_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/watch_ads_screen_new.dart' as watch_ads;
import '../../screens/spin_and_win_screen_new.dart';
import '../../screens/tic_tac_toe_screen.dart';
import '../../screens/withdraw_screen.dart';
import '../../screens/edit_profile_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/help_support_screen.dart';
import '../../screens/whack_a_mole_screen.dart';
import '../../screens/daily_bonus_screen.dart';
import '../../screens/responsive_payment_methods_screen.dart';

class AppRouter {
  static const String paymentMethodsRoute = '/payment-methods';
  static Route<dynamic> generateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) {
        // Return appropriate screen based on route name
        switch (settings.name) {
          case MainHomeScreen.routeName:
            return const MainContainerScreen();
          case InviteScreen.routeName:
            return const InviteScreen();
          case TransactionHistoryScreen.routeName:
            return const TransactionHistoryScreen();
          case ProfileScreen.routeName:
            return const ProfileScreen();
          case watch_ads.WatchAdsScreen.routeName:
            return const watch_ads.WatchAdsScreen();
          case SpinAndWinScreenNew.routeName:
            return const SpinAndWinScreenNew();
          case TicTacToeScreen.routeName:
            return const TicTacToeScreen();
          case WithdrawScreen.routeName:
            return const WithdrawScreen();
          case EditProfileScreen.routeName:
            return const EditProfileScreen();
          case SettingsScreen.routeName:
            return const SettingsScreen();
          case HelpSupportScreen.routeName:
            return const HelpSupportScreen();
          case '/whack-a-mole':
            return const WhackAMoleScreen();
          case DailyBonusScreen.routeName:
            return const DailyBonusScreen();
          case paymentMethodsRoute:
            return const ResponsivePaymentMethodsScreen();
          default:
            return Scaffold(
              body: Center(child: Text('Route ${settings.name} not found')),
            );
        }
      },
    );
  }

  static void navigateToHome(BuildContext context) {
    Navigator.pushReplacementNamed(context, MainHomeScreen.routeName);
  }
}
