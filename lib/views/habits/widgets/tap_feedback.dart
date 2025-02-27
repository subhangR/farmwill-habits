import 'package:flutter/material.dart';

class TapFeedback extends StatefulWidget {
  final Widget child;
  final Color color;
  final Duration duration;

  const TapFeedback({
    Key? key,
    required this.child,
    required this.color,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<TapFeedback> createState() => _TapFeedbackState();
}

class _TapFeedbackState extends State<TapFeedback> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeOut,
      ),
    );
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!_isTapped) {
      setState(() {
        _isTapped = true;
      });
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isTapped = false;
    });
    if (_controller.status != AnimationStatus.reverse) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    setState(() {
      _isTapped = false;
    });
    if (_controller.status != AnimationStatus.reverse) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            children: [
              child!,
              Positioned.fill(
                child: Opacity(
                  opacity: _animation.value * 0.3, // Adjust opacity as needed
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
} 