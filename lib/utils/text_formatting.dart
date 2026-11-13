class TextFormatting {
  static Map<String, String> formatSongInfo(String title, String artist) {
    final Map<String, String> result = {};

    result['title'] = formatTitle(title);

    result['artist'] = formatArtist(artist);

    final featInfo = _extractFeaturing(title, artist);
    result['feat'] = featInfo['feat'] ?? '';

    if (featInfo['cleanTitle'] != null) {
      result['title'] = featInfo['cleanTitle']!;
    }
    if (featInfo['cleanArtist'] != null) {
      result['artist'] = featInfo['cleanArtist']!;
    }

    return result;
  }

  /// Words that only describe the upload, not the song: "(Official Music
  /// Video)", "[HD]", "(audio 2011)", "| Lyrics" and the like.
  static final _junk = RegExp(
    r'\b(official|oficijaln\w*|music\s*video|video\s*clip|videoclip|'
    r'video|spot|audio|lyrics?|tekst|hd|hq|4k|1080p|720p|'
    r'visuali[sz]er|remaster(ed)?|full\s*album)\b',
    caseSensitive: false,
  );
  static final _bracketed = RegExp(r'\s*[(\[{]([^)\]}]*)[)\]}]');
  static final _yearOnly = RegExp(r'^\s*(19|20)\d{2}\s*$');
  static final _junkAtEnd = RegExp(
    r'(\s*[-|/•]\s*|\s+)(official\s+(music\s+)?video|official\s+audio|'
    r'music\s+video|lyrics?(\s+video)?|video|audio|hd|hq|4k)\s*$',
    caseSensitive: false,
  );
  static final _dangling = RegExp(r'[\s\-|/•]+$');

  /// Removes upload labels from a song title or artist. Brackets with
  /// anything else, such as "(feat. X)", "(Live)" or "(Remix)", stay.
  static String cleanSongText(String text) {
    var result = text.replaceAllMapped(_bracketed, (m) {
      final inside = m[1]!;
      final junk =
          inside.trim().isEmpty ||
          _junk.hasMatch(inside) ||
          _yearOnly.hasMatch(inside);
      return junk ? '' : m[0]!;
    });
    String before;
    do {
      before = result;
      result = result.replaceAll(_junkAtEnd, '').replaceAll(_dangling, '');
    } while (result != before);
    result = result.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return result.isEmpty ? text.trim() : result;
  }

  static String formatTitle(String title) {
    if (title.isEmpty) return title;

    return title.toLowerCase().replaceRange(0, 1, title[0].toUpperCase());
  }

  static String formatArtist(String artist) {
    if (artist.isEmpty) return artist;

    return artist
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word.toLowerCase().replaceRange(0, 1, word[0].toUpperCase());
        })
        .join(' ');
  }

  static Map<String, String> _extractFeaturing(String title, String artist) {
    final Map<String, String> result = {
      'cleanTitle': title,
      'cleanArtist': artist,
      'feat': '',
    };

    final featPatterns = [
      RegExp(r'\s+feat\.?\s+(.+?)(?:\s*[\)\]]|$)', caseSensitive: false),
      RegExp(r'\s+featuring\s+(.+?)(?:\s*[\)\]]|$)', caseSensitive: false),
      RegExp(r'\s+ft\.?\s+(.+?)(?:\s*[\)\]]|$)', caseSensitive: false),
      RegExp(r'\(feat\.?\s+(.+?)\)', caseSensitive: false),
      RegExp(r'\(featuring\s+(.+?)\)', caseSensitive: false),
      RegExp(r'\(ft\.?\s+(.+?)\)', caseSensitive: false),
    ];

    String cleanTitle = title;
    String featArtist = '';

    for (final pattern in featPatterns) {
      final match = pattern.firstMatch(cleanTitle);
      if (match != null) {
        featArtist = match.group(1)?.trim() ?? '';
        cleanTitle = cleanTitle.replaceAll(pattern, '').trim();
        break;
      }
    }

    if (featArtist.isEmpty) {
      String cleanArtistName = artist;
      for (final pattern in featPatterns) {
        final match = pattern.firstMatch(cleanArtistName);
        if (match != null) {
          featArtist = match.group(1)?.trim() ?? '';
          cleanArtistName = cleanArtistName.replaceAll(pattern, '').trim();
          break;
        }
      }
      result['cleanArtist'] = formatArtist(cleanArtistName);
    }

    if (featArtist.isNotEmpty) {
      result['feat'] = formatArtist(featArtist);
      result['cleanTitle'] = formatTitle(cleanTitle);
    }

    return result;
  }
}
