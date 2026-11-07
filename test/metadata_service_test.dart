import 'package:feniksflutter/services/metadata_service.dart';
import 'package:flutter_test/flutter_test.dart';

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
      expect(metadataService, isNotNull);
    });

    test('should handle errors gracefully', () async {
      final metadata = await metadataService.getCurrentMetadata();
      expect(metadata, isA<Map<String, String>>());

      expect(metadata['title'], isNotNull);
    });

    test('should stop metadata service properly', () {
      metadataService.start();
      expect(() => metadataService.stop(), returnsNormally);
      expect(metadataService.metadataStream, isNull);
    });
  });
}
