import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/auth_repository.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/presentation/widgets/app_snack_bar.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/verification_message_dialog.dart';
import '../../../../../app/animations/dialog_animations.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      AppSnackBar.showWarning(context, '请输入并确认新密码');
      return;
    }

    if (password != confirmPassword) {
      await showAnimatedDialog(
        context: context,
        builder: (context) => const VerificationMessageDialog(
          status: VerificationStatus.failure,
          message: '密码不匹配，请检查后重试。',
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authRepository.updatePassword(password: password);

      if (mounted) {
        await showAnimatedDialog(
          context: context,
          builder: (context) => VerificationMessageDialog(
            status: VerificationStatus.success,
            message: '您的密码已成功重置。您现在可以使用新密码登录。',
            onDismiss: () {
              context.go('/login');
            },
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        await showAnimatedDialog(
          context: context,
          builder: (context) => VerificationMessageDialog(
            status: VerificationStatus.failure,
            message: e.message,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await showAnimatedDialog(
          context: context,
          builder: (context) => const VerificationMessageDialog(
            status: VerificationStatus.failure,
            message: '更新密码失败，请重试。',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppTheme.textPrimary;
    final iconColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: iconColor),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          "创建新密码",
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                SvgPicture.asset(
                  'assets/images/auth_success.svg',
                  height: 200,
                ),
                const SizedBox(height: 48), // Moved svg down a bit

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "请创建您的新密码:",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                AuthTextField(
                  controller: _passwordController,
                  hintText: "新密码",
                  prefixIcon: Icons.lock_rounded,
                  isPassword: true,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _confirmPasswordController,
                  hintText: "确认密码",
                  prefixIcon: Icons.lock_rounded,
                  isPassword: true,
                ),

                const SizedBox(height: 16),

                // Remember Me Checkbox
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        activeColor: AppTheme.primary,
                        side: const BorderSide(
                          color: AppTheme.primary,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        onChanged: (val) => setState(() => _rememberMe = val ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "记住我",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Continue",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
