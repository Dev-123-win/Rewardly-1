import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Core
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

// Providers
import 'providers/local_user_provider.dart';
import 'providers/local_config_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/ad_provider_new.dart';

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocalConfigProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AdProviderNew()),
        ChangeNotifierProvider(
          create: (context) => LocalUserProvider(
            configProvider: Provider.of<LocalConfigProvider>(
              context,
              listen: false,
            ),
          ),
        ),
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
