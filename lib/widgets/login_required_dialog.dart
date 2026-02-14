import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginRequiredDialog extends StatelessWidget {
  final String activityName;
  
  const LoginRequiredDialog({
    super.key,
    required this.activityName,
  });

  static void show(BuildContext context, String activityName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => LoginRequiredDialog(activityName: activityName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Theme.of(context).brightness == Brightness.dark;
    final isDarkMode = themeProvider;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.cardBackground : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isDarkMode
              ? Border.all(color: AppTheme.cardBorder, width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryWithOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Prijava potrebna',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? AppTheme.textPrimary : const Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Message
            Text(
              'Da biste sačuvali svoj napredak u "$activityName", morate biti prijavljeni.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDarkMode ? AppTheme.textSecondary : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: isDarkMode ? AppTheme.cardBorder : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      'Otkaži',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? AppTheme.textPrimary : const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Login button
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryWithOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, '/login');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          child: const Text(
                            'Prijavi se',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper extension to check auth and show dialog
extension AuthCheck on BuildContext {
  bool requireAuth(String activityName) {
    final authService = Provider.of<AuthService>(this, listen: false);
    if (!authService.isAuthenticated) {
      LoginRequiredDialog.show(this, activityName);
      return false;
    }
    return true;
  }
}

