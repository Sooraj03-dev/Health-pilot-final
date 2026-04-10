import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:health_pilot/providers/auth_provider.dart';
import 'package:health_pilot/screens/auth/login_page.dart';
import 'package:health_pilot/screens/auth/signup_page.dart';
import 'package:health_pilot/screens/auth/pending_verification.dart';
import 'package:health_pilot/screens/dashboards/patient_dashboard.dart';
import 'package:health_pilot/screens/dashboards/doctor_dashboard.dart';
<<<<<<< HEAD
import 'package:health_pilot/screens/vitals/sos_screen.dart';
import 'package:health_pilot/screens/ai/ai_assistant_screen.dart';
import 'package:health_pilot/screens/chat/patient_chat_screen.dart';
import 'package:health_pilot/screens/records/records_screen.dart';
import 'package:health_pilot/screens/records/records_viewer.dart';
import 'package:health_pilot/screens/profile/setup_profile_screen.dart';
import 'package:health_pilot/screens/profile/patient_profile_screen.dart';
import 'package:health_pilot/screens/profile/doctor_profile_screen.dart';
import 'package:health_pilot/widgets/app_shell.dart';
import 'package:health_pilot/screens/chat/caregiver_screen.dart';
=======
>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42

/// Application router.
///
/// Uses [authProvider] to redirect users based on authentication state:
/// - Not signed in → `/login`
/// - Signed in but not verified → `/pending-verification`
/// - Signed in & verified → role-specific dashboard
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
<<<<<<< HEAD
      // While auth state is still loading, don't redirect.
      if (authState.isLoading) return null;

=======
>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42
      final isAuthenticated = authState.isAuthenticated;
      final isVerified = authState.isVerified;
      final role = authState.role;
      final currentPath = state.uri.path;

      final isAuthRoute =
          currentPath == '/login' || currentPath == '/signup';

      // Not signed in → force to login (unless already on an auth route).
      if (!isAuthenticated) {
        return isAuthRoute ? null : '/login';
      }

      // Signed in but not verified → pending verification.
      if (!isVerified) {
        return currentPath == '/pending-verification'
            ? null
            : '/pending-verification';
      }

<<<<<<< HEAD
      // Check if essential profile info is missing — this must run BEFORE
      // the dashboard redirect so new sign-ups land on /setup-profile first.
      if (!authState.hasMinimalProfile && currentPath != '/setup-profile') {
        return '/setup-profile';
      }

      // Signed in & profile complete — if still on an auth page, go to dashboard.
      if (isAuthRoute || currentPath == '/pending-verification') {
        if (role == 'caregiver') {
            return '/caregiver-view/00000000-0000-0000-0000-000000000000/Patient';
        }
=======
      // Signed in & verified — if still on an auth page, redirect to dashboard.
      if (isAuthRoute || currentPath == '/pending-verification') {
>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42
        return role == 'doctor' ? '/doctor-dashboard' : '/patient-dashboard';
      }

      // Otherwise, stay on the requested route.
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/pending-verification',
        builder: (context, state) => const PendingVerificationPage(),
      ),
      GoRoute(
        path: '/patient-dashboard',
<<<<<<< HEAD
        builder: (context, state) => AppShell(
          pages: const [
            PatientDashboard(),
            Center(child: Text('Vitals')),
            Center(child: Text('Reports')),
            PatientProfileScreen(),
          ],
        ),
=======
        builder: (context, state) => const PatientDashboard(),
>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42
      ),
      GoRoute(
        path: '/doctor-dashboard',
        builder: (context, state) => const DoctorDashboard(),
      ),
<<<<<<< HEAD
      GoRoute(
        path: '/sos',
        builder: (context, state) => const SosScreen(),
      ),
      GoRoute(
        path: '/ai-pilot',
        builder: (context, state) => const AIAssistantScreen(),
      ),
      GoRoute(
        path: '/patient-chat',
        builder: (context, state) => const PatientChatScreen(),
      ),
      GoRoute(
        path: '/caregiver-view/:patientId/:patientName',
        builder: (context, state) {
          final patientId = state.pathParameters['patientId']!;
          final patientName = state.pathParameters['patientName'] ?? 'Assigned Patient';
          return CaregiverScreen(patientId: patientId, patientName: patientName);
        },
      ),
      GoRoute(
        path: '/setup-profile',
        builder: (context, state) => const SetupProfileScreen(),
      ),
      GoRoute(
        path: '/profile-patient',
        builder: (context, state) => const PatientProfileScreen(),
      ),
      GoRoute(
        path: '/profile-doctor',
        builder: (context, state) => const DoctorProfileScreen(),
      ),
      GoRoute(
        path: '/records',
        builder: (context, state) => const RecordsScreen(),
      ),
      GoRoute(
        path: '/records/viewer/:patientId',
        builder: (context, state) {
          final patientId = state.pathParameters['patientId']!;
          return RecordsViewerScreen(patientId: patientId);
        },
      ),
=======
>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42
    ],
  );
});
