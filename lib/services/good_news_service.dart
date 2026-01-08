import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'notification_service.dart';

class GoodNewsService {
  // Optional remote JSON with fields: {"date":"2025-08-13","text":"..."}
  final String? remoteJsonUrl;
  GoodNewsService({this.remoteJsonUrl});

  Future<String> getTodayGoodNews() async {
    final today = DateTime.now();
    // Try remote first if provided
    if (remoteJsonUrl != null && remoteJsonUrl!.isNotEmpty) {
      try {
        final resp = await http.get(Uri.parse(remoteJsonUrl!));
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body);
          if (data is List) {
            // find item with today's date
            final iso = today.toIso8601String().substring(0, 10);
            for (final item in data) {
              if (item is Map && item['date'] == iso && item['text'] is String) {
                return item['text'] as String;
              }
            }
          } else if (data is Map && data['text'] is String) {
            return data['text'] as String;
          }
        }
      } catch (_) {}
    }
    // Fallback to bundled JSON
    try {
      final bundle = await DefaultAssetBundle.of(navigatorKey.currentContext!)
          .loadString('assets/good_news.json');
      final list = (json.decode(bundle) as List).cast<Map<String, dynamic>>();
      // choose by day-of-year to rotate
      final dayOfYear = int.parse(
        DateTime(today.year, today.month, today.day).difference(DateTime(today.year, 1, 1)).inDays.toString(),
      );
      final item = list[dayOfYear % list.length];
      return item['text'] as String;
    } catch (_) {
      return 'Danas se negdje rodila dobra ideja — i možda je tvoja. 💛';
    }
  }
}