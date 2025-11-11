import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

// Core
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

// Providers
import 'providers/local_user_provider.dart';
import 'providers/local_config_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/ad_provider_new.dart';
import 'providers/config_provider.dart'; // Import ConfigProvider
import 'core/services/config_service.dart'; // Import ConfigService

// Screens
import 'screens/main_container_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Mobile Ads SDK
  await MobileAds.instance.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  final localConfigProvider = LocalConfigProvider();
  final localUserProvider = LocalUserProvider(configProvider: localConfigProvider);

  // Initialize SharedPreferences once
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Initialize LocalUserProvider with SharedPreferences
  await localUserProvider.initialize(prefs);

  // Ensure a user is signed in or loaded
  if (localUserProvider.currentUser == null) {
    await localUserProvider.signInUser('Guest User'); // Create a default user if none exists
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => localConfigProvider),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AdProviderNew()),
        ChangeNotifierProvider(create: (_) => ConfigProvider(ConfigService())), // Add ConfigProvider with ConfigService
        ChangeNotifierProvider(create: (_) => localUserProvider), // Provide the pre-initialized LocalUserProvider
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EarnPlay',
      theme: AppTheme.theme,
      onGenerateRoute: AppRouter.generateRoute,
      home: const MainContainerScreen(),
    );
  }
}
