import 'package:flutter/foundation.dart';

/// Logs an error that the app recovers from on its own (debug builds only),
/// so failures are visible while developing instead of disappearing silently.
void logError(String where, Object error) {
  if (kDebugMode) debugPrint('[Feniks] $where: $error');
}
