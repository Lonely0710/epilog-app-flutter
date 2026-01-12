import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/auth_repository.dart';
import '../widgets/verification_message_dialog.dart';
import '../../../../app/animations/dialog_animations.dart';

class VerificationPage extends StatefulWidget {
  final String email;

  const VerificationPage({super.key, required this.email});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _authRepository = AuthRepository();
  // Supabase defaults to 6 digits for OTP, but user reports 8
  final List<TextEditingController> _controllers =
      List.generate(8, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(8, (_) => FocusNode());

  // Timer state
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
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;

    try {
      await _authRepository.resendEmailOtp(email: widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Code resent!'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleVerify() async {
    final code = _controllers.map((c) => c.text).join();
    // Check for 8 digits
    if (code.length != 8) {
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final response = await _authRepository.verifyEmailOtp(
        email: widget.email,
        token: code,
      );

      if (mounted) {
        if (response.session != null) {
          // Wait for dialog to be closed
          await showAnimatedDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => VerificationMessageDialog(
              status: VerificationStatus.success,
              message:
                  'Your account is ready to use. Please continue to set up your profile.',
            ),
          );

          if (mounted) {
            context.go('/setup-profile');
          }
        } else {
          throw const AuthException('Verification failed, no session created.');
        }
      }
    } catch (e) {
      if (mounted) {
        await showAnimatedDialog(
          context: context,
          builder: (context) => VerificationMessageDialog(
            status: VerificationStatus.failure,
            message: e is AuthException
                ? e.message
                : 'Invalid code. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 7) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black;
    final titleColor = isDark ? Colors.white : Colors.black;
    final inputFillColor = isDark ? Colors.grey.shade800 : Colors.white;
    final inputBorderColor =
        isDark ? Colors.grey.shade700 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: iconColor),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Email Verification",
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24), // Adjusted height
              // Image
              SvgPicture.asset(
                'assets/images/auth_email_verify.svg',
                height: 200,
              ),
              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Code has been send to ",
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  Text(
                    _maskEmail(widget.email),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Code Input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(8, (index) {
                  return SizedBox(
                    width: 36, // Reduced width to fits 8 items
                    height: 56, // Adjusted height
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        counterText: "",
                        filled: true,
                        fillColor: inputFillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: inputBorderColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: inputBorderColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) => _onCodeChanged(value, index),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  );
                }),
              ),

              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Resend code in ",
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  Text(
                    "$_secondsRemaining s",
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.primary, // Changed color
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              if (_canResend)
                TextButton(
                  onPressed: _handleResend,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary, // Added style
                  ),
                  child: const Text("Resend Code"),
                ),

              const SizedBox(height: 100),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary, // Changed color
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Verify",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _maskEmail(String email) {
    if (email.length <= 4) return email;
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];

    if (name.length <= 2) return "$name***@$domain";

    return "${name.substring(0, 2)}***${name.substring(name.length - 1)}@$domain";
  }
}
