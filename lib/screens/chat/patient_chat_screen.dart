import 'package:flutter/material.dart';
import 'package:health_pilot/core/constants.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/models/message.dart';
import 'package:health_pilot/services/chat_service.dart';
import 'package:health_pilot/features/chat/presentation/widgets/message_bubble.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PatientChatScreen — Real-time chat between the patient and their assigned
/// doctor, powered by [ChatService] (Supabase Realtime).
///
/// Flow:
///   1. On init, fetch the assigned doctor's ID from `assigned_patients`.
///   2. Fetch the doctor's name from `profiles`.
///   3. Initialise the ChatService stream for this conversation.
///   4. Display messages via StreamBuilder; auto-scroll on new messages.
///   5. Send messages through ChatService.sendMessage().
/// ─────────────────────────────────────────────────────────────────────────────
class PatientChatScreen extends StatefulWidget {
  const PatientChatScreen({super.key});

  @override
  State<PatientChatScreen> createState() => _PatientChatScreenState();
}

class _PatientChatScreenState extends State<PatientChatScreen>
    with WidgetsBindingObserver {
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  /// Current patient's ID (from Supabase Auth).
  late final String _patientId;

  /// The patient's assigned doctor ID, fetched on init.
  String? _doctorId;

  /// The doctor's display name, fetched from profiles.
  String? _doctorName;

  /// True while we are loading the doctor assignment + initialising the stream.
  bool _isInitialising = true;

  /// True when a message is currently being sent.
  bool _isSending = false;

  /// Number of messages we've last seen — used to detect new arrivals.
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _patientId = supabase.auth.currentUser!.id;
    _initChat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _chatService.dispose();
    super.dispose();
  }

  /// Observe keyboard changes so we can scroll to the bottom when keyboard opens.
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Small delay to let the layout settle after keyboard appears/disappears.
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _scrollToBottom();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Initialisation
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _initChat() async {
    final doctorId = await _getAssignedDoctorId();

    if (doctorId == null) {
      if (mounted) {
        setState(() => _isInitialising = false);
      }
      return;
    }

    // Fetch doctor name from profiles.
    final doctorName = await _getDoctorName(doctorId);

    if (mounted) {
      setState(() {
        _doctorId = doctorId;
        _doctorName = doctorName ?? 'Your Doctor';
        _isInitialising = false;
      });
    }

    // Initialise the ChatService stream.
    _chatService.initializeConversation(doctorId);
  }

  /// Queries `assigned_patients` to find the doctor assigned to this patient.
  Future<String?> _getAssignedDoctorId() async {
    try {
      final response = await supabase
          .from('assigned_patients')
          .select('doctor_id')
          .eq('patient_id', _patientId)
          .maybeSingle();

      return response?['doctor_id'] as String?;
    } catch (e) {
      debugPrint('[PatientChatScreen] Error fetching assigned doctor: $e');
      return null;
    }
  }

  /// Fetches the doctor's full_name from the `profiles` table.
  Future<String?> _getDoctorName(String doctorId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('full_name')
          .eq('user_id', doctorId)
          .maybeSingle();

      return response?['full_name'] as String?;
    } catch (e) {
      debugPrint('[PatientChatScreen] Error fetching doctor name: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Send message
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _doctorId == null || _isSending) return;

    _textController.clear();
    setState(() => _isSending = true);

    try {
      await _chatService.sendMessage(text, _doctorId!);
    } catch (e) {
      debugPrint('[PatientChatScreen] Send error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send message. Please try again.'),
            backgroundColor: AppColors.sosRed,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Scroll helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          // Doctor avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _doctorName != null ? 'Dr. $_doctorName' : 'Doctor Chat',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF80CBC4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined, size: 22),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Video call coming soon!'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBody() {
    // Loading state
    if (_isInitialising) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primaryDark),
            SizedBox(height: 16),
            Text(
              'Connecting to your doctor...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // No doctor assigned
    if (_doctorId == null) {
      return _buildNoDoctorState();
    }

    // Chat view
    return Column(
      children: [
        Expanded(child: _buildMessageList()),
        _buildInputBar(),
      ],
    );
  }

  // ── No Doctor Assigned State ───────────────────────────────────────────

  Widget _buildNoDoctorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                size: 48,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your doctor will be\nassigned soon.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Once a doctor is assigned to you, you\'ll be\nable to chat with them right here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _isInitialising = true);
                _initChat();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                side: const BorderSide(color: AppColors.primaryDark),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Message List (StreamBuilder) ────────────────────────────────────────

  Widget _buildMessageList() {
    return StreamBuilder<List<Message>>(
      stream: _chatService.messagesStream,
      builder: (context, snapshot) {
        // ── Loading ──
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryDark),
          );
        }

        // ── Error ──
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.sosRed, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final messages = snapshot.data ?? [];

        // ── Empty state ──
        if (messages.isEmpty) {
          return _buildEmptyState();
        }

        // Auto-scroll when new messages arrive.
        if (messages.length != _lastMessageCount) {
          _lastMessageCount = messages.length;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final isMine = msg.senderId == _patientId;

            // Show a date separator if the date changes between messages.
            Widget? dateSeparator;
            if (index == 0 ||
                !_isSameDay(
                    messages[index - 1].createdAt, msg.createdAt)) {
              dateSeparator = _buildDateSeparator(msg.createdAt);
            }

            return Column(
              children: [
                if (dateSeparator != null) dateSeparator,
                DoctorMessageBubble(
                  message: msg,
                  isMine: isMine,
                  showReadIndicator: isMine && index == messages.length - 1,
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryDark.withAlpha(15),
                    AppColors.primary.withAlpha(25),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 52,
                    color: AppColors.primaryDark.withAlpha(100),
                  ),
                  Positioned(
                    right: 22,
                    top: 22,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        size: 14,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Say hi to Dr. ${_doctorName ?? "your doctor"}! 👋',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Date Separator ──────────────────────────────────────────────────────

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(date.year, date.month, date.day);

    String label;
    if (msgDate == today) {
      label = 'Today';
    } else if (msgDate == today.subtract(const Duration(days: 1))) {
      label = 'Yesterday';
    } else {
      label =
          '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ── Input Bar ───────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _isSending ? null : _sendMessage,
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
