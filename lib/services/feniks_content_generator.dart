import 'package:flutter/material.dart';

class FeniksContentGenerator {
  // Motivational quotes from famous writers and philosophers
  static final List<Map<String, String>> _famousQuotes = [
    {"text": "Uspjeh nije konačan, neuspjeh nije fatalan: važna je hrabrost da se nastavi.", "author": "Winston Churchill"},
    {"text": "Možeš pobjeći od poraza, ali nećeš pobjeći od pouke.", "author": "Maya Angelou"},
    {"text": "Budućnost pripada onima koji vjeruju u ljepotu svojih snova.", "author": "Eleanor Roosevelt"},
    {"text": "Jedini nemoguć put je onaj koji nećeš početi.", "author": "Tony Robbins"},
    {"text": "Sreća nije nešto gotovo. Dolazi iz vlastitih postupaka.", "author": "Dalai Lama"},
    {"text": "Uspjeh je sposobnost da ideš od neuspjeha do neuspjeha bez gubitka entuzijazma.", "author": "Winston Churchill"},
    {"text": "Budi ti promjena koju želiš vidjeti u svijetu.", "author": "Mahatma Gandhi"},
    {"text": "Život je 10% ono što ti se dogodi i 90% kako reaguješ na to.", "author": "Charles R. Swindoll"}
  ];

  // Motivational messages from Feniks Crew
  static final List<Map<String, String>> _feniksMessages = [
    {"text": "Muzika je univerzalni jezik koji spaja sve nas. Slušajte glasno, živite još glasnije! 🎵", "author": "Feniks Crew"},
    {"text": "Svaki novi dan je prilika za novi početak. Pustite da muzika bude vaš vodič kroz sve izazove.", "author": "Feniks Crew"},
    {"text": "U svakoj melodiji krije se priča. Koja je vaša priča danas?", "author": "Feniks Crew"},
    {"text": "Muzika je hrana za dušu. Hranimo vas svaki dan najljepšim notama i ritmovima! ❤️", "author": "Feniks Crew"},
    {"text": "Kada riječje nisu dovoljne, pusti da muzika govori umjesto tebe.", "author": "Feniks Crew"},
    {"text": "Vaša podrška je naš najbolji hit! Hvala vam što ste dio Feniks porodice! 🔥", "author": "Feniks Crew"}
  ];

  // Messages from top listeners with badges
  static final List<Map<String, String>> _listenerMessages = [
    {"text": "Feniks Radio mi je promijenio život! Svako jutro počinjem dan uz vaše emisije. Hvala vam! 💫", "author": "Marko S.", "badge": "Top 2% slušalac"},
    {"text": "Već 3 godine slušam Feniks svaki dan. Najbolja muzika, najbolji voditelji! Keep it up! 🎧", "author": "Ana M.", "badge": "VIP slušalac"},
    {"text": "Hvala vam što postojite! U teškim trenucima, vaša muzika mi je bila podrška.", "author": "Stefan R.", "badge": "Top 5% slušalac"},
    {"text": "Feniks Radio = dom za moju dušu. Ne mogu zamisliti dan bez vas! 🏠❤️", "author": "Milica K.", "badge": "Platinum slušalac"},
    {"text": "Vaše emisije su mi pomogle da prođem kroz sve životne faze. Beskrajno zahvalan! 🙏", "author": "Nikola D.", "badge": "Top 1% slušalac"}
  ];

  // Good news and positive stories
  static final List<String> _goodNews = [
    "Istraživanja pokazuju da muzika poboljšava mentalno zdravlje za 67% kod redovnih slušalaca!",
    "Lokalna zajednica organizovala je besplatne koncerte za starije susjede.",
    "Nova studija otkriva da ljudi koji slušaju radio češće pomažu drugima.",
    "Mladi glazbenici pokrenuli su inicijativu besplatnih lekcija za djecu iz siromašnih porodica.",
    "Radio stanice širom svijeta udružile su se za humanitarnu akciju.",
    "Otkriveno je da glazba smanjuje stres i povećava produktivnost na poslu."
  ];

  // Sample comments for posts
  static final List<Map<String, String>> _sampleComments = [
    {"author": "Marija K.", "text": "Ovo je tako istinito! 💯"},
    {"author": "Stefan M.", "text": "Baš mi je trebalo ovo danas, hvala! ❤️"},
    {"author": "Ana S.", "text": "Feniks Radio uvijek zna šta da kaže 🎵"},
    {"author": "Nikola P.", "text": "Inspirativno kao uvijek! 🔥"},
    {"author": "Milica D.", "text": "Savršeno vreme za ovakvu poruku 🌟"},
    {"author": "Aleksandar R.", "text": "Feniks ekipa je najbolja! Keep it up 💪"},
    {"author": "Jelena M.", "text": "Ovo mi je dan učinilo boljim ☀️"},
    {"author": "Petar N.", "text": "Muzika + mudre riječi = savršenstvo 🎧"},
  ];

  static final _random = <int>[];
  static int _contentIndex = 0;
  
  static Map<String, dynamic> generateContent() {
    // Create a mixed list of all content types for better variety
    if (_random.isEmpty) {
      _random.addAll(List.generate(_famousQuotes.length, (i) => i));
      _random.addAll(List.generate(_feniksMessages.length, (i) => i + 100));
      _random.addAll(List.generate(_listenerMessages.length, (i) => i + 200));
      _random.addAll(List.generate(_goodNews.length, (i) => i + 300));
      _random.shuffle();
    }
    
    final currentValue = _random[_contentIndex % _random.length];
    _contentIndex++;
    
    Map<String, String> postContent;
    
    if (currentValue < 100) {
      postContent = _famousQuotes[currentValue];
    } else if (currentValue < 200) {
      postContent = _feniksMessages[currentValue - 100];
    } else if (currentValue < 300) {
      postContent = _listenerMessages[currentValue - 200];
    } else {
      postContent = {"text": _goodNews[currentValue - 300], "author": "Feniks Radio"};
    }
    
    // Generate random comments (1-4 comments per post)
    final numComments = 1 + (DateTime.now().millisecondsSinceEpoch % 4);
    final comments = <Map<String, String>>[];
    final usedComments = <int>[];
    
    for (int i = 0; i < numComments; i++) {
      int commentIndex;
      do {
        commentIndex = DateTime.now().millisecondsSinceEpoch % _sampleComments.length;
      } while (usedComments.contains(commentIndex));
      
      usedComments.add(commentIndex);
      comments.add(_sampleComments[commentIndex]);
    }
    
    return {
      ...postContent,
      "comments": comments,
      "commentCount": numComments,
    };
  }
  
  static List<Map<String, String>> generateComments(int count) {
    final comments = <Map<String, String>>[];
    final random = DateTime.now().millisecondsSinceEpoch;
    
    for (int i = 0; i < count; i++) {
      final index = (random + i) % _sampleComments.length;
      comments.add(_sampleComments[index]);
    }
    
    return comments;
  }

  static String getContentType(Map<String, dynamic> content) {
    final author = content['author'] ?? '';
    if (author.contains('Churchill') || author.contains('Gandhi') || author.contains('Roosevelt') || 
        author.contains('Angelou') || author.contains('Robbins') || author.contains('Lama') || 
        author.contains('Swindoll')) {
      return 'Mudre riječi';
    }
    if (author == 'Feniks Crew') return 'Od nas za vas';
    if (content.containsKey('badge')) return 'Slušaoci govore';
    return 'Dobre vijesti';
  }

  static IconData getContentIcon(Map<String, dynamic> content) {
    final author = content['author'] ?? '';
    if (author.contains('Churchill') || author.contains('Gandhi') || author.contains('Roosevelt') || 
        author.contains('Angelou') || author.contains('Robbins') || author.contains('Lama') || 
        author.contains('Swindoll')) {
      return Icons.format_quote_rounded;
    }
    if (author == 'Feniks Crew') return Icons.radio_rounded;
    if (content.containsKey('badge')) return Icons.people_rounded;
    return Icons.celebration_rounded;
  }
}