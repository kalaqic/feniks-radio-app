import 'package:flutter/material.dart';

import '../widgets/app_background_layer.dart';

/// Route that fades the new page in.
///
/// Every page is placed on top of its own [AppBackgroundLayer], so during the
/// transition the new page fully covers the old one instead of showing it
/// through its transparent background.
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
