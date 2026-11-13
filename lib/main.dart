import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'config/app_config.dart';
import 'config/routes.dart';
import 'firebase_options.dart';
import 'models/radio_player_model.dart';
import 'pages/badges_page.dart';
import 'pages/change_password_page.dart';
import 'pages/favorites_page.dart';
import 'pages/home_page.dart';
import 'pages/leaderboard_page.dart';
import 'pages/login_page.dart';
import 'pages/profile_page.dart';
import 'pages/settings_page.dart';
import 'pages/welcome_page.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme/theme_provider.dart';
import 'utils/page_transitions.dart';
import 'widgets/loading_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  tz.initializeTimeZones();
  await NotificationService.instance.init();
  runApp(const FeniksApp());
}

class FeniksApp extends StatelessWidget {
  const FeniksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RadioPlayerModel()..init()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) => MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: themeProvider.currentTheme,
          initialRoute: Routes.loading,
          onGenerateRoute: (settings) {
            final fromLanding = settings.arguments == HomePage.landingArgument;
            return FadePageRoute<void>(
              page: _pageFor(settings),
              settings: settings,
              duration: fromLanding
                  ? const Duration(milliseconds: 900)
                  : const Duration(milliseconds: 300),
            );
          },
        ),
      ),
    );
  }
}

Widget _pageFor(RouteSettings settings) {
  switch (settings.name) {
    case Routes.loading:
      return const LoadingScreen();
    case Routes.welcome:
      return const WelcomePage();
    case Routes.login:
      return const LoginPage();
    case Routes.leaderboard:
      return const LeaderboardPage();
    case Routes.badges:
      return const BadgesPage();
    case Routes.favorites:
      return const FavoritesPage();
    case Routes.profile:
      return const ProfilePage();
    case Routes.settings:
      return const SettingsPage();
    case Routes.changePassword:
      return const ChangePasswordPage();
    default:
      return HomePage(
        fromLanding: settings.arguments == HomePage.landingArgument,
      );
  }
}
