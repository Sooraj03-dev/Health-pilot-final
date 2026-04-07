import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health_pilot/core/constants.dart';
import 'package:health_pilot/models/message.dart';
import 'package:health_pilot/providers/chat_provider.dart';
import 'package:health_pilot/widgets/loading_shimmer.dart';
import 'package:health_pilot/widgets/message_bubble.dart';

/// Full-screen AI Pilot chat interface.
///
/// Features:
///   • Disclaimer banner
///   • Scrollable chat ListView with user / assistant / error bubbles
///   • Streaming text shown incrementally with a cursor
///   • Loading shimmer on first load
///   • Upload Report — picks a PDF/image, passes to Gemini
///   • Live Vitals — bottom sheet showing latest biometrics
///   • Symptom text field + send button
class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom(delay: 300);
  }

  void _scrollToBottom({int delay = 0}) {
    Future.delayed(Duration(milliseconds: delay), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Live Vitals bottom sheet ───────────────────────────────────────────────

  void _showLiveVitals() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _LiveVitalsSheet(),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // Auto-scroll when new content arrives.
    ref.listen<ChatState>(chatProvider, (_, next) {
      if (next.isLoading || next.messages.isNotEmpty) {
        _scrollToBottom(delay: 80);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6F5),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // ── Disclaimer banner ──────────────────────────────────────────
          _DisclaimerBanner(),

          // ── Chat list ──────────────────────────────────────────────────
          Expanded(
            child: _buildChatList(chatState),
          ),

          // ── Action bar (Upload + Live Vitals) ─────────────────────────
          _buildActionBar(chatState),

          // ── Input row ─────────────────────────────────────────────────
          _buildInputRow(chatState),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryDark, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A7A5E), Color(0xFF2E9B7F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.health_and_safety,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Health Pilot',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Medical AI Assistant',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.search_rounded,
                color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryDark.withAlpha(20),
            child: const Icon(Icons.person,
                color: AppColors.primaryDark, size: 18),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  Widget _buildChatList(ChatState chatState) {
    // Show shimmer only on initial load (empty messages + loading)
    final showShimmer =
        chatState.isLoading && chatState.messages.isEmpty;

    if (showShimmer) {
      return const ChatShimmer();
    }

    // Combine committed messages + optional in-progress streaming bubble
    final items = <_ChatListItem>[];
    for (final msg in chatState.messages) {
      items.add(_ChatListItem.message(msg));
    }
    if (chatState.isLoading && chatState.streamingText.isNotEmpty) {
      items.add(_ChatListItem.streaming(chatState.streamingText));
    } else if (chatState.isLoading && chatState.streamingText.isEmpty) {
      items.add(_ChatListItem.indicator());
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isIndicator) {
          return Padding(
            padding:
                const EdgeInsets.only(left: 56, top: 8, bottom: 8),
            child: Row(
              children: const [TypingIndicator()],
            ),
          );
        }
        if (item.isStreaming) {
          return MessageBubble(
            message: ChatMessage.assistant(item.streamingText!),
            isStreaming: true,
          );
        }
        return MessageBubble(message: item.message!);
      },
    );
  }

  Widget _buildActionBar(ChatState chatState) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          // Upload Report
          Expanded(
            child: _ActionButton(
              icon: Icons.upload_file_rounded,
              label: 'Upload Report',
              onTap: chatState.isLoading
                  ? null
                  : () => ref
                      .read(chatProvider.notifier)
                      .pickAndUploadFile(),
            ),
          ),
          const SizedBox(width: 12),
          // Live Vitals
          Expanded(
            child: _ActionButton(
              icon: Icons.favorite_outline_rounded,
              label: 'Live Vitals',
              onTap: _showLiveVitals,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(ChatState chatState) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F6F5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                      fontSize: 14.5, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Describe your symptoms…',
                    hintStyle:
                        TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: chatState.isLoading
                    ? const LinearGradient(
                        colors: [Color(0xFFCBD5E1), Color(0xFFCBD5E1)])
                    : const LinearGradient(
                        colors: [Color(0xFF1A7A5E), Color(0xFF2E9B7F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                shape: BoxShape.circle,
                boxShadow: chatState.isLoading
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF1A7A5E).withAlpha(60),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: IconButton(
                icon: Icon(
                  chatState.isLoading
                      ? Icons.hourglass_top_rounded
                      : Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: chatState.isLoading ? null : _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Disclaimer Banner
// ─────────────────────────────────────────────────────────────────────────────

class _DisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: const Color(0xFFFFFBEB),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFD97706), size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'AI responses are for informational purposes only. '
              'Not a substitute for professional medical advice.',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF92400E),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Button
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDisabled
              ? const Color(0xFFF1F5F9)
              : const Color(0xFFE8F4F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled
                ? AppColors.border
                : AppColors.primaryDark.withAlpha(80),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 17,
                color: isDisabled
                    ? AppColors.textSecondary
                    : AppColors.primaryDark),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDisabled
                    ? AppColors.textSecondary
                    : AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Vitals Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _LiveVitalsSheet extends ConsumerWidget {
  const _LiveVitalsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vitalsAsync = ref.watch(latestVitalsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Live Vitals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Latest 3 readings from health_metrics',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          vitalsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                    color: AppColors.primaryDark),
              ),
            ),
            error: (e, _) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Error loading vitals: $e',
                  style: const TextStyle(color: Colors.red)),
            ),
            data: (vitals) {
              if (vitals.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No vitals recorded yet.\nSync your wearable from the dashboard.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }
              return Column(
                children: vitals.map((m) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4F4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timeline_rounded,
                            color: AppColors.primaryDark, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            m.recordedAt
                                .toLocal()
                                .toString()
                                .substring(0, 16),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        _VitalChip(
                          icon: Icons.favorite_rounded,
                          value:
                              '${m.heartRate.toStringAsFixed(0)} bpm',
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(width: 8),
                        _VitalChip(
                          icon: Icons.water_drop_rounded,
                          value:
                              '${m.spo2.toStringAsFixed(1)}%',
                          color: Colors.blue.shade600,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VitalChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _VitalChip(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal list-item helper (avoids union type boilerplate)
// ─────────────────────────────────────────────────────────────────────────────

class _ChatListItem {
  final ChatMessage? message;
  final String? streamingText;
  final bool isIndicator;

  const _ChatListItem._({this.message, this.streamingText, this.isIndicator = false});

  factory _ChatListItem.message(ChatMessage m) =>
      _ChatListItem._(message: m);

  factory _ChatListItem.streaming(String t) =>
      _ChatListItem._(streamingText: t);

  factory _ChatListItem.indicator() =>
      const _ChatListItem._(isIndicator: true);

  bool get isStreaming => streamingText != null;
}
