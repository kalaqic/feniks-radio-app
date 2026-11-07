import 'package:flutter/foundation.dart';

void logError(String where, Object error) {
  if (kDebugMode) debugPrint('[Feniks] $where: $error');
}
