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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
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
      onLongPressUp: () => _cancelCountdown(),
      onLongPressCancel: () => _cancelCountdown(),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = _isPressed ? 1.0 : _pulseAnimation.value;
          
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 20 * scale,
                    spreadRadius: 5 * scale,
                  ),
                ],
              ),
              child: Center(
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : _isPressed
                    ? Text(
                        '\$_secondsLeft',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
