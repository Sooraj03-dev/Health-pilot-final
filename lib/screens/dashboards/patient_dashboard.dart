import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_pilot/core/constants.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/providers/health_provider.dart';
import 'package:health_pilot/services/auth_service.dart';
import 'package:health_pilot/services/watch_service.dart';
import 'package:health_pilot/services/sos_service.dart';
import 'package:health_pilot/widgets/sos_button.dart';
import 'package:health_pilot/widgets/vitals_card.dart';
import 'package:health_pilot/widgets/sleep_card.dart';

class PatientDashboard extends ConsumerStatefulWidget {
  const PatientDashboard({super.key});

  @override
  ConsumerState<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends ConsumerState<PatientDashboard> {
  final WatchService _watchService = WatchService();
  final SosService _sosService = SosService();

  /// Tracks when the last sync occurred to show a human-readable timestamp.
  DateTime? _lastSyncedAt;

  @override
  void initState() {
    super.initState();
    debugPrint('[PatientDashboard] initState — screen loaded');
    // Defer to post-frame so context is fully available
    WidgetsBinding.instance.addPostFrameCallback((_) => _initWatchService());
  }

  /// Requests Health Connect permissions if needed, then starts the sync timer.
  /// requestPermissions() is safe to call when permissions are already granted
  /// — it returns true immediately without showing a dialog.
  Future<void> _initWatchService() async {
    debugPrint('[PatientDashboard] Requesting Health Connect permissions...');
    await _watchService.requestPermissions();
    // Always start sync regardless of the returned flag, because
    // hasPermissions() on Android HC is unreliable. _syncData() will
    // gracefully catch any actual permission exceptions.
    _watchService.startSync();
    debugPrint('[PatientDashboard] WatchService sync started.');
  }

  @override
  void dispose() {
    _watchService.stopSync();
    super.dispose();
  }

  Future<bool> _handleSosTrigger() async {
    final result = await _sosService.triggerSOS();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result
              ? 'SOS Alert Sent! Help is on the way.'
              : 'Failed to send SOS. Check permissions.'),
          backgroundColor: result ? Colors.green : Colors.red,
        ),
      );
    }
    return result;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String get _userInitials {
    final name = supabase.auth.currentUser?.userMetadata?['full_name'] as String?;
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  String get _userName {
    return (supabase.auth.currentUser?.userMetadata?['full_name'] as String?) ??
        'Patient';
  }

  /// Returns a human-readable "last synced" label:
  /// - null         → "Not synced yet"
  /// - < 60 seconds → "Just now"
  /// - else         → "X min ago"
  String _syncLabel(DateTime? ts) {
    if (ts == null) return 'Not synced yet';
    final diff = DateTime.now().difference(ts);
    if (diff.inSeconds < 60) return 'Just now';
    return '${diff.inMinutes} min ago';
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ═══════════════════════════════════════════════════════════
              // ── GRADIENT HEADER ────────────────────────────────────────
              // ═══════════════════════════════════════════════════════════
              _buildHeader(),

              const SizedBox(height: 24),

              // ═══════════════════════════════════════════════════════════
              // ── LIVE VITALS ────────────────────────────────────────────
              // ═══════════════════════════════════════════════════════════
              _buildVitalsSection(),

              const SizedBox(height: 32),

              // ═══════════════════════════════════════════════════════════
              // ── SOS SECTION ────────────────────────────────────────────
              // ═══════════════════════════════════════════════════════════
              Center(
                child: SosButton(onTriggered: _handleSosTrigger),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Long press for emergency assistance',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ═══════════════════════════════════════════════════════════
              // ── QUICK ACTIONS ──────────────────────────────────────────
              // ═══════════════════════════════════════════════════════════
              _buildQuickActions(),

              const SizedBox(height: 24),

              // ═══════════════════════════════════════════════════════════
              // ── APPOINTMENT CARD ───────────────────────────────────────
              // ═══════════════════════════════════════════════════════════
              _buildAppointmentCard(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Extracted Widgets
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A7A5E), Color(0xFF2E9B7F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _userInitials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Consumer(
                  builder: (context, ref, _) {
                    final metricsAsync = ref.watch(healthMetricsProvider);
                    final ts = metricsAsync.valueOrNull?.recordedAt;
                    // Update local state when a new metric arrives
                    if (ts != null && ts != _lastSyncedAt) {
                      // Schedule after build
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _lastSyncedAt = ts);
                      });
                    }
                    return Text(
                      'Last synced: ${_syncLabel(_lastSyncedAt)}',
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 13,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Notification bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 24),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 22),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
    );
  }

  // ── Live Vitals Section ──────────────────────────────────────────────────

  Widget _buildVitalsSection() {
    return Consumer(
      builder: (context, ref, _) {
        final metricsAsync = ref.watch(healthMetricsProvider);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LIVE VITALS',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              metricsAsync.when(
                loading: () => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: VitalsCard(
                            label: 'HEART RATE BPM',
                            numericValue: null,
                            unit: '',
                            borderColor: Colors.red.shade400,
                            iconData: Icons.favorite,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: VitalsCard(
                            label: 'SPO2 LEVEL',
                            numericValue: null,
                            unit: '%',
                            borderColor: Colors.blue.shade600,
                            iconData: Icons.water_drop,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const SleepCard(sleepLabel: '--'),
                  ],
                ),
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Unable to load vitals. Check your connection.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (metric) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: VitalsCard(
                              label: 'HEART RATE BPM',
                              numericValue: metric?.heartRate,
                              unit: '',
                              borderColor: Colors.red.shade400,
                              iconData: Icons.favorite,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: VitalsCard(
                              label: 'SPO2 LEVEL',
                              numericValue: metric?.spo2,
                              unit: '%',
                              borderColor: Colors.blue.shade600,
                              iconData: Icons.water_drop,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SleepCard(
                        sleepLabel: metric?.formattedSleep ?? '--',
                        quality: metric?.sleepQuality,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _quickActionCard(Icons.chat_outlined, 'Chat', '/patient-chat'),
          const SizedBox(width: 12),
          _quickActionCard(Icons.description_outlined, 'Records', '/records'),
          const SizedBox(width: 12),
          _quickActionCard(Icons.smart_toy_outlined, 'AI Pilot', '/ai-pilot'),
        ],
      ),
    );
  }

  Widget _quickActionCard(IconData icon, String label, String? route) {
    return Expanded(
      child: GestureDetector(
        onTap: route != null ? () => context.push(route) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primaryDark, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: const Border(
            left: BorderSide(color: AppColors.primaryDark, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryDark.withAlpha(30),
              child: const Icon(Icons.person, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dr. Sarah Chen',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary)),
                  SizedBox(height: 2),
                  Text('Neurology Clinic',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('09:30 AM',
                    style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                SizedBox(height: 2),
                Text('Tomorrow',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
