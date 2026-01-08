class TextFormatting {
  static Map<String, String> formatSongInfo(String title, String artist) {
    final Map<String, String> result = {};
    
    // Format song title: first letter uppercase, rest lowercase
    result['title'] = _formatTitle(title);
    
    // Format artist: every word starts with uppercase
    result['artist'] = _formatArtist(artist);
    
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
  
  static String _formatTitle(String title) {
    if (title.isEmpty) return title;
    
    return title.toLowerCase().replaceRange(0, 1, title[0].toUpperCase());
  }
  
  static String _formatArtist(String artist) {
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
      result['cleanArtist'] = _formatArtist(cleanArtistName);
    }
    
    if (featArtist.isNotEmpty) {
      result['feat'] = _formatArtist(featArtist);
      result['cleanTitle'] = _formatTitle(cleanTitle);
    }
    
    return result;
  }
}