import 'package:flutter/material.dart';

/// A vitals metric card with an animated value, status badge, and sparkline.
///
/// Both [heartRate] and [spo2] can be null (while data is loading or unavailable);
/// in that case the card shows "--" instead of crashing.
class VitalsCard extends StatelessWidget {
  final String label;

  /// The actual numeric value to display.  Pass `null` to show "--".
  final double? numericValue;
  final String unit;
  final Color borderColor;
  final IconData iconData;
  final List<double> dataPoints;

  const VitalsCard({
    super.key,
    required this.label,
    required this.numericValue,
    required this.unit,
    required this.borderColor,
    required this.iconData,
    this.dataPoints = const [],
  });

  // ── Status badge logic ──────────────────────────────────────────────────────

  /// Derives status text + colour from the value and the metric type.
  _StatusInfo get _status {
    final v = numericValue;
    if (v == null) return _StatusInfo('Waiting', Colors.grey);

    // Heart Rate badge (detected by borderColor == red-ish or by label string)
    if (label.toUpperCase().contains('HEART')) {
      if (v >= 60 && v <= 100) return _StatusInfo('Normal', const Color(0xFF2E9B7F));
      if ((v >= 50 && v < 60) || (v > 100 && v <= 110)) {
        return _StatusInfo('Borderline', Colors.orange);
      }
      return _StatusInfo('Critical', Colors.red);
    }

    // SpO2 badge
    if (v >= 97) return _StatusInfo('Normal', const Color(0xFF2E9B7F));
    if (v >= 95) return _StatusInfo('Low', Colors.orange);
    return _StatusInfo('Critical', Colors.red);
  }



  @override
  Widget build(BuildContext context) {
    final info = _status;

    return Container(
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
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: borderColor, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: icon + status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(iconData, color: borderColor, size: 24),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: info.color.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      info.text,
                      style: TextStyle(
                        color: info.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Animated value using TweenAnimationBuilder
              numericValue != null
                  ? TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween<double>(
                        begin: numericValue! * 0.8,
                        end: numericValue!,
                      ),
                      curve: Curves.easeOut,
                      builder: (context, value, _) {
                        return _ValueRow(
                          displayValue: value.toInt().toString(),
                          unit: unit,
                        );
                      },
                    )
                  : _ValueRow(displayValue: '--', unit: unit),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              // Sparkline
              SizedBox(
                height: 40,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SparklinePainter(
                    dataPoints: dataPoints,
                    lineColor: borderColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _StatusInfo {
  final String text;
  final Color color;
  const _StatusInfo(this.text, this.color);
}

class _ValueRow extends StatelessWidget {
  final String displayValue;
  final String unit;
  const _ValueRow({required this.displayValue, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: Text(
            displayValue,
            key: ValueKey<String>(displayValue),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        if (unit.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Sparkline ─────────────────────────────────────────────────────────────────

class _SparklinePainter extends CustomPainter {
  final List<double> dataPoints;
  final Color lineColor;

  _SparklinePainter({required this.dataPoints, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    double minVal = dataPoints[0];
    double maxVal = dataPoints[0];
    for (final v in dataPoints) {
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
    }

    if (maxVal == minVal) {
      maxVal += 1;
      minVal -= 1;
    } else {
      final diff = maxVal - minVal;
      maxVal += diff * 0.1;
      minVal -= diff * 0.1;
    }

    final double widthStep =
        size.width / (dataPoints.length > 1 ? dataPoints.length - 1 : 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final double x = i * widthStep;
      final double normalizedY = (dataPoints[i] - minVal) / (maxVal - minVal);
      final double y = size.height - (normalizedY * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    if (dataPoints.length != oldDelegate.dataPoints.length) return true;
    for (int i = 0; i < dataPoints.length; i++) {
      if (dataPoints[i] != oldDelegate.dataPoints[i]) return true;
    }
    return false;
  }
}
