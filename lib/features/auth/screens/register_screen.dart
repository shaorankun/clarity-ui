import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onGoLogin;
  const RegisterScreen({super.key, required this.onGoLogin});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    await context.read<AuthProvider>().register(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      _nameCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                const Text('Tạo tài khoản ✦',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                const Text('Bắt đầu hành trình tập trung của bạn',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 32),

                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'Display name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'Email'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textMuted),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                if (auth.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(auth.errorMessage!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                  ),

                const SizedBox(height: 16),
                AppButton(
                  label: 'Đăng ký',
                  isLoading: auth.isLoading,
                  onPressed: _register,
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: widget.onGoLogin,
                    child: const Text.rich(TextSpan(children: [
                      TextSpan(text: 'Đã có tài khoản? ',
                          style: TextStyle(color: AppColors.textSecondary)),
                      TextSpan(text: 'Đăng nhập',
                          style: TextStyle(color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ])),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}