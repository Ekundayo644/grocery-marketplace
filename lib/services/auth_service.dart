import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase Auth calls so the rest of the app
/// doesn't touch the SDK directly.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Currently signed-in user, or null.
  User? get currentUser => _client.auth.currentUser;

  /// Stream of auth changes (login, logout, token refresh).
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign up with email, password, plus extra metadata
  /// (username, full_name) stored in raw_user_meta_data.
  /// A DB trigger auto-creates a matching row in `profiles`.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    return await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'username': username.trim(),
        'full_name': fullName?.trim() ?? '',
      },
    );
  }

  /// Sign in with email + password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign out and clear session.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Fetch the current user's profile row from `profiles`.
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return data;
  }

  /// Fetch the current user's vendor row, if they are a vendor.
  Future<Map<String, dynamic>?> getCurrentVendor() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from('vendors')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    return data;
  }
}