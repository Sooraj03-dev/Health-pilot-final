import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/services/auth_service.dart';

// ─── AuthState ──────────────────────────────────────────────────────────────────

/// Immutable state object consumed by the UI layer.
class AuthState {
  final User? user;
  final String? role;
  final bool isVerified;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.role,
    this.isVerified = false,
    this.isLoading = false,
    this.error,
  });

  /// Convenience getter – `true` when a user session exists.
  bool get isAuthenticated => user != null;

  /// Returns a copy with the specified fields replaced.
  AuthState copyWith({
    User? user,
    String? role,
    bool? isVerified,
    bool? isLoading,
    String? error,
    // Flags to explicitly set nullable fields to null.
    bool clearUser = false,
    bool clearRole = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      role: clearRole ? null : (role ?? this.role),
      isVerified: isVerified ?? this.isVerified,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  String toString() =>
      'AuthState(user: ${user?.id}, role: $role, isVerified: $isVerified, '
      'isLoading: $isLoading, error: $error)';
}

// ─── AuthNotifier ───────────────────────────────────────────────────────────────

/// Manages authentication state for the entire app.
///
/// All public methods catch errors from [AuthService] and surface them
/// via `state.error` instead of throwing — the UI never needs try/catch.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(const AuthState()) {
    // Hydrate state if the user is already logged in (e.g. app restart).
    _restoreSession();
  }

  // ── Session restore ──────────────────────────────────────────────────────────

  /// Called once at construction to pick up an existing Supabase session.
  Future<void> _restoreSession() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final profile = await _fetchProfile(currentUser.id);

      state = state.copyWith(
        user: currentUser,
        role: profile['role'] as String?,
        isVerified: profile['is_verified'] as bool? ?? false,
        isLoading: false,
      );
    } catch (e) {
      // Non-fatal – user is authenticated but profile fetch failed.
      state = state.copyWith(
        user: currentUser,
        isLoading: false,
        error: 'Could not load profile: $e',
      );
    }
  }

  // ── Sign In ──────────────────────────────────────────────────────────────────

  /// Authenticates with email & password, then fetches profile data.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Sign-in succeeded but no user was returned.',
        );
        return;
      }

      // Fetch role & verification status from profiles table.
      final profile = await _fetchProfile(user.id);

      state = state.copyWith(
        user: user,
        role: profile['role'] as String?,
        isVerified: profile['is_verified'] as bool? ?? false,
        isLoading: false,
      );
    } on AuthSignInException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unexpected sign-in error: $e',
      );
    }
  }

  // ── Sign Up ──────────────────────────────────────────────────────────────────

  /// Creates a new account and profile row, then updates state.
  Future<void> signUp({
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        role: role,
      );

      final user = response.user;

      // After sign-up the user may still need email confirmation,
      // so `user` could technically be null. We still update state
      // optimistically with the role that was requested.
      state = state.copyWith(
        user: user,
        role: role,
        isVerified: false,
        isLoading: false,
      );
    } on AuthSignUpException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } on ProfileInsertException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unexpected sign-up error: $e',
      );
    }
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────────

  /// Signs the user out and resets state to its initial value.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authService.signOut();

      // Reset to a clean, unauthenticated state.
      state = const AuthState();
    } on AuthSignOutException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unexpected sign-out error: $e',
      );
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Clears the current error (e.g. after the user dismisses a snackbar).
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Fetches a single profile row from the `profiles` table.
  Future<Map<String, dynamic>> _fetchProfile(String userId) async {
    final response = await supabase
        .from('profiles')
        .select('role, is_verified')
        .eq('user_id', userId)
        .single();

    return response;
  }
}

// ─── Global Provider ────────────────────────────────────────────────────────────

/// Top-level provider the whole widget tree can watch / read.
///
/// ```dart
/// // In a widget:
/// final authState = ref.watch(authProvider);
/// final authNotifier = ref.read(authProvider.notifier);
/// ```
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
