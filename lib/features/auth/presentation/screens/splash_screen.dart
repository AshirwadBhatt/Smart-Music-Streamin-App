import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    context.go(session != null ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated logo
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 32, spreadRadius: 4)],
                ),
                child: const Icon(Icons.music_note_rounded, color: Colors.black, size: 52),
              )
              .animate()
              .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut)
              .fade(duration: 400.ms),

              const SizedBox(height: 24),
              const Text('ASHU', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 6))
              .animate().fade(delay: 400.ms, duration: 400.ms).slideY(begin: 0.3, end: 0),

              const SizedBox(height: 8),
              const Text('Advanced Streaming Hub for Users',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted, letterSpacing: 2))
              .animate().fade(delay: 700.ms, duration: 400.ms),

              const SizedBox(height: 64),
              SizedBox(
                width: 28, height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.withOpacity(0.7)),
                ),
              ).animate().fade(delay: 1200.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}
