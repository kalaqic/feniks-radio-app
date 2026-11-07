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
