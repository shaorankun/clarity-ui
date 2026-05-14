import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CircularTimer extends StatelessWidget {
  final double progress;  // 0.0 → 1.0
  final String timeLabel;
  final bool isRunning;

  const CircularTimer({
    super.key,
    required this.progress,
    required this.timeLabel,
    this.isRunning = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect when running
          if (isRunning)
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),

          // Progress ring
          SizedBox(
            width: 220,
            height: 220,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              strokeCap: StrokeCap.round,
            ),
          ),

          // Time text
          Text(
            timeLabel,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}