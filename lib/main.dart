import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemChrome
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

import 'providers/auth_provider.dart' as my_auth_provider;
import 'providers/user_provider.dart';
import 'providers/config_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/ad_provider.dart';

import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/watch_ads_screen.dart';
import 'screens/spin_and_win_screen.dart';
import 'screens/tic_tac_toe_screen.dart';
import 'screens/withdraw_screen.dart';
import 'screens/invite_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/auth_screen.dart'; // Assuming AuthScreen exists

late SharedPreferences
sharedPreferences; // Declare global SharedPreferences instance

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await MobileAds.instance.initialize(); // Initialize Mobile Ads SDK
  sharedPreferences =
      await SharedPreferences.getInstance(); // Initialize SharedPreferences

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.black, // Black nav bar background
      systemNavigationBarIconBrightness: Brightness.light, // White nav icons
      statusBarColor: Colors.transparent, // Optional: status bar color
      statusBarIconBrightness: Brightness.light, // status bar icons color
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ConfigProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => AdProvider()),
        ChangeNotifierProxyProvider<ConfigProvider, UserProvider>(
          create: (context) => UserProvider(
            configProvider: Provider.of<ConfigProvider>(context, listen: false),
          ),
          update: (context, configProvider, userProvider) =>
              userProvider ?? UserProvider(configProvider: configProvider),
        ),
        ChangeNotifierProxyProvider<
          UserProvider,
          my_auth_provider.AuthProvider
        >(
          create: (context) => my_auth_provider.AuthProvider(
            Provider.of<UserProvider>(context, listen: false),
          ),
          update: (context, userProvider, authProvider) =>
              authProvider ?? my_auth_provider.AuthProvider(userProvider),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Fetch app config on app start
    Provider.of<ConfigProvider>(context, listen: false).fetchAppConfig();

    Provider.of<UserProvider>(context, listen: false).loadUser();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (!mounted) return;
      if (user != null) {
        // User is signed in, update active days and fetch user data
        Provider.of<UserProvider>(context, listen: false).updateActiveDays();
      } else {
        // User is signed out, clear user data
        Provider.of<UserProvider>(context, listen: false).clearUserData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Earning App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        HomeScreen.routeName: (context) => const HomeScreen(),
        WatchAdsScreen.routeName: (context) => const WatchAdsScreen(),
        SpinAndWinScreen.routeName: (context) => const SpinAndWinScreen(),
        TicTacToeScreen.routeName: (context) => const TicTacToeScreen(),
        WithdrawScreen.routeName: (context) => const WithdrawScreen(),
        InviteScreen.routeName: (context) => const InviteScreen(),
        TransactionHistoryScreen.routeName: (context) =>
            const TransactionHistoryScreen(),
        ProfileScreen.routeName: (context) => const ProfileScreen(),
        EditProfileScreen.routeName: (context) => const EditProfileScreen(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
        HelpSupportScreen.routeName: (context) => const HelpSupportScreen(),
        AuthScreen.routeName: (context) => const AuthScreen(),
      },
    );
  }
}
