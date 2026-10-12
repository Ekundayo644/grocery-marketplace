import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    // React to login/logout/token-refresh events from Supabase.
    _authSub = AuthService.instance.authStateChanges.listen((state) async {
      _session = state.session;
      _user = state.session?.user;

      if (_user != null) {
        // ✅ Fetch the profile whenever the auth state changes to a signed-in state
        await loadProfile();
      } else {
        _profile = null;
        notifyListeners();
      }
    });

    // Seed initial state from any persisted session AND load the profile.
    _session = AuthService.instance.currentUser != null
        ? Supabase.instance.client.auth.currentSession
        : null;
    _user = AuthService.instance.currentUser;

    // ✅ If a session was restored on app launch, load the profile immediately
    if (_user != null) {
      loadProfile();
    }
  }

  late final dynamic _authSub;
  Session? _session;
  User? _user;
  Map<String, dynamic>? _profile;

  bool get isLoggedIn => _user != null;
  User? get user => _user;
  Session? get session => _session;
  Map<String, dynamic>? get profile => _profile;

  Future<void> loadProfile() async {
    try {
      _profile = await AuthService.instance.getCurrentProfile();
    } catch (e) {
      _profile = null;
      debugPrint('loadProfile failed: $e');
    }
    notifyListeners();
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await AuthService.instance.signIn(email: email, password: password);
      await loadProfile();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    try {
      await AuthService.instance.signUp(
        email: email,
        password: password,
        username: username,
        fullName: fullName,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await AuthService.instance.signOut();
    _profile = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}