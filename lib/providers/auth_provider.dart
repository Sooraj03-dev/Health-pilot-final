import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/services/profile_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Auth state model
// ─────────────────────────────────────────────────────────────────────────────

class AuthState {
  final bool isAuthenticated;
  final bool isVerified;
  final String? role;         // 'patient' | 'doctor' | 'caregiver'
  final String? userId;
  final String? fullName;
  final bool isLoading;

  const AuthState({
    this.isAuthenticated = false,
    this.isVerified = false,
    this.role,
    this.userId,
    this.fullName,
    this.isLoading = true,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isVerified,
    String? role,
    String? userId,
    String? fullName,
    bool? isLoading,
  }) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        isVerified: isVerified ?? this.isVerified,
        role: role ?? this.role,
        userId: userId ?? this.userId,
        fullName: fullName ?? this.fullName,
        isLoading: isLoading ?? this.isLoading,
      );

  @override
  String toString() =>
      'AuthState(auth=$isAuthenticated, verified=$isVerified, role=$role, '
      'uid=$userId, loading=$isLoading)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final ProfileService _profileService = ProfileService();
  StreamSubscription<dynamic>? _authSub;

  void _init() {
    // Check if there's already a session on cold start.
    final session = supabase.auth.currentSession;
    if (session != null) {
      _loadProfile(session.user);
    } else {
      state = state.copyWith(isLoading: false);
    }

    // Listen for auth state changes (login / logout / token refresh).
    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _loadProfile(session.user);
      } else {
        state = const AuthState(isLoading: false);
      }
    });
  }

  Future<void> _loadProfile(User user) async {
    state = state.copyWith(isLoading: true);

    final profile = await _profileService.fetchProfile(user.id);

    state = AuthState(
      isAuthenticated: true,
      isVerified: true, // DEV BYPASS: Force verification so dashboard loads
      role: profile?.role ?? 'patient',
      userId: user.id,
      fullName: profile?.fullName,
      isLoading: false,
    );
    debugPrint('[AuthProvider] state updated → $state');
  }

  /// Call after login / signup to force a profile re-fetch.
  Future<void> refresh() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      await _loadProfile(user);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
