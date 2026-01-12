import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import '../core/router/app_router.dart';

class DramaTrackerApp extends ConsumerStatefulWidget {
  const DramaTrackerApp({super.key});

  @override
  ConsumerState<DramaTrackerApp> createState() => _DramaTrackerAppState();
}

class _DramaTrackerAppState extends ConsumerState<DramaTrackerApp> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        final session = data.session;
        if (session != null) {
          final metadata = session.user.userMetadata;
          final hasSetUsername =
              metadata?['has_set_username'] as bool? ?? false;

          if (hasSetUsername) {
            ref.read(appRouterProvider).go('/home');
          } else {
            ref.read(appRouterProvider).go('/setup-profile');
          }
        } else {
          ref.read(appRouterProvider).go('/home');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.watch(appRouterProvider);

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Drama Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
