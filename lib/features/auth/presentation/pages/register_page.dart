import 'package:flutter/material.dart';
import 'dart:math';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository.dart';
import '../../../../app/theme/app_theme.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_login_row.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  final _authRepository = AuthRepository();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleGithubLogin() async {
    try {
      await _authRepository.signInWithGithub();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.primaryFont,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF333333),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            margin: const EdgeInsets.only(bottom: 20, left: 40, right: 40),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '登录失败，请稍后重试',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.primaryFont,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF333333),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            margin: const EdgeInsets.only(bottom: 20, left: 40, right: 40),
          ),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '请填写所有字段',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.primaryFont,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF333333),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          margin: const EdgeInsets.only(bottom: 20, left: 40, right: 40),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '两次输入的密码不一致',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.primaryFont,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF333333),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          margin: const EdgeInsets.only(bottom: 20, left: 40, right: 40),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate avatar URL
      // Using values provided by user: size=80, colors=..., variant=beam
      // We use the email prefix (username) as the name seed
      final nameSeed = email.split('@').first;
      final avatarUrl =
          'https://source.boringavatars.com/beam/80/$nameSeed?colors=0a0310,49007e,ff005b,ff7d10,ffb238';

      // Generate random 6-digit suffix
      final random = Random();
      final suffix = (random.nextInt(900000) + 100000).toString();
      final displayName = 'epilog_$suffix';

      final response = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        data: {
          'avatar_url': avatarUrl,
          'display_name': displayName,
          'has_set_username': false,
        },
        emailRedirectTo: 'epilog://login-callback/',
      );

      if (mounted) {
        // Check if we have a session. If so, email confirmation is disabled or auto-confirmed.
        if (response.session != null) {
          context.go('/home');
        } else {
          // No session means email confirmation is likely required.
          if (mounted) {
            context.push('/verification', extra: email);
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.primaryFont,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF333333),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            margin: const EdgeInsets.only(bottom: 20, left: 40, right: 40),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '网络连接失败，请检查网络设置',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.primaryFont,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF333333),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            margin: const EdgeInsets.only(bottom: 20, left: 40, right: 40),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _reflectRememberMe = false;
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_checkInput);
    _passwordController.addListener(_checkInput);
    _confirmPasswordController.addListener(_checkInput);
  }

  void _checkInput() {
    final hasInput = _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty;
    if (hasInput != _hasInput) {
      if (mounted) {
        setState(() {
          _hasInput = hasInput;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;
    final secondaryTextColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final titleColor = isDark ? Colors.white : AppTheme.textPrimary;
    final iconColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: iconColor),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/auth');
            }
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Lottie
                SizedBox(
                  height: 150, // Reduced from 180
                  child: Lottie.asset('assets/lottie/watchtv_splash.json'),
                ),
                const SizedBox(height: 12),

                Text(
                  "Create Your Account",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),

                const SizedBox(height: 24), // Reduced from 32

                // Email
                AuthTextField(
                  controller: _emailController,
                  hintText: "Email",
                  prefixIcon: Icons.email, // Filled
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 16), // Height is okay for tighter pack

                // Password
                AuthTextField(
                  controller: _passwordController,
                  hintText: "Password",
                  prefixIcon: Icons.lock_rounded, // Filled rounded
                  isPassword: true,
                ),

                const SizedBox(height: 16),

                // Confirm Password
                AuthTextField(
                  controller: _confirmPasswordController,
                  hintText: "Confirm Password",
                  prefixIcon: Icons.lock_rounded,
                  isPassword: true,
                ),

                const SizedBox(height: 20),

                // Remember Me Checkbox
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _reflectRememberMe,
                        activeColor: AppTheme.primary,
                        side: const BorderSide(
                          color: AppTheme.primary, // Primary when unchecked
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _reflectRememberMe = val ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Remember me",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Sign Up Button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: _hasInput
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                              spreadRadius: 2,
                            )
                          ]
                        : [],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      elevation: 0,
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
                            "Sign up",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24), // Reduced from 32

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: dividerColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "or continue with",
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: dividerColor)),
                  ],
                ),

                const SizedBox(height: 24), // Reduced from 32

                // Social Login
                SocialLoginRow(
                  onGithubPressed: _handleGithubLogin,
                  onGooglePressed: null, // Gmail login temporarily disabled
                ),

                const SizedBox(height: 20), // Reduced from 24 (tighter spacing)

                // Sign in Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pushReplacement('/login'),
                      child: const Text(
                        "Sign in",
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24), // Reduced from 48
              ],
            ),
          ),
        ),
      ),
    );
  }
}
