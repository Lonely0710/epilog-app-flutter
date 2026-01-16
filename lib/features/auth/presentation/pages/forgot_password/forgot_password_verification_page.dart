import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../app/theme/app_theme.dart';
import 'package:drama_tracker_flutter/core/presentation/widgets/app_snack_bar.dart';
import '../../../data/auth_repository.dart';
import '../../widgets/verification_message_dialog.dart';
import '../../../../../app/animations/dialog_animations.dart';

class ForgotPasswordVerificationPage extends StatefulWidget {
  final String email;

  const ForgotPasswordVerificationPage({super.key, required this.email});

  @override
  State<ForgotPasswordVerificationPage> createState() => _ForgotPasswordVerificationPageState();
}

class _ForgotPasswordVerificationPageState extends State<ForgotPasswordVerificationPage> {
  final _authRepository = AuthRepository();
  final List<TextEditingController> _controllers = List.generate(8, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(8, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    try {
      await _authRepository.sendPasswordResetEmail(email: widget.email);
      if (mounted) {
        AppSnackBar.showSuccess(context, '验证码已重新发送！');
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, message: '重发失败: $e');
      }
    }
  }

  Future<void> _handleVerify() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 8) return;

    setState(() => _isVerifying = true);

    try {
      final response = await _authRepository.verifyPasswordResetOtp(
        email: widget.email,
        token: code,
      );

      if (mounted) {
        if (response.session != null) {
          context.pushReplacement('/forgot-password/reset');
        } else {
          context.pushReplacement('/forgot-password/reset');
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        await showAnimatedDialog(
          context: context,
          builder: (context) => VerificationMessageDialog(
            status: VerificationStatus.failure,
            message: '验证失败: ${e.message}',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Handle generic errors (like HandshakeException) with a user-friendly message
        final errorMessage = e.toString().contains('HandshakeException') || e.toString().contains('SocketException')
            ? '网络连接失败，请检查网络设置'
            : '验证码无效，请重试';

        await showAnimatedDialog(
          context: context,
          builder: (context) => VerificationMessageDialog(
            status: VerificationStatus.failure,
            message: errorMessage,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 7) _focusNodes[index + 1].requestFocus();
    } else {
      if (index > 0) _focusNodes[index - 1].requestFocus();
    }
    // Auto submit? Optional.
  }

  String _maskEmail(String email) {
    if (email.length <= 4) return email;
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    if (name.length <= 2) return "$name***@${parts[1]}";
    return "${name.substring(0, 2)}***${name.substring(name.length - 1)}@${parts[1]}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final inputFillColor = isDark ? Colors.grey.shade800 : Colors.white;
    final inputBorderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          "忘记密码",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              Text(
                "验证码已发送至",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                _maskEmail(widget.email),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 48),

              // OTP Input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(8, (index) {
                  return SizedBox(
                    width: 38, // Slightly smaller to fit 8 boxes
                    height: 52,
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
      ),
    );
  }
}
