import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import '../pages/home_page.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _zoomController;
  late AnimationController _spinController;
  late AnimationController _slideController;
  late AnimationController _textController;
  late Animation<double> _zoomAnimation;
  late Animation<double> _spinAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _logoShrinkAnimation;
  late Animation<double> _textGrowAnimation;
  late Timer _navigationTimer;

  @override
  void initState() {
    super.initState();
    
    // Zoom animation (fast to slow)
    _zoomController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Spin animation (one full circle)
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Slide animation (move logo to left)
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Text fade animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Zoom animation with ease-out curve (fast to slow)
    _zoomAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _zoomController,
      curve: Curves.easeOut,
    ));

    // Spin animation (one full rotation)
    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeInOut,
    ));

    // Slide animation (move to left)
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: -90.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // Text fade animation
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));

    // Logo shrink animation (when sliding)
    _logoShrinkAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    // Text grow animation
    _textGrowAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    // Start animations sequence
    _zoomController.forward();
    _spinController.forward().then((_) {
      // After spin completes, slide logo left and show text simultaneously
      _slideController.forward();
      _textController.forward();
    });

    // Navigate to home after 5 seconds with fade transition
    _navigationTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
            transitionDuration: const Duration(milliseconds: 1000),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer.cancel();
    _zoomController.dispose();
    _spinController.dispose();
    _slideController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([_zoomController, _spinController, _slideController, _textController]),
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                // Logo with animations - starts centered, slides left
                Positioned(
                  left: MediaQuery.of(context).size.width / 2 - 60 + _slideAnimation.value, // Center minus half logo width
                  top: MediaQuery.of(context).size.height / 2 - 60, // Center minus half logo height
                  child: Transform.scale(
                    scale: _zoomAnimation.value * _logoShrinkAnimation.value,
                    child: Transform.rotate(
                      angle: _spinAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'lib/assets/png/logo_red.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Text that fades in - centered on screen, left-aligned
                Positioned(
                  left: MediaQuery.of(context).size.width / 2 - 40, // Center minus offset for left-aligned text
                  top: MediaQuery.of(context).size.height / 2 - 28, // Vertically centered with logo
                  child: Transform.scale(
                    scale: _textGrowAnimation.value,
                    child: Opacity(
                      opacity: _textFadeAnimation.value,
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FENIKS',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFEB6556),
                            letterSpacing: 2.0,
                            height: 0.9,
                          ),
                        ),
                        Text(
                          'RADIO',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            color: Color(0xFF1D1D1F),
                            letterSpacing: 2.0,
                            height: 0.9,
                          ),
                        ),
                      ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}