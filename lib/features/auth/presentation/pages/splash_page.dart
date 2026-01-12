import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Keep the animation for at least 2 seconds for branding
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      try {
        // Validate session against server to ensure user wasn't deleted
        await Supabase.instance.client.auth.getUser();
        if (mounted) {
          context.go('/home');
        }
      } catch (e) {
        // If getUser fails (e.g. user deleted), sign out and go to login
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (_) {
          // Ignore signOut errors (e.g. network issues)
        }
        if (mounted) {
          context.go('/auth');
        }
      }
    } else {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sloganColor = isDark ? Colors.white70 : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade500 : Colors.grey;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Lottie Animations
            SizedBox(
              height: 200,
              width: 300,
              child: Lottie.asset('assets/lottie/tv_loading.json'),
            ),
            SizedBox(
              height: 100,
              width: 300,
              child: Lottie.asset('assets/lottie/plane_loading.json'),
            ),
            const SizedBox(height: 20),
            // Slogan
            Text(
              "Your films. Your archives.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'LibreBaskerville',
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: sloganColor,
              ),
            ),
            const Spacer(),
            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/ic_logo.png',
                    width: 48,
                    height: 48,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "影迹",
                        style: TextStyle(
                          fontFamily: 'FangZheng',
                          fontSize: 24,
                          color: isDark
                              ? Colors.white
                              : const Color.fromARGB(255, 108, 114, 128),
                          height: 1.0,
                        ),
                      ),
                      Text(
                        "Epilog",
                        style: TextStyle(
                          fontFamily: 'LibreBaskerville',
                          fontSize: 14,
                          color: subtitleColor,
                          height: 1.0,
                        ),
                      ),
                    ],
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
