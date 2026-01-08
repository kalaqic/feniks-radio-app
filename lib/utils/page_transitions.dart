import 'package:flutter/material.dart';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Duration duration;

  FadePageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 250),
    RouteSettings? settings,
  }) : super(
          pageBuilder: (context, animation, _) => child,
          settings: settings,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              ),
              child: child,
            );
          },
        );
}

class ScaleFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Duration duration;

  ScaleFadePageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    RouteSettings? settings,
  }) : super(
          pageBuilder: (context, animation, _) => child,
          settings: settings,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleAnimation = Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
            ));

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ));

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            );
          },
        );
}

class SlideUpFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Duration duration;

  SlideUpFadePageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 350),
    RouteSettings? settings,
  }) : super(
          pageBuilder: (context, animation, _) => child,
          settings: settings,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ));

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            );
          },
        );
}

// Helper function to create routes with custom transitions
Route<T> createRoute<T extends Object?>({
  required Widget page,
  RouteSettings? settings,
  PageTransitionType? transitionType,
}) {
  switch (transitionType) {
    case PageTransitionType.scaleFade:
      return ScaleFadePageRoute<T>(
        child: page,
        settings: settings,
      );
    case PageTransitionType.slideUpFade:
      return SlideUpFadePageRoute<T>(
        child: page,
        settings: settings,
      );
    case PageTransitionType.fade:
    default:
      return FadePageRoute<T>(
        child: page,
        settings: settings,
      );
  }
}

enum PageTransitionType {
  fade,
  scaleFade,
  slideUpFade,
}