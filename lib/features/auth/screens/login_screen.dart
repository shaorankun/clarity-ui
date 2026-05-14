import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onGoRegister;

  const LoginScreen({super.key, required this.onGoRegister});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    // Router sẽ tự redirect khi status thay đổi
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    const Text(
                      'Welcome back 👋',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Đăng nhập để tiếp tục',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),

                    // Email
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(hintText: 'Email'),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Error
                    if (auth.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          auth.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Đăng nhập',
                      isLoading: auth.isLoading,
                      onPressed: _login,
                    ),
                    const SizedBox(height: 16),

                    // Go to register
                    Center(
                      child: GestureDetector(
                        onTap: widget.onGoRegister,
                        child: const Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Chưa có tài khoản? ',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextSpan(
                                text: 'Đăng ký',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
