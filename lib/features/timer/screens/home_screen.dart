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
import '../../tasks/providers/task_provider.dart';

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
      context.read<TimerProvider>().loadPersistedStats();
      context.read<TaskProvider>().fetchTasks();
    });
  }

  void _switchTab(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return HomeSwitcherNotifier(
      switchTo: _switchTab,
      child: Scaffold(
        backgroundColor: const Color(0xFF12121D),
        body: _screens[_index],
        bottomNavigationBar: _BottomNav(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (icon: Iconsax.timer_1,     label: 'Focus'),
      (icon: Iconsax.task_square, label: 'Tasks'),
      (icon: Iconsax.chart_2,     label: 'Stats'),
      (icon: Iconsax.people,      label: 'Social'),
      (icon: Iconsax.user,        label: 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D18),
        border: Border(top: BorderSide(color: Color(0x1AFFFFFF), width: 1)),
        boxShadow: [BoxShadow(color: Color(0x1A6C3CE0), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item     = items[i];
              final isActive = currentIndex == i;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: isActive
                      ? const EdgeInsets.symmetric(horizontal: 16, vertical: 6)
                      : const EdgeInsets.symmetric(horizontal: 8,  vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0x336C3CE0) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isActive
                        ? const [BoxShadow(color: Color(0x4D6C3CE0), blurRadius: 15)]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, size: 22, color: isActive ? const Color(0xFFCEBDFF) : const Color(0xFF948EA1)),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: isActive ? const Color(0xFFCEBDFF) : const Color(0xFF948EA1),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}