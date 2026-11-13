import 'package:feniksflutter/services/metadata_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseSong', () {
    test('splits artist and title on the first dash', () {
      expect(MetadataService.parseSong('Dino Merlin - Godinama - Live'), {
        'artist': 'Dino Merlin',
        'title': 'Godinama - Live',
      });
    });

    test('keeps a title without artist', () {
      expect(MetadataService.parseSong('Jutarnji program'), {
        'title': 'Jutarnji program',
        'artist': '',
      });
    });

    test('empty text gives nothing', () {
      expect(MetadataService.parseSong('  '), isEmpty);
    });

    test('studio phone announcements stay whole, by Feniks Radio', () {
      for (final text in [
        'Studio - 066 / 17 17 13',
        'Feniks - 066-17-17-13',
        '+387 66 17 17 13',
        '066 171713',
      ]) {
        expect(MetadataService.parseSong(text), {
          'title': text,
          'artist': MetadataService.stationArtist,
        });
      }
    });
  });

  group('songFromStatus', () {
    test('reads the title of our mount, not the first one', () {
      final data = {
        'icestats': {
          'source': [
            {
              'listenurl': 'https://c30.radioboss.fm:8234/autodj',
              'title': 'Stara - Pjesma',
            },
            {
              'listenurl': 'https://c30.radioboss.fm:8234/stream',
              'title': 'Nova - Pjesma',
              'yp_currently_playing': 'Stara - Pjesma',
            },
          ],
        },
      };
      expect(MetadataService.songFromStatus(data), {
        'artist': 'Nova',
        'title': 'Pjesma',
      });
    });

    test('works with a single source and a separate artist field', () {
      final data = {
        'icestats': {
          'source': {
            'listenurl': 'https://c30.radioboss.fm:8234/stream',
            'artist': 'Halid Bešlić',
            'title': 'Romanija',
          },
        },
      };
      expect(MetadataService.songFromStatus(data), {
        'artist': 'Halid Bešlić',
        'title': 'Romanija',
      });
    });

    test('falls back to yp_currently_playing without a title', () {
      final data = {
        'icestats': {
          'source': {'yp_currently_playing': 'A - B'},
        },
      };
      expect(MetadataService.songFromStatus(data), {'artist': 'A', 'title': 'B'});
    });

    test('uses another mount when ours has no title', () {
      final data = {
        'icestats': {
          'source': [
            {
              'listenurl': 'http://c30.radioboss.fm:8234/autodj',
              'title': 'Lapsus Band - Cekam Te',
            },
            {'listenurl': 'http://c30.radioboss.fm:8234/stream'},
          ],
        },
      };
      expect(MetadataService.songFromStatus(data), {
        'artist': 'Lapsus Band',
        'title': 'Cekam Te',
      });
    });

    test('unknown shapes give nothing', () {
      expect(MetadataService.songFromStatus(null), isEmpty);
      expect(MetadataService.songFromStatus({'icestats': {}}), isEmpty);
    });
  });

  test('stop closes the stream', () {
    final service = MetadataService();
    expect(service.metadataStream, isNotNull);
    service.stop();
    expect(service.metadataStream, isNull);
    expect(service.isPolling, isFalse);
  });
}
