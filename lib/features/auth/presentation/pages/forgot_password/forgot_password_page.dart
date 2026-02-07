import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../data/auth_repository.dart';
import '../../../../../app/theme/app_theme.dart';
import 'package:drama_tracker_flutter/core/presentation/widgets/app_snack_bar.dart';
import '../../widgets/auth_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _isLoading = false;
  String? _selectedMethod; // 'sms' or 'email'

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_selectedMethod == null) {
      AppSnackBar.showWarning(context, '请选择验证方式');
      return;
    }

    if (_selectedMethod == 'sms') {
      AppSnackBar.showWarning(context, '短信重置暂不可用，请使用邮箱');
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      AppSnackBar.showWarning(context, '请输入您的邮箱');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authRepository.sendPasswordResetEmail(email: email);
      if (mounted) {
        context.push('/forgot-password/verify', extra: email);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, message: '发送重置邮件失败: ${e.toString()}');
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
          "忘记密码",
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
                const SizedBox(height: 20),
                SvgPicture.asset(
                  'assets/images/auth_forget_loading.svg',
                  height: 200,
                ),
                const SizedBox(height: 40),
                Text(
                  "选择重置密码的验证方式",
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // Selection Card - SMS
                _buildContactCard(
                  icon: Icons.message_rounded,
                  title: "短信验证:",
                  value: "+1 111 ******99",
                  isSelected: _selectedMethod == 'sms',
                  isDark: isDark,
                  onTap: () {
                    setState(() {
                      _selectedMethod = 'sms';
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Selection Card - Email
                _buildContactCard(
                  icon: Icons.email_rounded,
                  title: "邮箱验证:",
                  value: _emailController.text.isEmpty ? "yourname@example.com" : _emailController.text,
                  isSelected: _selectedMethod == 'email',
                  isDark: isDark,
                  onTap: () {
                    setState(() {
                      _selectedMethod = 'email';
                    });
                  },
                ),

                // Animated Input Field
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _selectedMethod == null
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            const SizedBox(height: 32),
                            AuthTextField(
                              controller: _emailController,
                              hintText: _selectedMethod == 'email' ? "请输入邮箱" : "请输入手机号",
                              prefixIcon:
                                  _selectedMethod == 'email' ? Icons.email_rounded : Icons.phone_android_rounded,
                              keyboardType:
                                  _selectedMethod == 'email' ? TextInputType.emailAddress : TextInputType.phone,
                              onChanged: (val) => setState(() {}),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleContinue,
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
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "继 续",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String value,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.1)
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primary : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
