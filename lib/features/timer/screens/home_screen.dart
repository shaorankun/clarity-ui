import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../timer/providers/timer_provider.dart';
import 'timer_screen.dart';
import '../../tasks/screens/tasks_screen.dart';
import '../../stats/screens/stats_screen.dart';
import '../../rooms/screens/rooms_screen.dart';
import '../../auth/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _screens = [
    const TimerScreen(),
    const TasksScreen(),
    const StatsScreen(),
    const RoomsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TimerProvider>().cancelStaleSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.surfaceLight, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Iconsax.timer_1), label: 'Timer'),
            BottomNavigationBarItem(icon: Icon(Iconsax.task_square), label: 'Tasks'),
            BottomNavigationBarItem(icon: Icon(Iconsax.chart_2), label: 'Stats'),
            BottomNavigationBarItem(icon: Icon(Iconsax.people), label: 'Rooms'),
            BottomNavigationBarItem(icon: Icon(Iconsax.user), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}