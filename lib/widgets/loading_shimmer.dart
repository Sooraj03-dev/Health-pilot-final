import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A loading placeholder for the chat view displayed while the first
/// Gemini response chunk has not yet arrived.
class ChatShimmer extends StatelessWidget {
  const ChatShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simulate assistant avatar + wide bubble
            _shimmerBubble(width: double.infinity, isAssistant: true),
            const SizedBox(height: 16),
            // Simulate a narrow second line
            _shimmerBubble(width: 220, isAssistant: true),
            const SizedBox(height: 24),
            // Simulate a user bubble on the right
            Align(
              alignment: Alignment.centerRight,
              child: _shimmerBubble(width: 160, isAssistant: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBubble({required double width, required bool isAssistant}) {
    return Row(
      mainAxisAlignment:
          isAssistant ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        if (isAssistant) ...[
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Container(
          width: width,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }
}

/// A small three-dot animated indicator shown while streaming is active.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final t = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A7A5E),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
