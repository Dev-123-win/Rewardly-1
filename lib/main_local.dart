import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Core
import 'core/theme/app_theme.dart';
import 'core/routing/app_router_local.dart';

// Providers
import 'providers/local_user_provider.dart';
import 'providers/local_config_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/ad_provider_new.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
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
            configProvider: Provider.of<LocalConfigProvider>(context, listen: false),
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
      initialRoute: '/', // Start with local auth screen
    );
  }
}
