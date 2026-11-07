import 'package:flutter/material.dart';

import '../widgets/app_background_layer.dart';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  FadePageRoute({
    required Widget page,
    super.settings,
    Duration duration = const Duration(milliseconds: 250),
  }) : super(
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         pageBuilder: (context, animation, secondaryAnimation) => Stack(
           children: [
             const Positioned.fill(child: AppBackgroundLayer()),
             Positioned.fill(child: page),
           ],
         ),
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
