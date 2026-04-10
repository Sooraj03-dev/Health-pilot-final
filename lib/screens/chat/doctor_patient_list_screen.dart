import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_pilot/core/constants.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/models/message.dart';
import 'package:intl/intl.dart';

class PatientChatInfo {
  final String patientId;
  final String patientName;
  final Message? lastMessage;
  final int unreadCount;

  PatientChatInfo({
    required this.patientId,
    required this.patientName,
    this.lastMessage,
    required this.unreadCount,
  });
}

final doctorPatientsChatProvider = FutureProvider<List<PatientChatInfo>>((ref) async {
  final doctorId = supabase.auth.currentUser?.id;
  if (doctorId == null) return [];

  try {
    // 1. Fetch assigned patients
    final assignedRows = await supabase
        .from('assigned_patients')
        .select('patient_id, profiles!patient_id(full_name)')
        .eq('doctor_id', doctorId);

    final List<PatientChatInfo> results = [];

    for (final row in assignedRows as List<dynamic>) {
      final patientId = row['patient_id'] as String;
      final patientName = (row['profiles'] as Map<String, dynamic>?)?['full_name'] ?? 'Unknown Patient';

      // 2. Fetch last message between doctor and this patient
      final msgsResponse = await supabase
          .from('messages')
          .select()
          .or('and(sender_id.eq.$doctorId,receiver_id.eq.$patientId),and(sender_id.eq.$patientId,receiver_id.eq.$doctorId)')
          .order('created_at', ascending: false)
          .limit(1);

      Message? lastMsg;
      if ((msgsResponse as List<dynamic>).isNotEmpty) {
        lastMsg = Message.fromJson(msgsResponse.first);
      }

      // 3. Fetch count of unread messages from this patient to the doctor
      final unreadResponse = await supabase
          .from('messages')
          .select('id')
          .eq('sender_id', patientId)
          .eq('receiver_id', doctorId)
          .eq('read', false)
          .count();
      
      final unreadCount = unreadResponse.count ?? 0;

      results.add(PatientChatInfo(
        patientId: patientId,
        patientName: patientName,
        lastMessage: lastMsg,
        unreadCount: unreadCount,
      ));
    }
    
    // Sort so most recent message comes first
    results.sort((a, b) {
      if (a.lastMessage == null && b.lastMessage == null) return 0;
      if (a.lastMessage == null) return 1;
      if (b.lastMessage == null) return -1;
      return b.lastMessage!.createdAt.compareTo(a.lastMessage!.createdAt);
    });

    return results;
  } catch (e) {
    debugPrint('[doctorPatientsChatProvider] error: $e');
    return [];
  }
});

class DoctorPatientListScreen extends ConsumerWidget {
  const DoctorPatientListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(doctorPatientsChatProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Patient Chats', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: patientsAsync.when(
        data: (patients) {
          if (patients.isEmpty) {
            return const Center(child: Text('No assigned patients found.', style: TextStyle(color: Colors.grey)));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(doctorPatientsChatProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: patients.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
              itemBuilder: (context, index) {
                final p = patients[index];
                return _buildPatientItem(context, p, ref);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildPatientItem(BuildContext context, PatientChatInfo info, WidgetRef ref) {
    final hasUnread = info.unreadCount > 0;
    String timeStr = '';
    String previewStr = 'No messages yet';

    if (info.lastMessage != null) {
      final msg = info.lastMessage!;
      final isMe = msg.senderId == supabase.auth.currentUser?.id;
      timeStr = _formatTime(msg.createdAt.toLocal());
      previewStr = isMe ? 'You: ${msg.content}' : msg.content;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primaryDark.withAlpha(20),
        child: const Icon(Icons.person, color: AppColors.primaryDark),
      ),
      title: Text(
        info.patientName,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          previewStr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (timeStr.isNotEmpty)
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 12,
                color: hasUnread ? AppColors.primaryDark : AppColors.textSecondary,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          const SizedBox(height: 4),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                info.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        context.push('/doctor/chat/${info.patientId}').then((_) {
          // Refresh list when coming back
          ref.refresh(doctorPatientsChatProvider);
        });
      },
    );
  }

  String _formatTime(DateTime dt) {
    if (DateTime.now().difference(dt).inDays > 0) {
      return DateFormat('MMM d').format(dt);
    }
    return DateFormat('HH:mm').format(dt);
  }
}
