import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class VercelStripePaymentResult {
  final bool success;
  final String? paymentIntentId;

  const VercelStripePaymentResult({
    required this.success,
    this.paymentIntentId,
  });
}

class VercelStripePaymentService {
  VercelStripePaymentService._();
  static final instance = VercelStripePaymentService._();

  static const String publishableKey =
      'pk_test_51TTyzYQfTvWFv1LwDWqH9lCqqvoDGdPcKenjGhliFSfXHtMb1gvT9EGTRGuFNcF9N2iIJMKvjEcWJIyVjTZ4oQCe00Nu7r30Ia';

  // Example: --dart-define=VERCEL_API_BASE_URL=https://your-app.vercel.app
  static const String _apiBaseUrl =
      String.fromEnvironment(
        'VERCEL_API_BASE_URL',
        defaultValue: 'https://feniks-radio-app.vercel.app',
      );

  Future<void> initialize() async {
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }

  Future<VercelStripePaymentResult> pay({
    required String uid,
    required double amountEur,
  }) async {
    if (_apiBaseUrl.isEmpty) {
      throw Exception('VERCEL_API_BASE_URL nije podešen.');
    }

    final uri = Uri.parse('$_apiBaseUrl/api/create-payment-intent');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'uid': uid,
        'amountEur': amountEur,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String serverMessage = '';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        serverMessage = (decoded['error'] ?? decoded['message'] ?? '').toString();
      } catch (_) {
        serverMessage = response.body;
      }
      throw Exception(
        'Greška pri kreiranju naplate (${response.statusCode})'
        '${serverMessage.isNotEmpty ? ': $serverMessage' : ''}.',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final clientSecret = body['clientSecret'] as String?;
    final paymentIntentId = body['paymentIntentId'] as String?;
    if (clientSecret == null || paymentIntentId == null) {
      throw Exception('Neispravan odgovor sa servera za naplatu.');
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Muzička želja',
        style: ThemeMode.system,
        allowsDelayedPaymentMethods: true,
      ),
    );

    try {
      await Stripe.instance.presentPaymentSheet();
      return VercelStripePaymentResult(
        success: true,
        paymentIntentId: paymentIntentId,
      );
    } on StripeException {
      return const VercelStripePaymentResult(success: false);
    }
  }
}
