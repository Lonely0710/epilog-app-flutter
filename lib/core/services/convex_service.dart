import 'package:convex_flutter/convex_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConvexService {
  static final instance = ConvexService._();

  ConvexService._();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final deploymentUrl = dotenv.env['CONVEX_URL'];

    if (deploymentUrl == null || deploymentUrl.isEmpty) {
      debugPrint('⚠️ Convex URL not set. Please check your .env file.');
      return;
    }

    try {
      await ConvexClient.initialize(
        ConvexConfig(
          deploymentUrl: deploymentUrl,
          clientId: 'drama-tracker-flutter-1.0',
        ),
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Failed to initialize Convex: $e');
    }
  }

  /// Set the auth token for Convex (from Clerk JWT)
  void setAuthToken(String token) {
    if (!_isInitialized) {
      debugPrint('⚠️ ConvexService not initialized, cannot set auth token');
      return;
    }

    try {
      ConvexClient.instance.setAuth(token: token);
    } catch (e) {
      debugPrint('❌ Failed to set Convex auth token: $e');
    }
  }

  /// Clear the auth token (on sign out)
  void clearAuthToken() {
    if (!_isInitialized) return;

    try {
      ConvexClient.instance.setAuth(token: null);
    } catch (e) {
      debugPrint('❌ Failed to clear Convex auth token: $e');
    }
  }

  ConvexClient get client {
    if (!_isInitialized) {
      throw Exception('ConvexService not initialized. Call initialize() first.');
    }
    return ConvexClient.instance;
  }
}
