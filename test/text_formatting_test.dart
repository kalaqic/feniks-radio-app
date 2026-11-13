import 'package:feniksflutter/utils/text_formatting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cleanSongText', () {
    final cases = {
      'Grijeh (official music video)': 'Grijeh',
      'Duga - (audio 2011) hd': 'Duga',
      'Romanija [Official Video HD]': 'Romanija',
      'Sanjam (Lyrics)': 'Sanjam',
      'Pjesma (2011)': 'Pjesma',
      'Pjesma | Official Audio': 'Pjesma',
      'Pjesma - Official Music Video': 'Pjesma',
      'Pjesma (Spot 2019) (HQ)': 'Pjesma',
      'Pjesma (feat. Neko)': 'Pjesma (feat. Neko)',
      'Pjesma (Live)': 'Pjesma (Live)',
      'Pjesma (Remix) [Official Video]': 'Pjesma (Remix)',
      'Thunder': 'Thunder',
      'Hdžaba': 'Hdžaba',
      'Natali Dizdar': 'Natali Dizdar',
    };
    cases.forEach((input, expected) {
      test(input, () {
        expect(TextFormatting.cleanSongText(input), expected);
      });
    });

    test('never returns an empty title', () {
      expect(TextFormatting.cleanSongText('(Official Video)'), '(Official Video)');
    });
  });
}
