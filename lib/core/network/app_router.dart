import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/rooms/providers/room_provider.dart';
import '../../features/timer/screens/home_screen.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    if (status == AuthStatus.authenticated) {
      Future.microtask(() =>
          context.read<RoomProvider>().restoreRoom());
    }

    switch (status) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.unauthenticated:
        return _AuthFlow();
      case AuthStatus.authenticated:
        return const HomeScreen();
    }
  }
}

class _AuthFlow extends StatefulWidget {
  @override
  State<_AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<_AuthFlow> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      return LoginScreen(
        onGoRegister: () => setState(() => _showLogin = false),
      );
    }
    return RegisterScreen(
      onGoLogin: () => setState(() => _showLogin = true),
    );
  }
}