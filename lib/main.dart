import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemChrome
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/auth_provider.dart' as my_auth_provider;
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'providers/user_provider.dart'; // Import UserProvider
import 'providers/config_provider.dart'; // Import ConfigProvider
import 'providers/settings_provider.dart'; // Import SettingsProvider
import 'providers/ad_provider.dart'; // Import AdProvider
import 'screens/splash_screen.dart';

late SharedPreferences sharedPreferences; // Declare global SharedPreferences instance

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await MobileAds.instance.initialize(); // Initialize Mobile Ads SDK
  sharedPreferences = await SharedPreferences.getInstance(); // Initialize SharedPreferences

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
        ChangeNotifierProvider(create: (context) => my_auth_provider.AuthProvider()),
        ChangeNotifierProvider(create: (context) => ConfigProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => AdProvider()),
        ChangeNotifierProxyProvider<ConfigProvider, UserProvider>(
          create: (context) => UserProvider(),
          update: (context, configProvider, userProvider) =>
              UserProvider(configProvider: configProvider),
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

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (!mounted) return;
      if (user != null) {
        // User is signed in, update active days and fetch user data
        Provider.of<UserProvider>(context, listen: false).fetchUserData(user.uid);
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
    );
  }
}
