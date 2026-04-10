<<<<<<< HEAD
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:health_pilot/core/supabase_client.dart';

/// Handles Supabase Auth operations — sign in, sign up, sign out.
class AuthService {
  // ── Sign In ───────────────────────────────────────────────────────────────
  /// Returns the [AuthResponse] on success or throws.
=======
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:health_pilot/core/supabase_client.dart';

// ─── Typed Exceptions ──────────────────────────────────────────────────────────

/// Thrown when sign-up fails (duplicate email, weak password, etc.).
class AuthSignUpException implements Exception {
  final String message;
  const AuthSignUpException(this.message);

  @override
  String toString() => 'AuthSignUpException: $message';
}

/// Thrown when sign-in fails (wrong credentials, unverified email, etc.).
class AuthSignInException implements Exception {
  final String message;
  const AuthSignInException(this.message);

  @override
  String toString() => 'AuthSignInException: $message';
}

/// Thrown when sign-out fails.
class AuthSignOutException implements Exception {
  final String message;
  const AuthSignOutException(this.message);

  @override
  String toString() => 'AuthSignOutException: $message';
}

/// Thrown when inserting the user profile row fails.
class ProfileInsertException implements Exception {
  final String message;
  const ProfileInsertException(this.message);

  @override
  String toString() => 'ProfileInsertException: $message';
}

// ─── AuthService (Singleton) ────────────────────────────────────────────────────

/// Singleton service that wraps Supabase Auth and the `profiles` table.
///
/// Usage:
/// ```dart
/// final auth = AuthService();
/// await auth.signUp(email: 'a@b.com', password: 's3cret', role: 'patient');
/// ```
class AuthService {
  // Private constructor
  AuthService._internal();

  /// The single shared instance.
  static final AuthService _instance = AuthService._internal();

  /// Factory constructor always returns the same instance.
  factory AuthService() => _instance;

  // ── Getters ──────────────────────────────────────────────────────────────────

  /// Returns the currently authenticated [User], or `null` if signed out.
  User? get currentUser => supabase.auth.currentUser;

  // ── Sign Up ──────────────────────────────────────────────────────────────────

  /// Creates a new account and inserts a row into `profiles`.
  ///
  /// [role] should be one of `'patient'`, `'doctor'`, or `'admin'`.
  ///
  /// Throws [AuthSignUpException] if the Supabase auth call fails.
  /// Throws [ProfileInsertException] if the profile row cannot be created.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String role,
  }) async {
    late final AuthResponse response;

    // 1. Create the auth user.
    try {
      response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthSignUpException(e.message);
    } catch (e) {
      throw AuthSignUpException('Unexpected error during sign-up: $e');
    }

    final userId = response.user?.id;
    if (userId == null) {
      throw AuthSignUpException(
        'Sign-up succeeded but no user ID was returned. '
        'The email may require confirmation.',
      );
    }

    // 2. Insert the profile row.
    try {
      await supabase.from('profiles').insert({
        'user_id': userId,
        'role': role,
        'is_verified': false,
      });
    } on PostgrestException catch (e) {
      throw ProfileInsertException(
        'Failed to create profile: ${e.message}',
      );
    } catch (e) {
      throw ProfileInsertException(
        'Unexpected error creating profile: $e',
      );
    }

    return response;
  }

  // ── Sign In ──────────────────────────────────────────────────────────────────

  /// Authenticates an existing user with email & password.
  ///
  /// Returns [AuthResponse] on success.
  /// Throws [AuthSignInException] on failure.
>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
<<<<<<< HEAD
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
=======
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw AuthSignInException(e.message);
    } catch (e) {
      throw AuthSignInException('Unexpected error during sign-in: $e');
    }
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────────

  /// Signs the current user out.
  ///
  /// Throws [AuthSignOutException] on failure.
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (e) {
      throw AuthSignOutException(e.message);
    } catch (e) {
      throw AuthSignOutException('Unexpected error during sign-out: $e');
    }
  }
}
>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42
