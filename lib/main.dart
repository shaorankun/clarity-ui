import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/network/app_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/timer/providers/timer_provider.dart';
import 'features/tasks/providers/task_provider.dart';
import 'features/stats/providers/stats_provider.dart';
import 'features/rooms/providers/room_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
      ],
      child: const ClarityApp(),
    ),
  );
}

class ClarityApp extends StatefulWidget {
  const ClarityApp({super.key});

  @override
  State<ClarityApp> createState() => _ClarityAppState();
}

class _ClarityAppState extends State<ClarityApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      final timer = context.read<TimerProvider>();
      final room  = context.read<RoomProvider>();

      if (timer.status != TimerStatus.idle) {
        timer.abandon();
      }
      if (room.currentRoom != null) {
        room.leaveRoom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clarity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppRouter(),
    );
  }
}