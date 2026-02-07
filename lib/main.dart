import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clerk_flutter/clerk_flutter.dart';
import 'core/services/convex_service.dart';

import 'features/auth/data/auth_repository.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'app/app.dart';
import 'app/presentation/splash_screen.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve the splash screen until we're ready to show our custom splash
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Fix for CERTIFICATE_VERIFY_FAILED: application verification failure
  HttpOverrides.global = MyHttpOverrides();

  // Initialize Convex (without token initially, will be set after Clerk auth)
  await ConvexService.instance.initialize();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );

  // Remove native splash and show our app with custom splash
  FlutterNativeSplash.remove();

  runApp(
    ProviderScope(
      child: DramaTrackerAppWithSplash(),
    ),
  );
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

/// Wrapper that shows splash screen during initial app setup
class DramaTrackerAppWithSplash extends StatefulWidget {
  const DramaTrackerAppWithSplash({super.key});

  @override
  State<DramaTrackerAppWithSplash> createState() => _DramaTrackerAppWithSplashState();
}

class _DramaTrackerAppWithSplashState extends State<DramaTrackerAppWithSplash> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Show splash for minimum duration to display Lottie animation
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // Show splash screen during initialization
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      );
    }

    // Wrap with ClerkAuth if using Convex Auth
    // Wrap with ClerkAuth
    return ClerkAuth(
      config: ClerkAuthConfig(
        publishableKey: dotenv.env['CLERK_PUBLISHABLE_KEY']!,
      ),
      child: _ConvexTokenSync(
        child: const DramaTrackerApp(),
      ),
    );
  }
}

/// Widget that syncs Clerk auth tokens to Convex
class _ConvexTokenSync extends StatefulWidget {
  const _ConvexTokenSync({required this.child});

  final Widget child;

  @override
  State<_ConvexTokenSync> createState() => _ConvexTokenSyncState();
}

class _ConvexTokenSyncState extends State<_ConvexTokenSync> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncToken();
  }

  Future<void> _syncToken() async {
    try {
      final authState = ClerkAuth.of(context, listen: true);

      // Inject ClerkAuthState into repository for use outside widget tree
      ClerkAuthRepositoryImpl.setAuthState(authState);

      if (authState.isSignedIn) {
        // Get Convex-specific JWT token
        final sessionToken = await authState.sessionToken(templateName: 'convex');
        ConvexService.instance.setAuthToken(sessionToken.jwt);
      } else {
        ConvexService.instance.clearAuthToken();
      }
    } catch (e) {
      debugPrint('⚠️ Error syncing Convex token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
