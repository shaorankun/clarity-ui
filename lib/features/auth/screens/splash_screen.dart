import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await context.read<AuthProvider>().checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('✦', style: TextStyle(fontSize: 48)),
              SizedBox(height: 16),
              Text('Clarity',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary, letterSpacing: 2)),
              SizedBox(height: 8),
              Text('Focus. Flow. Finish.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}