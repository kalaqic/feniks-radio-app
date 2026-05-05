import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _delayController;
  late AnimationController _logoPulseController;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _delayController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _logoPulseController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _logoPulseController, curve: Curves.easeInOut),
    );
    _logoPulseController.repeat(reverse: true);

    _delayController.forward().then((_) {
      if (!mounted) return;
      final isLoggedIn = context.read<AuthService>().isAuthenticated;
      Navigator.pushReplacementNamed(
        context,
        isLoggedIn ? '/home' : '/welcome',
      );
    });
  }

  @override
  void dispose() {
    _delayController.dispose();
    _logoPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background - whole PNG visible on page
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'lib/assets/png/background_decoration.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _logoScale,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScale.value,
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
                    );
                  },
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
