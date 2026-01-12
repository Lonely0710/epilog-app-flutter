import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository.dart';
import '../../../../app/theme/app_theme.dart';
import '../widgets/social_login_button.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;
    final secondaryTextColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final titleColor = isDark ? Colors.white : AppTheme.textPrimary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(),
              // Lottie Animation
              SizedBox(
                height: 250,
                child: Lottie.asset('assets/lottie/walking_dog.json'),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                "Let's you in",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                  fontFamily: AppTheme.primaryFont,
                ),
              ),
              const SizedBox(height: 32),

              // Social Login Buttons
              // Social Login Buttons
              SocialLoginButton(
                text: "Continue with Github",
                iconPath: 'assets/icons/ic_github.svg',
                onPressed: () async {
                  try {
                    await AuthRepository().signInWithGithub();
                  } on AuthException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message)),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Login failed')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              SocialLoginButton(
                text: "Continue with Google",
                iconPath: 'assets/icons/ic_google.svg',
                onPressed: () {
                  // Google Login
                },
              ),

              const SizedBox(height: 32),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: dividerColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "or",
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: dividerColor)),
                ],
              ),

              const SizedBox(height: 32),

              // Sign in with password button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    shadowColor: AppTheme.primary.withValues(alpha: 0.3),
                  ),
                  child: const Text(
                    "Sign in with password",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/register'),
                    child: const Text(
                      "Sign up",
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
