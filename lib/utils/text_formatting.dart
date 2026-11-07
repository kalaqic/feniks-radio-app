class TextFormatting {
  static Map<String, String> formatSongInfo(String title, String artist) {
    final Map<String, String> result = {};

    // Format song title: first letter uppercase, rest lowercase
    result['title'] = formatTitle(title);

    // Format artist: every word starts with uppercase
    result['artist'] = formatArtist(artist);

    // Extract featuring information
    final featInfo = _extractFeaturing(title, artist);
    result['feat'] = featInfo['feat'] ?? '';

    // Update title and artist without feat info
    if (featInfo['cleanTitle'] != null) {
      result['title'] = featInfo['cleanTitle']!;
    }
    if (featInfo['cleanArtist'] != null) {
      result['artist'] = featInfo['cleanArtist']!;
    }

    return result;
  }

  /// Song title in sentence case: "bosnom behar" -> "Bosnom behar".
  static String formatTitle(String title) {
    if (title.isEmpty) return title;

    return title.toLowerCase().replaceRange(0, 1, title[0].toUpperCase());
  }

  /// Artist with every word capitalized: "SAFET ISOVIĆ" -> "Safet Isović".
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

    // Patterns to match featuring information
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

    // Check title for featuring info
    for (final pattern in featPatterns) {
      final match = pattern.firstMatch(cleanTitle);
      if (match != null) {
        featArtist = match.group(1)?.trim() ?? '';
        cleanTitle = cleanTitle.replaceAll(pattern, '').trim();
        break;
      }
    }

    // Check artist for featuring info
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
