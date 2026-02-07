import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/theme/app_theme.dart';
import 'package:drama_tracker_flutter/core/presentation/widgets/app_snack_bar.dart';
import 'package:drama_tracker_flutter/core/services/secure_storage_service.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/verification_message_dialog.dart';
import '../../../../../app/animations/dialog_animations.dart';
import '../../../data/auth_repository.dart';

class ForgotPasswordVerificationPage extends StatefulWidget {
  final String email;

  const ForgotPasswordVerificationPage({super.key, required this.email});

  @override
  State<ForgotPasswordVerificationPage> createState() => _ForgotPasswordVerificationPageState();
}

class _ForgotPasswordVerificationPageState extends State<ForgotPasswordVerificationPage> {
  final _authRepository = AuthRepository();
  // Clerk defaults to 6 digits
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _rememberMe = false;
  int _secondsRemaining = 30;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        if (mounted) setState(() => _canResend = true);
      }
    });
  }

  void _handleResend() {
    // Logic to resend email would go here
    // For now just restart timer
    _startTimer();
  }

  Future<void> _handleVerify() async {
    final code = _controllers.map((c) => c.text).join();
    final password = _passwordController.text.trim();

    if (code.length != 6) return;
    if (password.isEmpty || password.length < 8) {
      AppSnackBar.showWarning(context, "请输入至少8位新密码");
      return;
    }

    setState(() => _isVerifying = true);

    try {
      await _authRepository.verifyPasswordResetOtp(
        email: widget.email,
        token: code,
        password: password,
      );

      // Save credentials if "Remember Me" is checked
      if (_rememberMe) {
        await SecureStorageService.saveCredentials(
          email: widget.email,
          password: password,
        );
      } else {
        await SecureStorageService.clearCredentials();
      }

      if (mounted) {
        // Show success dialog
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
    } catch (e) {
      if (mounted) {
        String errorMessage;
        final errStr = e.toString().toLowerCase();

        if (errStr.contains('form_password_pwned') || errStr.contains('data breach') || errStr.contains('pwned')) {
          errorMessage = "该密码不够安全（曾在历史数据泄露中出现），请使用更复杂的密码";
        } else if (errStr.contains('password') && errStr.contains('weak')) {
          errorMessage = "密码强度太低，请尝试更复杂的组合";
        } else {
          errorMessage = "验证失败: $e";
        }

        await showAnimatedDialog(
          context: context,
          builder: (context) => VerificationMessageDialog(
            status: VerificationStatus.failure,
            message: errorMessage,
          ),
        );
        setState(() => _isVerifying = false);
      }
    }
  }

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) _focusNodes[index + 1].requestFocus(); // Adjusted loop limit
    } else {
      if (index > 0) _focusNodes[index - 1].requestFocus();
    }
  }

  // ... (maskEmail unchanged)

  @override
  Widget build(BuildContext context) {
    // Colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputFillColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100;
    final inputBorderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Scaffold(
      appBar: AppBar(
        title: const Text("验证邮箱"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Text(
              "请输入发送至 ${widget.email} 的验证码",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            // OTP Input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 44, // Slightly wider for 6 boxes
                  height: 56,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                    decoration: InputDecoration(
                      counterText: "",
                      filled: true,
                      fillColor: inputFillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: inputBorderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: inputBorderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) => _onCodeChanged(value, index),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // Password Inputs
            AuthTextField(
              controller: _passwordController,
              hintText: '输入新密码',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _confirmPasswordController,
              hintText: '确认新密码',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
            ),

            const SizedBox(height: 24),

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
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("重新发送 ", style: TextStyle(fontSize: 14, color: textColor)),
                Text("$_secondsRemaining s",
                    style: const TextStyle(fontSize: 14, color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            if (_canResend)
              TextButton(
                onPressed: _handleResend,
                child: const Text("重新发送验证码", style: TextStyle(color: AppTheme.primary)),
              ),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("验 证",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
