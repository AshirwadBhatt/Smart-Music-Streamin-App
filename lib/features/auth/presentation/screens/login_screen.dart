import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _nameCtrl    = TextEditingController();
  final _formKey     = GlobalKey<FormState>();
  bool  _isSignUp    = false;
  bool  _obscurePass = true;

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }

  @override
  void dispose() {
    _tab.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(authNotifierProvider.notifier);
    if (_isSignUp) {
      await notifier.signUpEmail(_emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim());
    } else {
      await notifier.signInEmail(_emailCtrl.text.trim(), _passCtrl.text);
    }
    final state = ref.read(authNotifierProvider);
    state.whenOrNull(
      data: (user) { if (user != null && mounted) context.go('/home'); },
      error: (e, _) => _showSnack(e.toString()),
    );
  }

  Future<void> _handleGoogle() async {
    // Triggers OAuth redirect — browser will redirect back after login
    await ref.read(authNotifierProvider.notifier).signInGoogle();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final loading   = authState is AsyncLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(children: [
              const SizedBox(height: 40),
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 24)],
                ),
                child: const Icon(Icons.music_note_rounded, color: Colors.black, size: 38),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 20),
              const Text('ASHU', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary, letterSpacing: 5))
                  .animate().fade(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 6),
              const Text('Your music. Everywhere.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted))
                  .animate().fade(delay: 350.ms, duration: 400.ms),
              const SizedBox(height: 36),

              // Tab bar
              Container(
                decoration: BoxDecoration(color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14)),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12)),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.black,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  tabs: const [Tab(text: 'Email'), Tab(text: 'Phone')],
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.all(4),
                  splashFactory: NoSplash.splashFactory,
                ),
              ).animate().fade(delay: 400.ms, duration: 400.ms),
              const SizedBox(height: 28),

              SizedBox(
                height: _isSignUp ? 320 : 260,
                child: TabBarView(
                  controller: _tab,
                  children: [
                    // ── Email tab ──
                    Form(
                      key: _formKey,
                      child: Column(children: [
                        if (_isSignUp) ...[
                          AuthTextField(controller: _nameCtrl, hint: 'Full name',
                              icon: Icons.person_outline_rounded,
                              validator: (v) => v!.isEmpty ? 'Enter your name' : null),
                          const SizedBox(height: 14),
                        ],
                        AuthTextField(controller: _emailCtrl, hint: 'Email address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v!.contains('@') ? null : 'Enter valid email'),
                        const SizedBox(height: 14),
                        AuthTextField(controller: _passCtrl, hint: 'Password',
                            icon: Icons.lock_outline_rounded, obscureText: _obscurePass,
                            suffix: IconButton(
                              icon: Icon(_obscurePass
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                                  color: AppColors.textMuted, size: 20),
                              onPressed: () => setState(() => _obscurePass = !_obscurePass),
                            ),
                            validator: (v) => v!.length >= 6 ? null : 'Min 6 characters'),
                        const SizedBox(height: 20),
                        _AuthButton(label: _isSignUp ? 'Create Account' : 'Sign In',
                            loading: loading, onTap: _handleEmailAuth),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () => setState(() => _isSignUp = !_isSignUp),
                          child: Text(
                            _isSignUp ? 'Already have an account? Sign in' : 'New here? Create account',
                            style: const TextStyle(color: AppColors.primary,
                                fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ]),
                    ),

                    // ── Phone tab — needs Twilio ──
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(16)),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.phone_disabled_outlined,
                              color: AppColors.textMuted, size: 40),
                          const SizedBox(height: 14),
                          const Text('Phone login not available',
                              style: TextStyle(color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 8),
                          const Text(
                            'Phone OTP requires Twilio SMS setup in Supabase.\nPlease use Email or Google login.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => _tab.animateTo(0),
                            child: const Text('← Use Email instead',
                                style: TextStyle(color: AppColors.primary)),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Row(children: [
                const Expanded(child: Divider(color: AppColors.divider)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text('or', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ),
                const Expanded(child: Divider(color: AppColors.divider)),
              ]).animate().fade(delay: 500.ms, duration: 400.ms),
              const SizedBox(height: 20),

              // Google button
              SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton(
                  onPressed: loading ? null : _handleGoogle,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(color: Colors.white,
                                borderRadius: BorderRadius.circular(4)),
                            child: const Center(child: Text('G',
                                style: TextStyle(color: Color(0xFF4285F4),
                                    fontWeight: FontWeight.w900, fontSize: 14))),
                          ),
                          const SizedBox(width: 12),
                          const Text('Continue with Google',
                              style: TextStyle(color: AppColors.textPrimary,
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                        ]),
                ),
              ).animate().fade(delay: 600.ms, duration: 400.ms),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  const _AuthButton({required this.label, required this.loading, this.onTap});

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: loading ? null : onTap,
    child: loading
        ? const SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
        : Text(label),
  );
}
