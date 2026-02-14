import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EtherMessagesPage extends StatelessWidget {
  const EtherMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: Colors.white,
            size: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Poruke',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0A0A0F),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '💬✨',
                    style: const TextStyle(fontSize: 56),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Poruke dolaze uskoro!',
                    style: TextStyle(
                      fontSize: 22,
                      height: 1.3,
                      color: Colors.white.withValues(alpha: 0.98),
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ova mala funkcija se još sprema — grupa za poruke se tek pravi, pa ćemo je pustiti u sledećoj verziji aplikacije. Hvala što ste strpljivi i što ste tu s nama! 💜',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.55,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.primaryLight.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Vidimo se u narednoj verziji! 🌟',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryLight.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
