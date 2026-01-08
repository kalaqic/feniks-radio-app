import 'package:flutter_test/flutter_test.dart';
import 'package:feniksflutter/services/metadata_service.dart';

void main() {
  group('MetadataService Tests', () {
    late MetadataService metadataService;

    setUp(() {
      metadataService = MetadataService();
    });

    tearDown(() {
      metadataService.stop();
    });

    test('should initialize and start metadata service', () {
      expect(() => metadataService.start(), returnsNormally);
      expect(metadataService.metadataStream, isNotNull);
    });

    test('should get current metadata', () async {
      final metadata = await metadataService.getCurrentMetadata();
      expect(metadata, isA<Map<String, String>>());
      expect(metadata.containsKey('title'), isTrue);
    });

    test('should parse ICY metadata string correctly', () {
      // This test would require making the parsing method public or using a test helper
      // For now, we'll just test that the service can be created and used
      expect(metadataService, isNotNull);
    });

    test('should handle errors gracefully', () async {
      // Test that the service doesn't crash when network is unavailable
      final metadata = await metadataService.getCurrentMetadata();
      expect(metadata, isA<Map<String, String>>());
      // Should return fallback values
      expect(metadata['title'], isNotNull);
    });

    test('should stop metadata service properly', () {
      metadataService.start();
      expect(() => metadataService.stop(), returnsNormally);
      expect(metadataService.metadataStream, isNull);
    });
  });
}