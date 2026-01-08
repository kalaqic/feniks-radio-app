import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'theme/theme_provider.dart';
import 'models/radio_player_model.dart';
import 'services/notification_service.dart';
import 'pages/home_page.dart';
import 'pages/leaderboard_page.dart';
import 'pages/feniks_feed_page.dart';
import 'pages/settings_page.dart';
import 'pages/favorites_page.dart';
import 'pages/badges_page.dart';
import 'pages/ether_messages_page.dart';
import 'widgets/loading_screen.dart';
import 'utils/page_transitions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) => MaterialApp(
          title: 'Feniks Radio',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: themeProvider.currentTheme,
          initialRoute: '/',
          onGenerateRoute: (RouteSettings settings) {
            switch (settings.name) {
              case '/':
                return createRoute(
                  page: const LoadingScreen(),
                  settings: settings,
                  transitionType: PageTransitionType.fade,
                );
              case '/home':
                return createRoute(
                  page: const HomePage(),
                  settings: settings,
                  transitionType: PageTransitionType.fade,
                );
              case '/leaderboard':
                return createRoute(
                  page: const LeaderboardPage(),
                  settings: settings,
                  transitionType: PageTransitionType.fade,
                );
              case '/feed':
                return createRoute(
                  page: const FeniksFeedPage(),
                  settings: settings,
                  transitionType: PageTransitionType.fade,
                );
              case '/settings':
                return createRoute(
                  page: const SettingsPage(),
                  settings: settings,
                  transitionType: PageTransitionType.fade,
                );
              case '/favorites':
                return createRoute(
                  page: const FavoritesPage(),
                  settings: settings,
                  transitionType: PageTransitionType.fade,
                );
              case '/badges':
                return createRoute(
                  page: const BadgesPage(),
                  settings: settings,
                  transitionType: PageTransitionType.fade,
                );
              case '/ether-messages':
                return createRoute(
                  page: const EtherMessagesPage(),
                  settings: settings,
                  transitionType: PageTransitionType.fade,
                );
              default:
                return createRoute(
                  page: const HomePage(),
                  settings: settings,
                  transitionType: PageTransitionType.fade,
                );
            }
          },
        ),
      ),
    );
  }
}