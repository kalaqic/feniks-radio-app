import 'package:flutter/material.dart';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  FadePageRoute({
    required Widget page,
    super.settings,
    Duration duration = const Duration(milliseconds: 300),
  }) : super(
         transitionDuration: duration,
         reverseTransitionDuration: const Duration(milliseconds: 300),
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) =>
             FadeTransition(
               opacity: CurvedAnimation(
                 parent: animation,
                 curve: Curves.easeInOutCubic,
               ),
               child: child,
             ),
       );
}
