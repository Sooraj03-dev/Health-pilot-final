import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
<<<<<<< HEAD
import 'package:health_pilot/core/constants.dart';
import 'package:health_pilot/providers/auth_provider.dart';
import 'package:health_pilot/services/auth_service.dart';

=======

import 'package:health_pilot/providers/auth_provider.dart';

/// Email regex — permissive; server-side validation is the source of truth.
final _emailRegex = RegExp(r'^[\w\-.+]+@[\w\-]+\.\w+$');

/// Available roles a new user can register with.
const _roles = <String>['patient', 'doctor'];

/// Sign-up screen for Health Pilot.
///
/// Watches [authProvider] for loading / error states.
/// Post-signup navigation is handled declaratively by the router —
/// this page only calls `signUp` and lets the state change propagate.
>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42
class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
<<<<<<< HEAD
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService = AuthService();
  String _selectedRole = 'patient';
  bool _isLoading = false;
=======
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _selectedRole;
>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42
  bool _obscurePassword = true;

  @override
  void dispose() {
<<<<<<< HEAD
    _nameCtrl.dispose();
=======
>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

<<<<<<< HEAD
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        fullName: _nameCtrl.text.trim(),
        role: _selectedRole,
      );
      await ref.read(authProvider.notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
=======
  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    ref.read(authProvider.notifier).clearError();

    await ref.read(authProvider.notifier).signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: _selectedRole!,
        );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Show a SnackBar whenever a new error lands in state.
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.error!),
              behavior: SnackBarBehavior.floating,
              backgroundColor: colorScheme.error,
              showCloseIcon: true,
              closeIconColor: colorScheme.onError,
            ),
          );
      }
    });

>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
<<<<<<< HEAD
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.person_add,
                        color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 24),
                  const Text('Create Account',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  const Text('Join Health Pilot',
                      style: TextStyle(
                          fontSize: 15, color: AppColors.textSecondary)),
                  const SizedBox(height: 36),

                  // ── Full Name ──────────────────────────────────────────
                  TextFormField(
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),

                  // ── Email ──────────────────────────────────────────────
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Enter valid email' : null,
                  ),
                  const SizedBox(height: 14),

                  // ── Password ───────────────────────────────────────────
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 14),

                  // ── Role selector ──────────────────────────────────────
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'patient', child: Text('Patient')),
                      DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                      DropdownMenuItem(
                          value: 'caregiver', child: Text('Caregiver')),
                    ],
                    onChanged: (v) => setState(() => _selectedRole = v!),
                  ),
                  const SizedBox(height: 28),

                  // ── Sign Up button ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignup,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text('Create Account'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ',
                          style: TextStyle(color: AppColors.textSecondary)),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: const Text('Sign In',
                            style: TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
=======
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ──────────────────────────────────────────────
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create Account',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join Health Pilot today',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // ── Email field ─────────────────────────────────────────
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@example.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!_emailRegex.hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Password field ──────────────────────────────────────
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Role selector ───────────────────────────────────────
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'I am a…',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      items: _roles.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(
                            role[0].toUpperCase() + role.substring(1),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedRole = value),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your role';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // ── Submit button ───────────────────────────────────────
                    FilledButton(
                      onPressed: authState.isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authState.isLoading
                          ? SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text('Create Account'),
                    ),
                    const SizedBox(height: 24),

                    // ── Login redirect ──────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Log In'),
                        ),
                      ],
                    ),
                  ],
                ),
>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42
              ),
            ),
          ),
        ),
      ),
    );
  }
}
