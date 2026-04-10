import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_pilot/providers/health_provider.dart';
import 'package:health_pilot/widgets/message_bubble.dart';
import 'package:health_pilot/widgets/vitals_card.dart';
import 'package:health_pilot/widgets/loading_shimmer.dart';
import 'package:health_pilot/models/message.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/services/auth_service.dart';

class CaregiverScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String patientName;

  const CaregiverScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends ConsumerState<CaregiverScreen> 
    with TickerProviderStateMixin {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _doctorScrollController = ScrollController();
  final ScrollController _caregiverScrollController = ScrollController();
  late AnimationController _pulseController;
  
  String? _doctorId;
  bool _isLoadingDoctor = true;

  @override
  void initState() {
    super.initState();
    _initScreen();
    
    // Setup pulse indicator for the LIVE vitals badge
    _pulseController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  Future<void> _initScreen() async {
    await _fetchAssignedDoctor();
  }

  Future<void> _fetchAssignedDoctor() async {
    try {
      // Fetch assigned doctor for this patient
      final response = await supabase
          .from('assigned_patients')
          .select('doctor_id')
          .eq('patient_id', widget.patientId)
          .limit(1)
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          _doctorId = response?['doctor_id'] as String?;
          _isLoadingDoctor = false;
        });
      }
    } catch (e) {
      debugPrint('[CaregiverScreen] Error fetching doctor: $e');
      if (mounted) setState(() => _isLoadingDoctor = false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _msgController.dispose();
    _doctorScrollController.dispose();
    _caregiverScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom(ScrollController controller) {
    if (controller.hasClients) {
      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSend() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    
    _msgController.clear();
    try {
      await supabase.from('messages').insert({
        'sender_id': supabase.auth.currentUser!.id,
        'receiver_id': widget.patientId,
        'content': text,
        // Let the default timestamp / created_at trigger in schema, 
        // Or explicitly pass what the table expects:
        // 'created_at': DateTime.now().toIso8601String(), 
        // 'is_read': false,
      });
      // Let the stream update then scroll
      Future.delayed(const Duration(milliseconds: 100), () => _scrollToBottom(_caregiverScrollController));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Stream<List<Message>> _getStreamForTab(String? otherId, bool isReadOnly) {
    if (otherId == null) return const Stream.empty();
    
    if (isReadOnly) {
      // Tab 1: Doctor <-> Patient
      return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true) // Note: using created_at instead of timestamp to avoid Postgrest errors!
        .map((data) => data.where((msg) =>
          (msg['sender_id'] == otherId && msg['receiver_id'] == widget.patientId) ||
          (msg['sender_id'] == widget.patientId && msg['receiver_id'] == otherId)
        ).map((e) => Message.fromJson(e)).toList());
    } else {
      // Tab 2: Caregiver <-> Patient
      final caregiverId = supabase.auth.currentUser!.id;
      return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true) // Note: using created_at instead of timestamp
        .map((data) => data.where((msg) =>
          (msg['sender_id'] == caregiverId && msg['receiver_id'] == widget.patientId) ||
          (msg['sender_id'] == widget.patientId && msg['receiver_id'] == caregiverId)
        ).map((e) => Message.fromJson(e)).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF7ED), // Refined Light Orange Base
        appBar: AppBar(
          backgroundColor: const Color(0xFFEA580C), // Primary Orange
          centerTitle: false,
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Sign Out',
              onPressed: () async {
                await AuthService().signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
          title: Row(
            children: [
              const Icon(Icons.health_and_safety, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Caregiver View - ${widget.patientName}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Unified Patient Portal',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: '👨‍⚕️ Doctor Chat'),
              Tab(text: '💬 My Chat with Patient'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Doctor Chat (READ-ONLY)
                  _buildChatTab(
                    otherUserId: _doctorId,
                    isReadOnly: true,
                    emptyText: 'No messages between doctor and patient yet.',
                    controller: _doctorScrollController,
                  ),
                  
                  // Tab 2: Caregiver Chat (INTERACTIVE)
                  _buildChatTab(
                    otherUserId: widget.patientId, // The "other" is just the patient
                    isReadOnly: false,
                    emptyText: 'No messages yet. Start chatting with the patient.',
                    controller: _caregiverScrollController,
                  ),
                ],
              ),
            ),

            // Fixed Vitals Panel at bottom
            _buildVitalsDashboard(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTab({
    required String? otherUserId,
    required bool isReadOnly,
    required String emptyText,
    required ScrollController controller,
  }) {
    // Show shimmer if still resolving identity (in Read Only / Doctor tab)
    if (otherUserId == null && _isLoadingDoctor && isReadOnly) {
      return const ChatShimmer();
    }
    
    // If identity resolved but null (no doctor assigned)
    if (otherUserId == null && isReadOnly) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text('No doctor assigned for this patient', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Message>>(
            stream: _getStreamForTab(isReadOnly ? otherUserId : widget.patientId, isReadOnly),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ChatShimmer(); 
              }

              if (snapshot.hasError) {
                return Center(child: Text('Stream Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }

              final messages = snapshot.data ?? [];

              if (messages.isEmpty) {
                return Center(child: Text(emptyText, style: const TextStyle(color: Colors.black45)));
              }

              // Handle auto-scroll on new data
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(controller));

              return ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  
                  // Role Mapping for alignment:
                  // - In Read-only: Patient = Right (User style), Doctor = Left (Assistant style)
                  // - In Interactive: Current Caregiver = Right, Patient = Left
                  final isCurrentSelf = msg.senderId == supabase.auth.currentUser?.id;
                  final MessageRole role;
                  
                  if (isReadOnly) {
                    role = msg.senderId == widget.patientId ? MessageRole.user : MessageRole.assistant;
                  } else {
                    role = isCurrentSelf ? MessageRole.user : MessageRole.assistant;
                  }
                  
                  return MessageBubble(
                    message: ChatMessage(
                      role: role,
                      text: msg.content,
                      timestamp: msg.createdAt,
                    ),
                  );
                },
              );
            },
          ),
        ),
        
        if (isReadOnly)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.orange.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.visibility, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                const Text(
                  'Read-only view',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
            ),
          )
        else
          _buildInputContainer(),
      ],
    );
  }

  Widget _buildInputContainer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.orange.shade50)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -2))
        ]
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                decoration: InputDecoration(
                  hintText: 'Type message to patient...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(color: Color(0xFFEA580C), shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                onPressed: _handleSend,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsDashboard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: const Color(0xFFEA580C).withOpacity(0.1), blurRadius: 15, offset: const Offset(0, -5))
        ]
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monitor_heart, color: Color(0xFFEA580C), size: 20),
                const SizedBox(width: 8),
                const Text('Live Metrics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) => Opacity(
                    opacity: 0.3 + (_pulseController.value * 0.7),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, color: Colors.redAccent, size: 6),
                          SizedBox(width: 4),
                          Text('LIVE', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ref.watch(caregiverHealthMetricsProvider(widget.patientId)).when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFEA580C))),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red, fontSize: 12)),
              data: (metric) => Row(
                children: [
                  Expanded(
                    child: VitalsCard(
                      label: 'HEART RATE',
                      numericValue: metric?.heartRate.toDouble(),
                      unit: 'bpm',
                      borderColor: const Color(0xFFEF4444),
                      iconData: Icons.favorite,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: VitalsCard(
                      label: 'SpO2',
                      numericValue: metric?.spo2.toDouble(),
                      unit: '%',
                      borderColor: const Color(0xFF3B82F6),
                      iconData: Icons.bloodtype,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
