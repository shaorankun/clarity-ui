import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stats_provider.dart';
import '../models/stats_model.dart';
import '../../../core/theme/app_colors.dart';

// ── Design tokens (mirrors Stitch / app_colors) ──────────────────────────────
class _C {
  static const bg           = Color(0xFF12121D);
  static const surface      = Color(0xFF1F1E2A);
  static const surfaceHigh  = Color(0xFF292935);
  static const surfaceHighest = Color(0xFF343440);
  static const outline      = Color(0xFF948EA1);
  static const outlineVar   = Color(0xFF494455);

  // Primary (purple)
  static const primary      = Color(0xFFCEBDFF);
  static const primaryCont  = Color(0xFF6C3CE0);

  // Secondary (lavender)
  static const secondary    = Color(0xFFD2BBFF);

  // Tertiary (cyan)
  static const tertiary     = Color(0xFF00DBE9);

  static const onSurface    = Color(0xFFE3E0F1);
  static const onSurfaceVar = Color(0xFFCBC3D7);

  // Gradient helpers
  static LinearGradient get glassCard => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xB31F1E2A), Color(0xCC0D0D18)],
  );
}

// ── Main Screen ───────────────────────────────────────────────────────────────
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F0F1A), Color(0xFF12121D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: stats.isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: _C.primary,
            strokeWidth: 2,
          ),
        )
            : stats.overview == null
            ? const Center(
          child: Text(
            'No data yet',
            style: TextStyle(color: _C.outline),
          ),
        )
            : _buildContent(context, stats),
      ),
    );
  }

  Widget _buildContent(BuildContext context, StatsProvider stats) {
    final o = stats.overview!;
    final today = o.weekly.isNotEmpty ? o.weekly.last : null;

    // Date range label: show Mon–Sun of current week
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd   = weekStart.add(const Duration(days: 6));
    final months    = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateLabel =
        '${months[weekStart.month - 1]} ${weekStart.day} — ${months[weekEnd.month - 1]} ${weekEnd.day}, ${weekEnd.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          const Text(
            'Stats',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: _C.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateLabel,
            style: const TextStyle(
              fontSize: 13,
              color: _C.outline,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),

          // ── 2×2 Metric Cards ─────────────────────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _MetricCard(
                label: 'CURRENT STREAK',
                icon: Icons.local_fire_department_outlined,
                iconColor: _C.secondary,
                value: '${o.currentStreak}',
                unit: 'days',
                valueColor: _C.secondary,
              ),
              _MetricCard(
                label: 'LONGEST STREAK',
                icon: Icons.workspace_premium_outlined,
                iconColor: _C.primary,
                value: '${o.longestStreak}',
                unit: 'days',
                valueColor: _C.primary,
              ),
              _MetricCard(
                label: 'TOTAL FOCUS',
                icon: Icons.timer_outlined,
                iconColor: _C.primary,
                value: '${o.totalMinutes ~/ 60}',
                unit: 'h',
                subUnit: o.totalMinutes % 60 > 0 ? '${o.totalMinutes % 60}m' : null,
                valueColor: _C.primary,
              ),
              _MetricCard(
                label: 'TOTAL SESSIONS',
                icon: Icons.layers_outlined,
                iconColor: _C.tertiary,
                value: '${o.totalSessions}',
                unit: '',
                valueColor: _C.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Today ────────────────────────────────────────────────────────
          const Text(
            'Today',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: _C.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _TodayCard(today: today, stats: stats),
          const SizedBox(height: 24),

          // ── Daily Focus Time Bar Chart ───────────────────────────────────
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daily Focus Time',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _C.onSurface,
                      ),
                    ),
                    const Icon(Icons.more_horiz, color: _C.outline, size: 20),
                  ],
                ),
                const SizedBox(height: 20),
                o.weekly.isEmpty
                    ? const SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'No data this week',
                      style: TextStyle(color: _C.outline, fontSize: 13),
                    ),
                  ),
                )
                    : _WeeklyBarChart(weekly: o.weekly),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Personal Best ────────────────────────────────────────────────
          _PersonalBestCard(weekly: o.weekly, stats: stats),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Glass Card container ──────────────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: _C.glassCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C3CE0).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Metric Card ───────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String unit;
  final String? subUnit; // e.g. "30m" shown after the primary unit
  final Color valueColor;

  const _MetricCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    this.subUnit,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: _C.glassCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _C.outline,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Icon(icon, color: iconColor.withOpacity(0.9), size: 20),
            ],
          ),
          // Value row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                  height: 1.0,
                  letterSpacing: -1,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _C.outline,
                    ),
                  ),
                ),
              ],
              if (subUnit != null && subUnit!.isNotEmpty) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    subUnit!,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: valueColor.withOpacity(0.75),
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Today Card ────────────────────────────────────────────────────────────────
class _TodayCard extends StatelessWidget {
  final DailyStats? today;
  final StatsProvider stats;

  const _TodayCard({required this.today, required this.stats});

  @override
  Widget build(BuildContext context) {
    final focusLabel = today != null ? stats.formatMinutes(today!.totalMinutes) : '0m';
    final sessions   = today?.sessionCount ?? 0;
    final tasks      = today?.tasksCompleted ?? 0;

    return _GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _TodayItem(
              label: 'FOCUS TIME',
              value: focusLabel,
              valueColor: _C.primary,
            ),
            VerticalDivider(
              color: _C.outlineVar.withOpacity(0.3),
              thickness: 1,
              width: 1,
            ),
            _TodayItem(
              label: 'SESSIONS',
              value: '$sessions',
              valueColor: _C.secondary,
            ),
            VerticalDivider(
              color: _C.outlineVar.withOpacity(0.3),
              thickness: 1,
              width: 1,
            ),
            _TodayItem(
              label: 'TASKS COMPLETED',
              value: '$tasks',
              valueColor: _C.tertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _TodayItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _C.outline,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Weekly Bar Chart ──────────────────────────────────────────────────────────
class _WeeklyBarChart extends StatelessWidget {
  final List<DailyStats> weekly;
  const _WeeklyBarChart({required this.weekly});

  @override
  Widget build(BuildContext context) {
    final maxMinutes = weekly.map((d) => d.totalMinutes).fold(0, (a, b) => a > b ? a : b);
    const dayLabels  = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const barHeight  = 100.0;
    const minBar     = 6.0;

    return SizedBox(
      height: barHeight + 32,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(weekly.length, (i) {
          final d       = weekly[i];
          final ratio   = maxMinutes == 0 ? 0.0 : d.totalMinutes / maxMinutes;
          final isToday = i == weekly.length - 1;
          final barH    = ratio == 0 ? minBar : (barHeight * ratio).clamp(minBar, barHeight);

          // Compute day label index based on today's weekday
          final todayWd  = DateTime.now().weekday; // 1=Mon..7=Sun
          final dayIdx   = ((todayWd - 1) - (weekly.length - 1 - i)) % 7;
          final label    = dayLabels[dayIdx < 0 ? dayIdx + 7 : dayIdx];

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 400 + i * 60),
                  curve: Curves.easeOut,
                  height: barH,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: isToday
                        ? const LinearGradient(
                      colors: [Color(0xFFCEBDFF), Color(0xFFB89CFF)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    )
                        : LinearGradient(
                      colors: [
                        const Color(0xFF6C3CE0).withOpacity(0.25),
                        const Color(0xFF6C3CE0).withOpacity(0.15),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    boxShadow: isToday
                        ? [
                      BoxShadow(
                        color: const Color(0xFF6C3CE0).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ]
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    color: isToday ? _C.primary : _C.outline,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Task Completion Card ──────────────────────────────────────────────────────
class _TaskCompletionCard extends StatelessWidget {
  final DailyStats today;
  const _TaskCompletionCard({required this.today});

  @override
  Widget build(BuildContext context) {
    // Simple heuristic: completed / (completed + 2 remaining)
    final completed = today.tasksCompleted;
    final total     = completed > 0 ? completed + 2 : 8;
    final pct       = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    final pctLabel  = '${(pct * 100).round()}%';

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Task Completion',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _C.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$completed of $total goals met',
                    style: const TextStyle(fontSize: 13, color: _C.outline),
                  ),
                ],
              ),
              Text(
                pctLabel,
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: _C.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: _C.surfaceHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(_C.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Personal Best Card ────────────────────────────────────────────────────────
class _PersonalBestCard extends StatelessWidget {
  final List<DailyStats> weekly;
  final StatsProvider stats;

  const _PersonalBestCard({required this.weekly, required this.stats});

  @override
  Widget build(BuildContext context) {
    // Find best day
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    int bestIdx    = 0;
    for (var i = 1; i < weekly.length; i++) {
      if (weekly[i].totalMinutes > weekly[bestIdx].totalMinutes) bestIdx = i;
    }
    final bestDay = weekly.isNotEmpty ? weekly[bestIdx] : null;

    final todayWd    = DateTime.now().weekday;
    final rawDayIdx  = ((todayWd - 1) - (weekly.length - 1 - bestIdx)) % 7;
    final dayName    = weekly.isNotEmpty
        ? dayNames[rawDayIdx < 0 ? rawDayIdx + 7 : rawDayIdx]
        : 'Tuesday';
    final timeLabel  = bestDay != null ? stats.formatMinutes(bestDay.totalMinutes) : '—';

    return Stack(
      children: [
        _GlassCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PERSONAL BEST',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _C.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Peak Performance',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _C.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your best day was $dayName\nwith $timeLabel of deep focus.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _C.onSurfaceVar,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _C.primary.withOpacity(0.35), width: 2),
                  color: _C.primaryCont.withOpacity(0.12),
                ),
                child: const Icon(Icons.auto_awesome, color: _C.primary, size: 28),
              ),
            ],
          ),
        ),
        // Decorative glow
        Positioned(
          right: -20,
          bottom: -20,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.primaryCont.withOpacity(0.1),
            ),
          ),
        ),
      ],
    );
  }
}