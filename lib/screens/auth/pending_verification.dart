import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pilot/core/constants.dart';
import 'package:health_pilot/services/auth_service.dart';

class PendingVerificationPage extends ConsumerWidget {
  const PendingVerificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
=======

/// Shown when a user has signed up but their profile is not yet verified.
class PendingVerificationPage extends StatelessWidget {
  const PendingVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
<<<<<<< HEAD
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_top_rounded,
                      color: AppColors.primaryDark, size: 40),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Awaiting Verification',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your account is being reviewed by an administrator. '
                  'You will be notified once your profile is verified.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),
                OutlinedButton.icon(
                  onPressed: () async {
                    await AuthService().signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: AppColors.primaryDark),
                    foregroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
=======
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mark_email_unread_rounded,
                  size: 80,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Verification Pending',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your account is awaiting verification.\n'
                  'Please check your email or contact an administrator.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
