import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:health_pilot/core/supabase_client.dart';

/// Handles Supabase Auth operations — sign in, sign up, sign out.
class AuthService {
  // ── Sign In ───────────────────────────────────────────────────────────────
  /// Returns the [AuthResponse] on success or throws.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    debugPrint('[AuthService] signIn → user: ${response.user?.id}');
    return response;
  }

  // ── Sign Up ───────────────────────────────────────────────────────────────
  /// Creates an auth user. The DB trigger on auth.users should auto-create
  /// the `profiles` row with the supplied role.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String role = 'patient',
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
      },
    );
    debugPrint('[AuthService] signUp → user: ${response.user?.id}');
    return response;
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await supabase.auth.signOut();
    debugPrint('[AuthService] signed out');
  }
}