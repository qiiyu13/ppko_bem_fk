import 'package:flutter/material.dart';

/// Parallax slide transition — foreground slides at 100%, background at 30%.
/// Push: new screen slides in from right, old screen drifts left.
/// Pop: reverse.
class ParallaxPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ParallaxPageRoute({required this.page, super.settings})
      : super(
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            final reverseCurve = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            // Foreground: slides in from right (0,0 → 1,0)
            final foregroundSlide = Tween<Offset>(
              begin: const Offset(1.0, 0),
              end: Offset.zero,
            ).animate(curve);

            // Background: drifts left at 30% speed (parallax)
            final backgroundSlide = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.3, 0),
            ).animate(reverseCurve);

            return SlideTransition(
              position: backgroundSlide,
              child: SlideTransition(
                position: foregroundSlide,
                child: child,
              ),
            );
          },
        );
}

/// Shorthand helper — drop-in replacement for MaterialPageRoute.
Route<T> slideRoute<T>(Widget page, {RouteSettings? settings}) =>
    ParallaxPageRoute<T>(page: page, settings: settings);
