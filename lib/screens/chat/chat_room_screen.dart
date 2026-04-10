import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/models/message.dart';
import 'package:health_pilot/widgets/message_bubble.dart';
import 'package:health_pilot/widgets/loading_shimmer.dart';
import 'package:health_pilot/providers/chat_provider.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String patientName;

  const ChatRoomScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _attachedFileName;
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachedFileName = result.files.first.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _attachedFileName == null) return;

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    _messageController.clear();
    
    // Encode attachment inside the message content natively
    String finalContent = text;
    if (_attachedFileName != null) {
      finalContent = '[FILE: $_attachedFileName] $text'.trim();
      setState(() {
        _attachedFileName = null;
      });
    }

    try {
      await ref.read(chatServiceProvider).sendMessage(finalContent, widget.patientId);
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  void _showScheduleFollowUp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Schedule Follow-up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(_selectedDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(_selectedDate!)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) setModalState(() => _selectedDate = picked);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) setModalState(() => _selectedTime = picked);
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A7A5E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (_selectedDate != null && _selectedTime != null) {
                          final msg = '📅 Follow-up scheduled for ${DateFormat('MMM dd, yyyy').format(_selectedDate!)} at ${_selectedTime!.format(context)}';
                          ref.read(chatServiceProvider).sendMessage(msg, widget.patientId);
                          // Reset
                          _selectedDate = null;
                          _selectedTime = null;
                          Navigator.pop(context);
                          _scrollToBottom();
                        }
                      },
                      child: const Text('Confirm Follow-up', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRequestLabs() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final List<String> labOptions = [
          'Complete Blood Count (CBC)',
          'Lipid Panel',
          'HbA1c',
          'Thyroid Function (TSH)',
          'Liver Function Test (LFT)',
          'Kidney Function Test (KFT)',
          'Blood Glucose (Fasting)',
          'Urine Routine',
        ];
        final selected = <String>{};
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Request Lab Tests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: labOptions.map((lab) {
                      final isSelected = selected.contains(lab);
                      return FilterChip(
                        label: Text(lab),
                        selected: isSelected,
                        selectedColor: const Color(0xFFD9EEF9),
                        checkmarkColor: const Color(0xFF0F3987),
                        onSelected: (val) {
                          setModalState(() {
                            if (val) {
                              selected.add(lab);
                            } else {
                              selected.remove(lab);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A7A5E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: selected.isEmpty ? null : () {
                        final labList = selected.join(', ');
                        final msg = '🧪 Lab tests requested: $labList';
                        ref.read(chatServiceProvider).sendMessage(msg, widget.patientId);
                        Navigator.pop(context);
                        _scrollToBottom();
                      },
                      child: const Text('Send Lab Request', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF1A7A5E).withAlpha(20),
              child: Text(
                widget.patientName.isNotEmpty ? widget.patientName[0].toUpperCase() : 'P',
                style: const TextStyle(color: Color(0xFF1A7A5E), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.patientName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'Acute Care Patient',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Color(0xFF1A7A5E)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ref.watch(chatMessagesProvider(widget.patientId)).when(
                loading: () => const ChatShimmer(),
                error: (error, stackTrace) => Center(
                  child: Text('Error loading messages: $error', style: const TextStyle(color: Colors.red)),
                ),
                data: (messages) {
                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet. Start the conversation!',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 15,
                        ),
                      ),
                    );
                  }
                  
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD9EEF9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'TODAY',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1A3A6B), letterSpacing: 0.5),
                            ),
                          ),
                        );
                      }
                      
                      final msg = messages[index - 1];
                      final isMe = msg.senderId == currentUser?.id;

                      // Parse attachment out of content if it exists
                      String rawContent = msg.content;
                      String? extractedFile;
                      
                      final fileMatch = RegExp(r'^\[FILE:\s*(.+?)\]\s*(.*)$').firstMatch(rawContent);
                      if (fileMatch != null) {
                        extractedFile = fileMatch.group(1);
                        rawContent = fileMatch.group(2) ?? '';
                      }

                      final chatMessage = ChatMessage(
                        role: isMe ? MessageRole.user : MessageRole.assistant,
                        text: rawContent,
                        timestamp: msg.createdAt,
                        attachedFileName: extractedFile,
                      );

                      // Hide bubbles that are *only* empty strings (if an attachment failed parsing somehow, but we handle it)
                      if (rawContent.isEmpty && extractedFile == null) return const SizedBox.shrink();

                      return MessageBubble(message: chatMessage);
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF8FAFC),
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _showScheduleFollowUp,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7BAFF8), // Primary action pill
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Schedule Follow-up', style: TextStyle(color: Color(0xFF0F3987), fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _showRequestLabs,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9EEF9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Request Labs', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9EEF9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Prescription', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_attachedFileName != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                color: const Color(0xFFF8FAFC),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A7A5E).withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1A7A5E).withAlpha(60)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_file, size: 16, color: Color(0xFF1A7A5E)),
                          const SizedBox(width: 6),
                          Text(
                            _attachedFileName!,
                            style: const TextStyle(color: Color(0xFF1A7A5E), fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() => _attachedFileName = null),
                            child: const Icon(Icons.close, size: 16, color: Color(0xFF1A7A5E)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              color: const Color(0xFFF8FAFC),
              width: double.infinity,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Type message...',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF006B4D),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
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
