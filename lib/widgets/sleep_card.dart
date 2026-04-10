import 'package:flutter/material.dart';

/// A full-width card showing sleep duration with a sine-wave sleep-cycle graph.
///
/// [sleepLabel] — the formatted string like "7h 45m" or "--" when no data.
/// [quality]    — "Poor" | "Fair" | "Normal" | "Good" | "Excellent" | null
class SleepCard extends StatelessWidget {
  final String sleepLabel;
  final String? quality;

  const SleepCard({
    super.key,
    required this.sleepLabel,
    this.quality,
  });

  static const _purple = Color(0xFF5C6BC0);

  // ── Badge colour ──────────────────────────────────────────────────────────

  _BadgeInfo get _badge {
    switch (quality) {
      case 'Poor':
        return const _BadgeInfo('Poor', Color(0xFFE53935));
      case 'Fair':
        return const _BadgeInfo('Fair', Color(0xFFFF9800));
      case 'Good':
        return const _BadgeInfo('Good', Color(0xFF2E9B7F));
      case 'Excellent':
        return const _BadgeInfo('Excellent', Color(0xFF00897B));
      case 'Normal':
      default:
        return const _BadgeInfo('Normal', Color(0xFF2E9B7F));
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: _purple, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: moon icon + badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.nightlight_round,
                      color: _purple, size: 24),
                  _Badge(text: badge.text, color: badge.color),
                ],
              ),
              const SizedBox(height: 16),
              // Value with animated switcher
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: Text(
                  sleepLabel,
                  key: ValueKey<String>(sleepLabel),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'SLEEP DURATION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              // Sine-wave sleep graph
              SizedBox(
                height: 40,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SleepWavePainter(color: _purple),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Badge helper ──────────────────────────────────────────────────────────────

class _BadgeInfo {
  final String text;
  final Color color;
  const _BadgeInfo(this.text, this.color);
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Sine-wave painter (sleep cycle visualization) ─────────────────────────────

class _SleepWavePainter extends CustomPainter {
  final Color color;
  const _SleepWavePainter({required this.color});

  // Sample sleep-cycle data points (normalised 0–1)
  static const _points = [
    0.5, 0.8, 0.2, 0.85, 0.15, 0.9, 0.25, 0.75, 0.4, 0.5,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final stepX = size.width / (_points.length - 1);

    for (int i = 0; i < _points.length; i++) {
      final x = i * stepX;
      // Flip Y so 1.0 is top, 0.0 is bottom
      final y = size.height - (_points[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Smooth cubic bezier between points
        final prevX = (i - 1) * stepX;
        final prevY = size.height - (_points[i - 1] * size.height);
        final cpX = prevX + (x - prevX) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SleepWavePainter old) => old.color != color;
}
