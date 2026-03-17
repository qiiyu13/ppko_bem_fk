// lib/widgets/animations/slide_in_card.dart

import 'package:flutter/material.dart';

class SlideInCard extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final AxisDirection direction;
  final Curve curve;

  const SlideInCard({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.direction = AxisDirection.up,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<SlideInCard> createState() => _SlideInCardState();
}

class _SlideInCardState extends State<SlideInCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    Offset beginOffset;
    switch (widget.direction) {
      case AxisDirection.up:
        beginOffset = const Offset(0, 1);
        break;
      case AxisDirection.down:
        beginOffset = const Offset(0, -1);
        break;
      case AxisDirection.left:
        beginOffset = const Offset(1, 0);
        break;
      case AxisDirection.right:
        beginOffset = const Offset(-1, 0);
        break;
    }

    _offsetAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(opacity: _opacityAnimation, child: widget.child),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
