import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/admin_main_nav.dart';
import 'features/auth/welcome_screen.dart';
import 'features/guru/guru_main_nav.dart';
import 'features/ortu/ortu_main_nav.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MurabbiApp());
}

class MurabbiApp extends StatelessWidget {
  const MurabbiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Murabbi App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _StartupGate(),
    );
  }
}

class _StartupGate extends StatelessWidget {
  const _StartupGate();

  Future<Widget> _resolve() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final role = prefs.getString('user_role');

    if (token == null || token.isEmpty || role == null || role.isEmpty) {
      return const WelcomeScreen();
    }

    return switch (role) {
      'admin' => const AdminMainNav(),
      'ortu' => const OrtuMainNav(),
      _ => const GuruMainNav(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _resolve(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!;
      },
    );
  }
}
