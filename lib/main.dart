import 'package:flutter/material.dart';
import 'package:frontend_daktmt/apis/api_refreshtoken.dart';
import 'package:frontend_daktmt/pages/history/history.dart';
import 'package:frontend_daktmt/pages/home/home.dart';
import 'package:frontend_daktmt/pages/login/forget_pass.dart';
import 'package:frontend_daktmt/pages/login/register.dart';
import 'package:frontend_daktmt/pages/login/sign_in.dart';
import 'package:frontend_daktmt/pages/profile/profile.dart';
import 'package:frontend_daktmt/pages/relay/relay.dart';
import 'package:frontend_daktmt/pages/schedule/schedule.dart';
import 'package:frontend_daktmt/pages/setting/setting.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load();
  startRefreshTokenTimer((dynamic homeScreenKey) {
    homeScreenKey.currentState?.fetchSensorData();
  });
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => const SignIn(),
        '/signin': (context) => const SignIn(),
        '/home': (context) => const HomeScreen(),
        '/register': (context) => const Register(),
        '/forget-password': (context) => const Forget(),
        '/history': (context) => const HistoryScreen(),
        '/relay': (context) => const RelayScreen(),
        '/schedule': (context) => const ScheduleScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/setting': (context) => const SettingsScreen(),
      },
    );
  }
}
