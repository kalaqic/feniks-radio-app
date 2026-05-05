import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/radio_player_model.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoPulseController;
  late AnimationController _logoRotateController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;

  bool _isFallbackSong(RadioPlayerModel model) {
    final title = model.currentSong.trim().toLowerCase();
    // Treat default station name as unresolved metadata.
    return title.isEmpty || title == 'feniks radio';
  }

  Future<void> _runStartupFlow() async {
    final model = context.read<RadioPlayerModel>();

    // Keep loading until we get actual now-playing metadata.
    while (mounted && _isFallbackSong(model)) {
      await model.updateSong();
      if (!_isFallbackSong(model)) break;
      await Future.delayed(const Duration(seconds: 1));
    }

    // Then keep splash 5 more seconds.
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;
    final isLoggedIn = context.read<AuthService>().isAuthenticated;
    Navigator.pushReplacementNamed(
      context,
      isLoggedIn ? '/home' : '/welcome',
    );
  }

  @override
  void initState() {
    super.initState();
    _logoPulseController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _logoPulseController, curve: Curves.easeInOut),
    );
    _logoRotateController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );
    _logoRotation = Tween<double>(begin: -0.03, end: 0.03).animate(
      CurvedAnimation(parent: _logoRotateController, curve: Curves.easeInOut),
    );
    _logoPulseController.repeat(reverse: true);
    _logoRotateController.repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runStartupFlow();
    });
  }

  @override
  void dispose() {
    _logoPulseController.dispose();
    _logoRotateController.dispose();
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
                  animation: Listenable.merge([_logoScale, _logoRotation]),
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _logoRotation.value,
                      child: Transform.scale(
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
