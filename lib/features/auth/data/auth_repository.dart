import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final GoTrueClient _auth = Supabase.instance.client.auth;

  User? get currentUser => _auth.currentUser;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
    String? emailRedirectTo,
  }) async {
    return await _auth.signUp(
      email: email,
      password: password,
      data: data,
      emailRedirectTo: emailRedirectTo,
    );
  }

  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    return await _auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
  }

  Future<void> resendEmailOtp({
    required String email,
  }) async {
    await _auth.resend(
      email: email,
      type: OtpType.signup,
    );
  }

  Future<bool> signInWithGithub() async {
    return await _auth.signInWithOAuth(
      OAuthProvider.github,
      redirectTo: 'epilog://login-callback/',
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
