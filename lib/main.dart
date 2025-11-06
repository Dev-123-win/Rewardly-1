import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

// Data Layer
import 'data/repositories/database_service.dart';
import 'data/repositories/queue_manager.dart';
import 'data/cache/cache_manager.dart';

// Core Services
import 'core/services/config_service.dart';

// Providers
import 'providers/auth_provider.dart' as my_auth_provider;
import 'providers/user_provider.dart';
import 'providers/config_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/ad_provider.dart';

// Screens

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Mobile Ads SDK
  await MobileAds.instance.initialize();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize Core Services
  final firestore = FirebaseFirestore.instance;

  // Initialize Data Layer
  final cacheManager = CacheManager(sharedPreferences);
  final databaseService = DatabaseService(firestore);
  final queueManager = QueueManager(databaseService, cacheManager);
  final configService = ConfigService(firestore);

  // Initialize Config Service
  await configService.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white, // white background
      statusBarIconBrightness: Brightness.dark, // white icons (invisible)
      statusBarBrightness: Brightness.light, // iOS
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: databaseService),
        Provider.value(value: queueManager),
        Provider.value(value: cacheManager),
        Provider.value(value: configService),

        ChangeNotifierProvider(create: (_) => ConfigProvider(configService)),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AdProvider()),

        ChangeNotifierProvider(
          create: (context) => UserProvider(
            configProvider: Provider.of<ConfigProvider>(context, listen: false),
          ),
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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;

    // Fetch app config on app start
    await Provider.of<ConfigProvider>(context, listen: false).fetchAppConfig();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EarnPlay',
      theme: AppTheme.theme,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/',
    );
  }
}
