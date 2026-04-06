import 'package:flutter/material.dart';

class VitalsCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String statusText;
  final Color statusColor;
  final Color borderColor;
  final IconData iconData;
  final List<double> dataPoints;

  const VitalsCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.statusText,
    required this.statusColor,
    required this.borderColor,
    required this.iconData,
    required this.dataPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: borderColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(iconData, color: borderColor, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Value Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: Text(
                  value,
                  key: ValueKey<String>(value),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
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
          ),
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
          // Sparkline Graph
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
    );
  }
}

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
    
    // Find min and max to scale the graph vertically
    double minVal = dataPoints[0];
    double maxVal = dataPoints[0];
    for (final v in dataPoints) {
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
    }
    
    // Add small padding to min/max so it doesn't touch the very top/bottom
    if (maxVal == minVal) {
      maxVal += 1;
      minVal -= 1;
    } else {
      final diff = maxVal - minVal;
      maxVal += diff * 0.1;
      minVal -= diff * 0.1;
    }

    final double widthStep = size.width / (dataPoints.length > 1 ? dataPoints.length - 1 : 1);
    
    for (int i = 0; i < dataPoints.length; i++) {
      final double x = i * widthStep;
      // Invert Y axis because 0 is at the top in canvas
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
