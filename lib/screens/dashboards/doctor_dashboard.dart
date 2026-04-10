import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:health_pilot/core/constants.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:go_router/go_router.dart';
import 'package:health_pilot/services/auth_service.dart';
import 'package:health_pilot/screens/chat/doctor_inbox_screen.dart';
import 'package:health_pilot/screens/chat/chat_room_screen.dart';
import 'package:health_pilot/models/sos_alert.dart';
import 'package:url_launcher/url_launcher.dart';

// ---------------------------------------------------------------------------
// Data Models
// ---------------------------------------------------------------------------

class _PatientInfo {
  final String userId;
  final String name;
  final String specialty;

  const _PatientInfo({
    required this.userId,
    required this.name,
    this.specialty = 'General',
  });
}

class _PatientVitals {
  final double? heartRate;
  final double? spo2;
  final DateTime? recordedAt;

  const _PatientVitals({this.heartRate, this.spo2, this.recordedAt});
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Fetches the list of patients assigned to the current doctor.
final assignedPatientsProvider = FutureProvider<List<_PatientInfo>>((ref) async {
  final doctorId = supabase.auth.currentUser?.id;
  if (doctorId == null) return [];
  try {
    debugPrint('[DoctorDashboard] Fetching assigned patients for doctorId: $doctorId');
    // 1. Fetch assigned patient IDs
    final rows = await supabase
        .from('assigned_patients')
        .select('patient_id')
        .eq('doctor_id', doctorId);

    debugPrint('[DoctorDashboard] Fetch assigned_patients result: $rows');

    if (rows.isEmpty) return [];

    final patientIds = (rows as List<dynamic>).map((r) => r['patient_id'] as String).toList();

    // 2. Fetch profiles for these patient IDs
    final profilesReq = await supabase
        .from('profiles')
        .select('user_id, full_name, role')
        .inFilter('user_id', patientIds);

    final profiles = {
      for (var p in profilesReq) p['user_id'] as String: p
    };

    return patientIds.map((pid) {
      final profile = profiles[pid];
      return _PatientInfo(
        userId: pid,
        name: (profile?['full_name'] as String?) ?? 'Unknown Patient',
        specialty: (profile?['role'] as String?) ?? 'Patient',
      );
    }).toList();
  } catch (e, st) {
    debugPrint('[DoctorDashboard] assignedPatientsProvider error: $e\n$st');
    throw Exception('Failed to load patients: $e'); // Make it show up on screen
  }
});

/// Streams the latest vitals for a specific patient from health_metrics.
final patientVitalsProvider =
    StreamProvider.family<_PatientVitals, String>((ref, patientId) {
  return Supabase.instance.client
      .from('health_metrics')
      .stream(primaryKey: ['id'])
      .eq('user_id', patientId)
      .order('recorded_at', ascending: false)
      .limit(1)
      .map((data) {
        if (data.isEmpty) return const _PatientVitals();
        final row = data.first;
        return _PatientVitals(
          heartRate: (row['heart_rate'] as num?)?.toDouble(),
          spo2: (row['spo2'] as num?)?.toDouble(),
          recordedAt: row['recorded_at'] != null
              ? DateTime.parse(row['recorded_at'] as String)
              : null,
        );
      });
});

// ---------------------------------------------------------------------------
// SOS Alerts Provider — streams new sos_alerts rows in real-time
// ---------------------------------------------------------------------------

final sosAlertsProvider = StreamProvider<List<SosAlert>>((ref) {
  return supabase
      .from('sos_alerts')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((data) => data.map((e) => SosAlert.fromJson(e)).toList());
});

// ---------------------------------------------------------------------------
// Doctor Dashboard
// ---------------------------------------------------------------------------

class DoctorDashboard extends ConsumerStatefulWidget {
  const DoctorDashboard({super.key});

  @override
  ConsumerState<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends ConsumerState<DoctorDashboard> {
  int _currentIndex = 0;
  String? _lastSeenSosId; // Track last seen alert to avoid duplicate dialogs

  void _onSosAlerts(List<SosAlert> alerts) {
    if (alerts.isEmpty) return;
    final latest = alerts.first;
    if (latest.id == null || latest.id == _lastSeenSosId) return;
    // Only show if the alert is recent (within last 2 minutes)
    final age = DateTime.now().toUtc().difference(latest.createdAt);
    if (age.inMinutes > 2) return;

    _lastSeenSosId = latest.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showSosDialog(latest);
    });
  }

  void _showSosDialog(SosAlert alert) {
    // Google Maps native deep link — opens app directly on Android
    final nativeMapsUrl = 'geo:${alert.lat},${alert.lng}?q=${alert.lat},${alert.lng}(SOS+Patient+Location)';
    final webMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${alert.lat},${alert.lng}';

    Future<void> openMap() async {
      // Try native Google Maps first
      final nativeUri = Uri.parse(nativeMapsUrl);
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to Google Maps on the web
        final webUri = Uri.parse(webMapsUrl);
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.emergency, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '🚨 SOS Alert!',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A patient has triggered an emergency SOS alert.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text('Patient Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lat: ${alert.lat.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  Text(
                    'Lng: ${alert.lng.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Time: ${TimeOfDay.fromDateTime(alert.createdAt.toLocal()).format(context)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dismiss', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.map, size: 18),
            label: const Text('View on Map'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await openMap();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for realtime SOS alerts
    ref.listen<AsyncValue<List<SosAlert>>>(sosAlertsProvider, (_, next) {
      next.whenData(_onSosAlerts);
    });
    final patientsAsync = ref.watch(assignedPatientsProvider);
    // Watch SOS to keep subscription alive + get count for badge
    final sosAsync = ref.watch(sosAlertsProvider);
    final recentSosCount = sosAsync.valueOrNull?.where((a) {
      return DateTime.now().toUtc().difference(a.createdAt).inMinutes <= 60;
    }).length ?? 0;

    final doctorName = (supabase.auth.currentUser
            ?.userMetadata?['full_name'] as String?) ??
        'Doctor';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0: Home view
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, doctorName, patientsAsync, recentSosCount),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: patientsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => _ErrorCard(message: e.toString()),
                      data: (patients) => _buildBody(context, ref, patients),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 1: Vitals (Placeholder)
          const Center(child: Text('Vitals Screen')),
          // 2: Chat
          const DoctorInboxScreen(),
          // 3: Profile (Placeholder)
          const Center(child: Text('Profile Screen')),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody(
      BuildContext context, WidgetRef ref, List<_PatientInfo> patients) {
    // Find patients with critical vitals for SOS banner
    final criticalPatients = <_PatientInfo>[];
    // We'll collect them as streams resolve in the patient cards

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Summary
        _AiSummaryCard(patientCount: patients.length),
        const SizedBox(height: 16),

        // Stats Row
        _StatsRow(patientCount: patients.length),
        const SizedBox(height: 20),

        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Monitoring',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (patients.isEmpty)
          const _EmptyPatientsCard()
        else
          ...patients.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PatientCard(patient: p, ref: ref),
              )),

        const SizedBox(height: 16),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, String doctorName,
      AsyncValue<List<_PatientInfo>> patientsAsync, int sosCount) {
    final count = patientsAsync.valueOrNull?.length ?? 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A3A6B),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Doctor Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 10),
          // Name + badge + subtitle — all in one Expanded column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + badge in a Wrap so badge drops below if needed
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      doctorName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withAlpha(80), width: 1),
                      ),
                      child: const Text(
                        'Verified',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Doctor · $count patient${count != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          // SOS notification bell with red badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                onPressed: () {
                  // Show SOS panel when tapped
                  final alerts = ref.read(sosAlertsProvider).valueOrNull ?? [];
                  final recent = alerts.where((a) =>
                    DateTime.now().toUtc().difference(a.createdAt).inMinutes <= 60
                  ).toList();
                  if (recent.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No recent SOS alerts'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    _showSosDialog(recent.first);
                  }
                },
              ),
              if (sosCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        sosCount > 9 ? '9+' : '$sosCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        if (index == 3) {
          context.push('/profile-doctor');
        } else {
          setState(() => _currentIndex = index);
        }
      },
      selectedItemColor: AppColors.primaryDark,
      unselectedItemColor: AppColors.textSecondary,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart_outlined), label: 'Vitals'),
        BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined), label: 'Chat'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Patient Card — streams real vitals
// ---------------------------------------------------------------------------

class _PatientCard extends ConsumerWidget {
  final _PatientInfo patient;
  final WidgetRef ref;
  const _PatientCard({required this.patient, required this.ref, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vitalsAsync = ref.watch(patientVitalsProvider(patient.userId));

    return vitalsAsync.when(
      loading: () => _buildCard(context, patient, const _PatientVitals(),
          isLoading: true),
      error: (e, _) =>
          _buildCard(context, patient, const _PatientVitals()),
      data: (vitals) => _buildCard(context, patient, vitals),
    );
  }

  Widget _buildCard(
      BuildContext context, _PatientInfo patient, _PatientVitals vitals,
      {bool isLoading = false}) {
    final hr = vitals.heartRate;
    final spo2 = vitals.spo2;
    final isCriticalHr = hr != null && (hr < 50 || hr > 110);
    final hrColor =
        isLoading ? Colors.grey : (isCriticalHr ? AppColors.critical : AppColors.normal);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCriticalHr
            ? Border.all(color: AppColors.critical.withAlpha(80), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: avatar + name + HR
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person,
                        color: AppColors.primaryDark, size: 26),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isCriticalHr
                            ? AppColors.critical
                            : AppColors.normal,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      patient.specialty,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // Live HR reading
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          hr != null ? '${hr.toInt()} BPM' : '-- BPM',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: hrColor,
                          ),
                        ),
                  const Text(
                    'HEART RATE',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Vitals chips
          Row(
            children: [
              _VitalChip(
                  label: 'SPO2',
                  value: spo2 != null ? '${spo2.toInt()}%' : '--%'),
              const SizedBox(width: 10),
              _VitalChip(
                  label: 'LAST SYNC',
                  value: vitals.recordedAt != null
                      ? _syncLabel(vitals.recordedAt!)
                      : '--'),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => context.push('/patient-records/${patient.userId}'),
                  icon: const Icon(Icons.folder_shared_outlined, size: 16, color: AppColors.primaryDark),
                  label: const Text('Records', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600, fontSize: 13)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: AppColors.primaryDark.withAlpha(15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(
                          patientId: patient.userId,
                          patientName: patient.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.primaryDark),
                  label: const Text('Chat', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600, fontSize: 13)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: AppColors.primaryDark.withAlpha(15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _syncLabel(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ---------------------------------------------------------------------------
// Supporting widgets
// ---------------------------------------------------------------------------

class _AiSummaryCard extends StatelessWidget {
  final int patientCount;
  const _AiSummaryCard({required this.patientCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
            left: BorderSide(color: AppColors.primaryDark, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.smart_toy_outlined,
                  color: AppColors.primaryDark, size: 18),
              SizedBox(width: 6),
              Text(
                'AI SUMMARY',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Monitoring $patientCount active patient${patientCount != 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vitals are streaming live from patient wearables via Health Connect.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int patientCount;
  const _StatsRow({required this.patientCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
            label: 'PATIENTS',
            value: '$patientCount',
            icon: Icons.people_outline,
            color: AppColors.primaryDark),
        const SizedBox(width: 12),
        _StatCard(
            label: 'ALERTS',
            value: '0',
            icon: Icons.warning_amber_outlined,
            color: AppColors.critical),
        const SizedBox(width: 12),
        _StatCard(
            label: 'MESSAGES',
            value: '0',
            icon: Icons.chat_bubble_outline,
            color: AppColors.primaryDark),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 4),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalChip extends StatelessWidget {
  final String label;
  final String value;
  const _VitalChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7FB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _EmptyPatientsCard extends StatelessWidget {
  const _EmptyPatientsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.people_outline, size: 48, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text('No patients assigned yet',
              style: TextStyle(
                  color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Patients will appear here once assigned via Supabase.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.critical.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.critical.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.critical),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: const TextStyle(color: AppColors.critical))),
        ],
      ),
    );
  }
}
