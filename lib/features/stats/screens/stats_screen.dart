import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stats_provider.dart';
import '../models/stats_model.dart';
import '../../../core/theme/app_colors.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<StatsProvider>().fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        child: stats.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : stats.overview == null
            ? const Center(child: Text('No data yet',
            style: TextStyle(color: AppColors.textSecondary)))
            : _buildContent(context, stats),
      ),
    );
  }

  Widget _buildContent(BuildContext context, StatsProvider stats) {
    final o = stats.overview!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text('Your Progress',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 24),

          // Streak cards
          Row(
            children: [
              Expanded(child: _statCard(
                icon: '🔥',
                label: 'Current Streak',
                value: '${o.currentStreak} days',
              )),
              const SizedBox(width: 12),
              Expanded(child: _statCard(
                icon: '🏆',
                label: 'Longest Streak',
                value: '${o.longestStreak} days',
              )),
            ],
          ),
          const SizedBox(height: 12),

          // Total cards
          Row(
            children: [
              Expanded(child: _statCard(
                icon: '⏱️',
                label: 'Total Focus',
                value: stats.formatMinutes(o.totalMinutes),
              )),
              const SizedBox(width: 12),
              Expanded(child: _statCard(
                icon: '✅',
                label: 'Total Sessions',
                value: '${o.totalSessions}',
              )),
            ],
          ),

          const SizedBox(height: 28),

          // Weekly chart
          const Text('This Week',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),

          o.weekly.isEmpty
              ? _emptyChart()
              : _WeeklyChart(weekly: o.weekly),

          const SizedBox(height: 28),

          // Today summary
          if (o.weekly.isNotEmpty) ...[
            const Text('Today',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            _todaySummary(o.weekly.last, stats),
          ],
        ],
      ),
    );
  }

  Widget _statCard({
    required String icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _emptyChart() {
    return Container(
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text('No data this week',
          style: TextStyle(color: AppColors.textMuted)),
    );
  }

  Widget _todaySummary(DailyStats today, StatsProvider stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('⏱️', stats.formatMinutes(today.totalMinutes), 'focused'),
          _divider(),
          _summaryItem('🍅', '${today.sessionCount}', 'sessions'),
          _divider(),
          _summaryItem('✅', '${today.tasksCompleted}', 'tasks done'),
        ],
      ),
    );
  }

  Widget _summaryItem(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _divider() => Container(
      width: 1, height: 40, color: AppColors.surfaceLight);
}

// ── Weekly Bar Chart ──────────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  final List<DailyStats> weekly;
  const _WeeklyChart({required this.weekly});

  @override
  Widget build(BuildContext context) {
    final maxMinutes = weekly
        .map((d) => d.totalMinutes)
        .fold(0, (a, b) => a > b ? a : b);

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(weekly.length, (i) {
                final d = weekly[i];
                final ratio = maxMinutes == 0
                    ? 0.0 : d.totalMinutes / maxMinutes;
                final isToday = i == weekly.length - 1;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Minute label on top of bar
                        if (d.totalMinutes > 0)
                          Text('${d.totalMinutes}m',
                              style: const TextStyle(
                                  fontSize: 9, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        // Bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          height: ratio == 0 ? 4 : 100 * ratio,
                          decoration: BoxDecoration(
                            gradient: isToday
                                ? AppColors.primaryGradient
                                : LinearGradient(colors: [
                              AppColors.primary.withOpacity(0.5),
                              AppColors.primaryLight.withOpacity(0.5),
                            ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(color: AppColors.surfaceLight, height: 1),
          const SizedBox(height: 8),

          // Day labels
          Row(
            children: List.generate(weekly.length, (i) {
              final isToday = i == weekly.length - 1;
              // Map index to day label based on today
              final dayIndex = (DateTime.now().weekday - 1 - (weekly.length - 1 - i)) % 7;
              final label = days[dayIndex < 0 ? dayIndex + 7 : dayIndex];
              return Expanded(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isToday ? AppColors.primary : AppColors.textMuted,
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    )),
              );
            }),
          ),
        ],
      ),
    );
  }
}