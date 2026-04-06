import 'dart:async';
import 'package:flutter/material.dart';

class SosButton extends StatefulWidget {
  final Future<bool> Function() onTriggered;

  const SosButton({super.key, required this.onTriggered});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Timer? _countdownTimer;
  int _secondsLeft = 3;
  bool _isPressed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    if (_isLoading) return;

    setState(() {
      _isPressed = true;
      _secondsLeft = 3;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _fireSos();
        timer.cancel();
      }
    });
  }

  void _cancelCountdown() {
    if (_isLoading) return;
    
    _countdownTimer?.cancel();
    setState(() {
      _isPressed = false;
      _secondsLeft = 3;
    });
  }

  Future<void> _fireSos() async {
    setState(() {
      _isPressed = false;
      _isLoading = true;
    });

    await widget.onTriggered();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _secondsLeft = 3;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startCountdown(),
      onLongPressEnd: (_) => _cancelCountdown(),
      onLongPressCancel: () => _cancelCountdown(),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          // Calculate pulse scales. When pressed, shrink everything slightly.
          final baseScale = _isPressed ? 0.95 : 1.0;
          final pulseVal = _isPressed ? 0.0 : _pulseAnimation.value;
          
          return Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ripple layer
                  Transform.scale(
                    scale: baseScale + (0.15 * pulseVal),
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha((255 * 0.15).round()),
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                  // Inner ripple layer
                  Transform.scale(
                    scale: baseScale + (0.08 * pulseVal),
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha((255 * 0.3).round()),
                        borderRadius: BorderRadius.circular(36),
                      ),
                    ),
                  ),
                  // Core SOS Button
                  Transform.scale(
                    scale: baseScale,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withAlpha((255 * 0.4).round()),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isPressed ? '$_secondsLeft' : 'SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _isPressed ? 48 : 42,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
