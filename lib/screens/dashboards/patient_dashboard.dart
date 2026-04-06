import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pilot/core/constants.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/services/auth_service.dart';
import 'package:health_pilot/services/watch_service.dart';
import 'package:health_pilot/services/sos_service.dart';
import 'package:health_pilot/screens/vitals/vitals_screen.dart';
import 'package:health_pilot/widgets/sos_button.dart';

class PatientDashboard extends ConsumerStatefulWidget {
  const PatientDashboard({super.key});

  @override
  ConsumerState<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends ConsumerState<PatientDashboard> {
  final WatchService _watchService = WatchService();
  final SosService _sosService = SosService();

  @override
  void initState() {
    super.initState();
    debugPrint('[PatientDashboard] initState — screen loaded');
    _watchService.startSync();
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
              const VitalsScreen(),

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
                Text(
                  'Last synced 2 min ago',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Notification bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 26),
                onPressed: () {},
              ),
              Positioned(
                right: 10,
                top: 10,
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
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _quickActionCard(Icons.chat_outlined, 'Chat'),
          const SizedBox(width: 12),
          _quickActionCard(Icons.description_outlined, 'Records'),
          const SizedBox(width: 12),
          _quickActionCard(Icons.smart_toy_outlined, 'AI Pilot'),
        ],
      ),
    );
  }

  Widget _quickActionCard(IconData icon, String label) {
    return Expanded(
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
