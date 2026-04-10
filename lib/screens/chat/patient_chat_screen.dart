import 'package:flutter/material.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/screens/chat/chat_room_screen.dart';
import 'package:health_pilot/widgets/loading_shimmer.dart';

class PatientChatScreen extends StatefulWidget {
  const PatientChatScreen({super.key});

  @override
  State<PatientChatScreen> createState() => _PatientChatScreenState();
}

class _PatientChatScreenState extends State<PatientChatScreen> {
  bool _isLoading = true;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _fetchDoctorAndNavigate();
  }

  Future<void> _fetchDoctorAndNavigate() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      // Find the doctor assigned to this patient
      final data = await supabase
          .from('assigned_patients')
          .select('''
            doctor_id,
            profiles!assigned_patients_doctor_id_fkey (
                full_name
            )
          ''')
          .eq('patient_id', currentUser.id)
          .maybeSingle();

      if (!mounted) return;

      if (data == null) {
        setState(() {
          _errorMsg = 'No doctor assigned yet. Please contact support.';
          _isLoading = false;
        });
        return;
      }

      final doctorId = data['doctor_id'];
      final doctorProfile = data['profiles'];
      final doctorName = doctorProfile != null ? doctorProfile['full_name'] ?? 'Doctor' : 'Doctor';

      // Navigate directly, replacing the current route securely
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomScreen(
            patientId: doctorId, // Use doctorId as the 'otherUserId'
            patientName: doctorName,
          ),
        ),
      );

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Failed to load chat: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Doctor', style: TextStyle(color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const ChatShimmer()
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _errorMsg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
                ),
              ),
            ),
    );
  }
}
