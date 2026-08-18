class _TranslitMatch {
  final String text;
  final int length;
  const _TranslitMatch(this.text, this.length);
}

/// Utility for converting Indian / Marathi names to authentic Marathi Devanagari script.
/// Supports dictionary matching for standard Marathi names/surnames and
/// rule-based phonetic transliteration for arbitrary/future dynamic names.
class MarathiTransliteration {
  MarathiTransliteration._();

  /// Checks if string already contains Devanagari characters (U+0900 to U+097F).
  static bool isDevanagari(String text) {
    return RegExp(r'[\u0900-\u097F]').hasMatch(text);
  }

  /// Converts an English/Latin name to its proper Marathi Devanagari representation.
  /// If the text is already in Devanagari or empty, it returns the input unchanged.
  static String toMarathi(String name) {
    if (name.trim().isEmpty) return name;
    if (isDevanagari(name)) return name;

    final words = name.trim().split(RegExp(r'\s+'));
    final translatedWords = words.map(_transliterateWord).toList();
    return translatedWords.join(' ');
  }

  static String _transliterateWord(String rawWord) {
    if (rawWord.isEmpty) return '';
    if (isDevanagari(rawWord)) return rawWord;

    final cleanWord = rawWord.toLowerCase();

    // 1. Direct dictionary lookup for authentic Marathi spelling
    if (_marathiNameDict.containsKey(cleanWord)) {
      return _marathiNameDict[cleanWord]!;
    }

    // 2. Dynamic phonetic transliteration fallback for arbitrary names
    return _phoneticTransliterate(cleanWord);
  }

  /// Rule-based phonetic transliteration algorithm
  static String _phoneticTransliterate(String input) {
    final buffer = StringBuffer();
    int i = 0;
    final len = input.length;
    bool lastWasConsonant = false;

    while (i < len) {
      // Standalone or initial vowel
      if (!lastWasConsonant) {
        final match = _matchInitialVowel(input, i);
        if (match.length > 0) {
          buffer.write(match.text);
          i += match.length;
          lastWasConsonant = false;
          continue;
        }
      } else {
        // Matra (vowel attached to previous consonant)
        final match = _matchMatra(input, i);
        if (match.length > 0) {
          buffer.write(match.text);
          i += match.length;
          lastWasConsonant = false;
          continue;
        }
      }

      // Check special conjuncts
      final conjMatch = _matchConjunct(input, i);
      if (conjMatch.length > 0) {
        if (lastWasConsonant) {
          buffer.write('्');
        }
        buffer.write(conjMatch.text);
        i += conjMatch.length;
        lastWasConsonant = true;
        continue;
      }

      // Check multi-character and single consonants
      final consMatch = _matchConsonant(input, i);
      if (consMatch.length > 0) {
        if (lastWasConsonant) {
          // Two adjacent consonants without a vowel form a conjunct (halant)
          buffer.write('्');
        }
        buffer.write(consMatch.text);
        i += consMatch.length;
        lastWasConsonant = true;
        continue;
      }

      // If unrecognized character (digits, punctuation), write directly
      buffer.write(input[i]);
      lastWasConsonant = false;
      i++;
    }

    return buffer.toString();
  }

  static _TranslitMatch _matchInitialVowel(String s, int idx) {
    if (idx + 2 <= s.length) {
      final sub2 = s.substring(idx, idx + 2);
      if (sub2 == 'aa') return const _TranslitMatch('आ', 2);
      if (sub2 == 'ai') return const _TranslitMatch('ऐ', 2);
      if (sub2 == 'au' || sub2 == 'ou') return const _TranslitMatch('औ', 2);
      if (sub2 == 'ee' || sub2 == 'ii') return const _TranslitMatch('ई', 2);
      if (sub2 == 'oo' || sub2 == 'uu') return const _TranslitMatch('ऊ', 2);
      if (sub2 == 'ru' || sub2 == 'ri') return const _TranslitMatch('ऋ', 2);
      if (sub2 == 'am' || sub2 == 'an') {
        if (idx + 2 == s.length || !_isVowelChar(s[idx + 2])) {
          return const _TranslitMatch('अं', 2);
        }
      }
    }
    final ch = s[idx];
    if (ch == 'a') return const _TranslitMatch('अ', 1);
    if (ch == 'i') return const _TranslitMatch('इ', 1);
    if (ch == 'u') return const _TranslitMatch('उ', 1);
    if (ch == 'e') return const _TranslitMatch('ए', 1);
    if (ch == 'o') return const _TranslitMatch('ओ', 1);

    return const _TranslitMatch('', 0);
  }

  static _TranslitMatch _matchMatra(String s, int idx) {
    if (idx + 2 <= s.length) {
      final sub2 = s.substring(idx, idx + 2);
      if (sub2 == 'aa') return const _TranslitMatch('ा', 2);
      if (sub2 == 'ai') return const _TranslitMatch('ै', 2);
      if (sub2 == 'au' || sub2 == 'ou') return const _TranslitMatch('ौ', 2);
      if (sub2 == 'ee' || sub2 == 'ii') return const _TranslitMatch('ी', 2);
      if (sub2 == 'oo' || sub2 == 'uu') return const _TranslitMatch('ू', 2);
      if (sub2 == 'am' || sub2 == 'an') {
        if (idx + 2 == s.length || !_isVowelChar(s[idx + 2])) {
          return const _TranslitMatch('ं', 2);
        }
      }
    }
    final ch = s[idx];
    if (ch == 'a') return const _TranslitMatch('', 1); // inherent 'a', consumes char without matra
    if (ch == 'i') return const _TranslitMatch('ि', 1);
    if (ch == 'u') return const _TranslitMatch('ु', 1);
    if (ch == 'e') return const _TranslitMatch('े', 1);
    if (ch == 'o') return const _TranslitMatch('ो', 1);

    return const _TranslitMatch('', 0);
  }

  static _TranslitMatch _matchConjunct(String s, int idx) {
    if (idx + 4 <= s.length) {
      final sub4 = s.substring(idx, idx + 4);
      if (sub4 == 'shhr' || sub4 == 'shri') return const _TranslitMatch('श्री', 4);
    }
    if (idx + 3 <= s.length) {
      final sub3 = s.substring(idx, idx + 3);
      if (sub3 == 'ksh') return const _TranslitMatch('क्ष', 3);
      if (sub3 == 'dny' || sub3 == 'jny') return const _TranslitMatch('ज्ञ', 3);
      if (sub3 == 'shr') return const _TranslitMatch('श्र', 3);
      if (sub3 == 'chh') return const _TranslitMatch('छ', 3);
      if (sub3 == 'str') return const _TranslitMatch('स्त्र', 3);
      if (sub3 == 'ndr') return const _TranslitMatch('न्द्र', 3);
      if (sub3 == 'sch') return const _TranslitMatch('श्च', 3);
    }
    if (idx + 2 <= s.length) {
      final sub2 = s.substring(idx, idx + 2);
      if (sub2 == 'pr') return const _TranslitMatch('प्र', 2);
      if (sub2 == 'tr') return const _TranslitMatch('त्र', 2);
      if (sub2 == 'kr') return const _TranslitMatch('क्र', 2);
      if (sub2 == 'gr') return const _TranslitMatch('ग्र', 2);
      if (sub2 == 'dr') return const _TranslitMatch('द्र', 2);
      if (sub2 == 'br') return const _TranslitMatch('ब्र', 2);
      if (sub2 == 'mr') return const _TranslitMatch('म्र', 2);
      if (sub2 == 'vr' || sub2 == 'wr') return const _TranslitMatch('व्र', 2);
      if (sub2 == 'gy') return const _TranslitMatch('ज्ञ', 2);
    }
    return const _TranslitMatch('', 0);
  }

  static _TranslitMatch _matchConsonant(String s, int idx) {
    if (idx + 2 <= s.length) {
      final sub2 = s.substring(idx, idx + 2);
      if (sub2 == 'kh') return const _TranslitMatch('ख', 2);
      if (sub2 == 'gh') return const _TranslitMatch('घ', 2);
      if (sub2 == 'ch') return const _TranslitMatch('च', 2);
      if (sub2 == 'jh') return const _TranslitMatch('झ', 2);
      if (sub2 == 'th') return const _TranslitMatch('थ', 2);
      if (sub2 == 'dh') return const _TranslitMatch('ध', 2);
      if (sub2 == 'ph') return const _TranslitMatch('फ', 2);
      if (sub2 == 'bh') return const _TranslitMatch('भ', 2);
      if (sub2 == 'sh') return const _TranslitMatch('श', 2);
      if (sub2 == 'ng') return const _TranslitMatch('ङ', 2);
      if (sub2 == 'ny') return const _TranslitMatch('ञ', 2);
    }

    final ch = s[idx];
    switch (ch) {
      case 'k': return const _TranslitMatch('क', 1);
      case 'g': return const _TranslitMatch('ग', 1);
      case 'c': return const _TranslitMatch('क', 1);
      case 'j': return const _TranslitMatch('ज', 1);
      case 'z': return const _TranslitMatch('झ', 1);
      case 't': return const _TranslitMatch('त', 1);
      case 'd': return const _TranslitMatch('द', 1);
      case 'n': return const _TranslitMatch('न', 1);
      case 'p': return const _TranslitMatch('प', 1);
      case 'f': return const _TranslitMatch('फ', 1);
      case 'b': return const _TranslitMatch('ब', 1);
      case 'm': return const _TranslitMatch('म', 1);
      case 'y': return const _TranslitMatch('य', 1);
      case 'r': return const _TranslitMatch('र', 1);
      case 'l': return const _TranslitMatch('ल', 1);
      case 'v': return const _TranslitMatch('व', 1);
      case 'w': return const _TranslitMatch('व', 1);
      case 's': return const _TranslitMatch('स', 1);
      case 'h': return const _TranslitMatch('ह', 1);
      case 'x': return const _TranslitMatch('क्स', 1);
      case 'q': return const _TranslitMatch('क', 1);
    }

    return const _TranslitMatch('', 0);
  }

  static bool _isVowelChar(String ch) {
    return 'aeiou'.contains(ch.toLowerCase());
  }

  /// Comprehensive dictionary of authentic Marathi names, middle names, and surnames
  static final Map<String, String> _marathiNameDict = {
    // --- First Names (Male) ---
    'tanmay': 'तन्मय',
    'vaibhav': 'वैभव',
    'rutik': 'रुतिक',
    'rhutik': 'रुतिक',
    'hrutik': 'ऋतिक',
    'aditya': 'आदित्य',
    'sachin': 'सचिन',
    'rahul': 'राहुल',
    'ramesh': 'रमेश',
    'suresh': 'सुरेश',
    'rajesh': 'राजेश',
    'amit': 'अमित',
    'aniket': 'अनिकेत',
    'akash': 'आकाश',
    'aakash': 'आकाश',
    'prashant': 'प्रशांत',
    'pradeep': 'प्रदीप',
    'prakash': 'प्रकाश',
    'pramod': 'प्रमोद',
    'ganesh': 'गणेश',
    'mahesh': 'महेश',
    'santosh': 'संतोष',
    'sanjay': 'संजय',
    'sandip': 'संदीप',
    'sandeep': 'संदीप',
    'vijay': 'विजय',
    'ajay': 'अजय',
    'vikas': 'विकास',
    'vishal': 'विशाल',
    'vikram': 'विक्रम',
    'vinod': 'विनोद',
    'amol': 'अमोल',
    'chetan': 'चेतन',
    'dinesh': 'दिनेश',
    'deepak': 'दीपक',
    'dipak': 'दीपक',
    'sunil': 'सुनील',
    'anil': 'अनिल',
    'nitin': 'नितीन',
    'mangesh': 'मंगेश',
    'kiran': 'किरण',
    'swapnil': 'स्वप्निल',
    'rohit': 'रोहित',
    'nilesh': 'निलेश',
    'satish': 'सतीश',
    'umesh': 'उमेश',
    'tushar': 'तुषार',
    'mayur': 'मयूर',
    'shubham': 'शुभम',
    'sourabh': 'सौरभ',
    'saurabh': 'सौरभ',
    'suraj': 'सूरज',
    'abhishek': 'अभिषेक',
    'omkar': 'ओंकार',
    'sanket': 'संकेत',
    'ruturaj': 'ऋतुराज',
    'shrikant': 'श्रीकांत',
    'shridhar': 'श्रीधर',
    'dnyaneshwar': 'ज्ञानेश्वर',
    'tukaram': 'तुकाराम',
    'pandurang': 'पांडुरंग',
    'vitthal': 'विठ्ठल',
    'ashok': 'अशोक',
    'balasaheb': 'बाळासाहेब',
    'dattatray': 'दत्तात्रय',
    'dattatraya': 'दत्तात्रय',
    'gorakh': 'गोरख',
    'haribhau': 'हरिभाऊ',
    'maruti': 'मारुती',
    'namdeo': 'नामदेव',
    'namdev': 'नामदेव',
    'nivrutti': 'निवृत्ती',
    'popat': 'पोपट',
    'ramdas': 'रामदास',
    'sakharam': 'सखाराम',
    'shankar': 'शंकर',
    'shivaji': 'शिवाजी',
    'uttam': 'उत्तम',
    'vasant': 'वसंत',
    'vithoba': 'विठोबा',
    'yashwant': 'यशवंत',
    'saideep': 'साईदीप',

    // --- First Names (Female) ---
    'dhanashri': 'धनश्री',
    'dhanashree': 'धनश्री',
    'priyanka': 'प्रियंका',
    'pooja': 'पूजा',
    'puja': 'पूजा',
    'sneha': 'स्नेहा',
    'sunita': 'सुनिता',
    'anita': 'अनिता',
    'swati': 'स्वाती',
    'seema': 'सीमा',
    'kavita': 'कविता',
    'rohini': 'रोहिणी',
    'rupali': 'रूपाली',
    'monika': 'मोनिका',
    'deepali': 'दीपाली',
    'dipali': 'दीपाली',
    'manisha': 'मनीषा',
    'suvarna': 'सुवर्णा',
    'shital': 'शीतल',
    'sheetal': 'शीतल',
    'pranita': 'प्रणिता',
    'pratibha': 'प्रतिभा',
    'ashwini': 'अश्विनी',
    'jyoti': 'ज्योती',
    'sangita': 'संगीता',
    'sangeeta': 'संगीता',
    'sarika': 'सारिका',
    'shobha': 'शोभा',
    'vandana': 'वंदना',
    'varsha': 'वर्षा',
    'vijaya': 'विजया',
    'archana': 'अर्चना',
    'jayashree': 'जयश्री',
    'jayshri': 'जयश्री',
    'meena': 'मीना',
    'mina': 'मीना',
    'neeta': 'नीता',
    'nita': 'नीता',
    'rekha': 'रेखा',
    'surekha': 'सुरेखा',
    'radha': 'राधा',
    'geeta': 'गीता',
    'gita': 'गीता',
    'lata': 'लता',
    'vidya': 'विद्या',
    'pramila': 'प्रमिला',
    'ujjwala': 'उज्ज्वला',
    'yogita': 'योगिता',
    'savita': 'सविता',
    'komal': 'कोमल',
    'renuka': 'रेणुका',
    'poonam': 'पूनम',
    'madhuri': 'माधुरी',
    'pallavi': 'पल्लवी',
    'chetana': 'चेतना',
    'anjali': 'अंजली',
    'arti': 'आरती',
    'aarti': 'आरती',
    'sonal': 'सोनल',
    'sonali': 'सोनाली',
    'tejaswini': 'तेजस्विनी',
    'harshada': 'हर्षदा',
    'namrata': 'नम्रता',
    'shilpa': 'शिल्पा',
    'chhaya': 'छाया',
    'sandhya': 'संध्या',
    'bharti': 'भारती',
    'alka': 'अलका',
    'kalpana': 'कल्पना',

    // --- Surnames ---
    'hase': 'हसे',
    'pawase': 'पावसे',
    'pavase': 'पावसे',
    'bhalke': 'भालके',
    'bhakle': 'भाकले',
    'bhake': 'भाके',
    'dhumal': 'धुमाळ',
    'wale': 'वाले',
    'vale': 'वाले',
    'dhawale': 'ढवळे',
    'dhavale': 'ढवळे',
    'patil': 'पाटील',
    'shinde': 'शिंदे',
    'pawar': 'पवार',
    'jadhav': 'जाधव',
    'deshmukh': 'देशमुख',
    'kulkarni': 'कुलकर्णी',
    'joshi': 'जोशी',
    'more': 'मोरे',
    'kadam': 'कदम',
    'gaikwad': 'गायकवाड',
    'gayakwad': 'गायकवाड',
    'chavan': 'चव्हाण',
    'sawant': 'सावंत',
    'thorat': 'थोरात',
    'ghorpade': 'घोरपडे',
    'jagtap': 'जगताप',
    'sonawane': 'सोनवणे',
    'kale': 'काळे',
    'wagh': 'वाघ',
    'raut': 'राऊत',
    'bhosale': 'भोसले',
    'bhosle': 'भोसले',
    'salunkhe': 'साळुंखे',
    'salunke': 'साळुंखे',
    'ghadge': 'घाडगे',
    'mohite': 'मोहिते',
    'shelke': 'शेळके',
    'mane': 'माने',
    'tambade': 'तांबडे',
    'tambde': 'तांबडे',
    'khade': 'खाडे',
    'kolhe': 'कोल्हे',
    'ghule': 'घुले',
    'navale': 'नवले',
    'kute': 'कुटे',
    'shirke': 'शिर्के',
    'borude': 'बोरुडे',
    'gadakh': 'गडाख',
    'autade': 'औताडे',
    'falke': 'फाळके',
    'zaware': 'झावरे',
    'chaugule': 'चौगुले',
    'chougule': 'चौगुले',
    'khot': 'खोत',
    'nagare': 'नगरे',
    'palve': 'पालवे',
    'doke': 'डोके',
    'ghodke': 'घोडके',
    'bodakhe': 'बोडखे',
    'pote': 'पोटे',
    'darade': 'दराडे',
    'sanap': 'सानप',
    'avhad': 'आव्हाड',
    'awhad': 'आव्हाड',
    'vidhate': 'विधाते',
    'bhandari': 'भंडारी',
    'gawade': 'गवडे',
    'gavade': 'गवडे',
    'mahajan': 'महाजन',
    'bhat': 'भट',
    'bhide': 'भिडे',
    'gokhale': 'गोखले',
    'apte': 'आपटे',
    'paranjape': 'परांजपे',
    'kelkar': 'केळकर',
    'ranade': 'रानडे',
    'oak': 'ओक',
    'pendse': 'पेंडसे',
    'godbole': 'गोडबोले',
    'chitale': 'चितळे',
    'agarkar': 'आगरकर',
    'abhyankar': 'अभ्यंकर',
    'phadke': 'फडके',
    'limaye': 'लिमये',
    'lele': 'लेले',
    'kanitkar': 'कानिटकर',
    'sathe': 'साठे',
    'marathe': 'मराठे',
    'tamboli': 'तांबोळी',
    'sutar': 'सुतार',
    'lohar': 'लोहार',
    'kumbhar': 'कुंभार',
    'mali': 'माळी',
    'navgire': 'नवगिरे',
    'khandagale': 'खंडागळे',
    'kamble': 'कांबळे',
    'gorde': 'गोरडे',
    'korde': 'कोरडे',
    'bhalerao': 'भालेराव',
    'gaurav': 'गौरव',
    'khairnar': 'खैरनार',
    'nikam': 'निकम',
    'chaudhari': 'चौधरी',
    'choudhary': 'चौधरी',
    'dube': 'दुबे',
    'singh': 'सिंग',
    'sharma': 'शर्मा',
    'verma': 'वर्मा',
    'gupta': 'गुप्ता',
    'pandey': 'पांडे',
    'mishra': 'मिश्रा',
    'yadav': 'यादव',
    'shah': 'शाह',
    'mehta': 'मेहता',
  };
}
