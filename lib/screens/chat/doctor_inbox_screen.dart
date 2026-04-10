import 'package:flutter/material.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/screens/chat/chat_room_screen.dart';
import 'package:health_pilot/widgets/loading_shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

class DoctorInboxScreen extends StatefulWidget {
  const DoctorInboxScreen({super.key});

  @override
  State<DoctorInboxScreen> createState() => _DoctorInboxScreenState();
}

class _DoctorInboxScreenState extends State<DoctorInboxScreen> {
  bool _isLoading = true;
  List<dynamic> _patients = [];

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      final data = await supabase
          .from('assigned_patients')
          .select('''
            patient_id,
            profiles!assigned_patients_patient_id_fkey (
                id,
                full_name,
                role
            ),
            messages (
                content,
                created_at,
                sender_id,
                is_read
            )
          ''')
          .eq('doctor_id', currentUser.id)
          .order('created_at', referencedTable: 'messages', ascending: false);

      if (mounted) {
        setState(() {
          _patients = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching patients: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Patients',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A7A5E)),
            onPressed: _fetchPatients,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPatients,
        color: const Color(0xFF1A7A5E),
        child: _isLoading
            ? ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: ChatShimmer(),
                ),
              )
            : _patients.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: Text(
                          'No patients assigned yet.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _patients.length,
                    itemBuilder: (context, index) {
                      final item = _patients[index];
                      final profile = item['profiles'];
                      final messages = item['messages'] as List<dynamic>? ?? [];
                      
                      final patientId = item['patient_id'];
                      final patientName = profile?['full_name'] ?? 'Unknown Patient';
                      
                      // Using the first message since we ordered by descending
                      final lastMessage = messages.isNotEmpty ? messages.first : null;
                      final lastMessageText = lastMessage?['content'] ?? 'No messages yet';
                      
                      // Calculate exact unread count based on database `is_read` flag
                      final unreadCount = messages
                          .where((m) => m['sender_id'] == patientId && m['is_read'] == false)
                          .length;

                      String timeText = '';
                      if (lastMessage != null && lastMessage['created_at'] != null) {
                        try {
                          final dt = DateTime.parse(lastMessage['created_at']);
                          timeText = timeago.format(dt);
                        } catch (_) {}
                      }

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatRoomScreen(
                                patientId: patientId,
                                patientName: patientName,
                              ),
                            ),
                          ).then((_) => _fetchPatients()); // Refresh on return
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFF1A7A5E).withAlpha(20),
                                child: Text(
                                  patientName.isNotEmpty ? patientName[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: Color(0xFF1A7A5E),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            patientName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: Color(0xFF1E293B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (timeText.isNotEmpty)
                                          Text(
                                            timeText,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            lastMessageText,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: unreadCount > 0
                                                  ? const Color(0xFF334155)
                                                  : const Color(0xFF64748B),
                                              fontWeight: unreadCount > 0
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (unreadCount > 0) ...[
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEF4444),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
