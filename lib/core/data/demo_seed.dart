import 'package:flutter/material.dart';

import '../models/artist_story.dart';
import '../models/download_task.dart';
import '../models/festival_event.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../models/station.dart';

class DemoSeed {
  const DemoSeed._();

  static final List<Song> songs = <Song>[
    Song(
      id: 'kesariya',
      title: 'Kesariya Reimagined',
      artist: 'Arijit Singh',
      album: 'Brahmastra Nights',
      language: 'Hindi',
      genre: 'Bollywood',
      mood: 'Romantic',
      duration: const Duration(minutes: 4, seconds: 28),
      palette: const <Color>[Color(0xFFFF7A00), Color(0xFFFFB347)],
      lyrics: const <LyricLine>[
        LyricLine(
          time: Duration(seconds: 0),
          text: 'Rang tera chadhe dil pe dheere',
        ),
        LyricLine(
          time: Duration(seconds: 20),
          text: 'Kesariya tera ishq hai piya',
          translation: 'Your love glows saffron around me.',
        ),
        LyricLine(
          time: Duration(seconds: 47),
          text: 'Har saans mein tera noor hai piya',
          translation: 'Every breath carries your light.',
        ),
      ],
    ),
    Song(
      id: 'channa',
      title: 'Channa Mereya Mehfil',
      artist: 'Arijit Singh',
      album: 'Ae Dil Sessions',
      language: 'Hindi',
      genre: 'Ghazal Pop',
      mood: 'Soulful',
      duration: const Duration(minutes: 4, seconds: 49),
      palette: const <Color>[Color(0xFF8C4B2D), Color(0xFFDEB887)],
      lyrics: const <LyricLine>[
        LyricLine(
          time: Duration(seconds: 0),
          text: 'Accha chalta hoon mehfil se',
        ),
        LyricLine(
          time: Duration(seconds: 31),
          text: 'Channa mereya mereya',
          translation: 'My moonlight, my companion.',
        ),
        LyricLine(
          time: Duration(seconds: 64),
          text: 'Door rehkar bhi paas tu hai',
        ),
      ],
    ),
    Song(
      id: 'namo',
      title: 'Namo Namo Bhakti Mix',
      artist: 'Amit Trivedi',
      album: 'Shiv Arpan',
      language: 'Hindi',
      genre: 'Bhakti',
      mood: 'Devotional',
      duration: const Duration(minutes: 5, seconds: 2),
      palette: const <Color>[Color(0xFFB55400), Color(0xFFFFD56A)],
      lyrics: const <LyricLine>[
        LyricLine(time: Duration(seconds: 0), text: 'Jai ho jai ho Shankara'),
        LyricLine(
          time: Duration(seconds: 25),
          text: 'Namo namo ji Shankara',
          translation: 'Salutations to the divine Shankara.',
        ),
        LyricLine(time: Duration(seconds: 52), text: 'Tera naam hi sahara'),
      ],
    ),
    Song(
      id: 'tere-bina',
      title: 'Tere Bina Monsoon Cut',
      artist: 'A.R. Rahman',
      album: 'Rain Window',
      language: 'Hindi',
      genre: 'Soundtrack',
      mood: 'Rain',
      duration: const Duration(minutes: 3, seconds: 56),
      palette: const <Color>[Color(0xFF1E5E7D), Color(0xFF7DC9E8)],
      lyrics: const <LyricLine>[
        LyricLine(
          time: Duration(seconds: 0),
          text: 'Tere bina beswaadi ratiyan',
        ),
        LyricLine(
          time: Duration(seconds: 28),
          text: 'Saawan aaye, tu na aaye',
          translation: 'Monsoon arrives, but you do not.',
        ),
        LyricLine(
          time: Duration(seconds: 58),
          text: 'Khidki pe baarish gungunaaye',
        ),
      ],
    ),
    Song(
      id: 'vaathi',
      title: 'Vaathi Coming Brass',
      artist: 'Anirudh Ravichander',
      album: 'South Heat',
      language: 'Tamil',
      genre: 'Mass',
      mood: 'Party',
      duration: const Duration(minutes: 3, seconds: 44),
      palette: const <Color>[Color(0xFF7A2D00), Color(0xFFFFA600)],
      lyrics: const <LyricLine>[
        LyricLine(time: Duration(seconds: 0), text: 'Vaathi coming, othu'),
        LyricLine(
          time: Duration(seconds: 22),
          text: 'Therikka vidalaama',
          translation: 'Shall we let the floor explode?',
        ),
        LyricLine(time: Duration(seconds: 49), text: 'Beat-u mela step-u podu'),
      ],
    ),
    Song(
      id: 'rowdy-baby',
      title: 'Rowdy Baby Sunset',
      artist: 'Dhanush',
      album: 'Beach Parade',
      language: 'Tamil',
      genre: 'Dance',
      mood: 'Feel Good',
      duration: const Duration(minutes: 4, seconds: 6),
      palette: const <Color>[Color(0xFFE4554B), Color(0xFFFFC857)],
      lyrics: const <LyricLine>[
        LyricLine(time: Duration(seconds: 0), text: 'Hey en goli sodaave'),
        LyricLine(
          time: Duration(seconds: 26),
          text: 'Rowdy baby, rowdy baby',
          translation: 'My rowdy darling, keep dancing.',
        ),
        LyricLine(time: Duration(seconds: 56), text: 'Suryan pola sirippu'),
      ],
    ),
    Song(
      id: 'butta-bomma',
      title: 'Butta Bomma Drive',
      artist: 'Armaan Malik',
      album: 'Telugu Cruise',
      language: 'Telugu',
      genre: 'Romantic',
      mood: 'Drive',
      duration: const Duration(minutes: 3, seconds: 25),
      palette: const <Color>[Color(0xFF6A5ACD), Color(0xFFFFB347)],
      lyrics: const <LyricLine>[
        LyricLine(
          time: Duration(seconds: 0),
          text: 'Inthakanna manchi polikedi',
        ),
        LyricLine(
          time: Duration(seconds: 24),
          text: 'Butta bomma butta bomma',
          translation: 'You are my little jewel.',
        ),
        LyricLine(
          time: Duration(seconds: 51),
          text: 'Cheyyi pattukoni vachesaa',
        ),
      ],
    ),
    Song(
      id: 'pasoori',
      title: 'Pasoori Sufi Club',
      artist: 'Ali Sethi & Shae Gill',
      album: 'Sufi Transit',
      language: 'Punjabi',
      genre: 'Sufi',
      mood: 'Ecstatic',
      duration: const Duration(minutes: 4, seconds: 10),
      palette: const <Color>[Color(0xFF155E63), Color(0xFFE9C46A)],
      lyrics: const <LyricLine>[
        LyricLine(time: Duration(seconds: 0), text: 'Aa chalein leke tujhe'),
        LyricLine(
          time: Duration(seconds: 29),
          text: 'Pasoori nu jaane na',
          translation: 'The ache inside cannot be ignored.',
        ),
        LyricLine(time: Duration(seconds: 60), text: 'Nachde ne dil de saaz'),
      ],
    ),
    Song(
      id: 'raatan',
      title: 'Raatan Lambiyan Acoustic',
      artist: 'Jubin Nautiyal',
      album: 'Shaam Ke Rang',
      language: 'Hindi',
      genre: 'Acoustic',
      mood: 'Romantic',
      duration: const Duration(minutes: 4, seconds: 14),
      palette: const <Color>[Color(0xFF5D4037), Color(0xFFF4A261)],
      lyrics: const <LyricLine>[
        LyricLine(
          time: Duration(seconds: 0),
          text: 'Teri meri gallan hogi mashhoor',
        ),
        LyricLine(
          time: Duration(seconds: 24),
          text: 'Raatan lambiyan lambiyan re',
          translation: 'These nights stretch endlessly in love.',
        ),
        LyricLine(
          time: Duration(seconds: 56),
          text: 'Sajna tere bina dil adhoora',
        ),
      ],
    ),
    Song(
      id: 'malare',
      title: 'Malare Morning',
      artist: 'Vijay Yesudas',
      album: 'Kerala Dawn',
      language: 'Malayalam',
      genre: 'Melody',
      mood: 'Morning',
      duration: const Duration(minutes: 5, seconds: 1),
      palette: const <Color>[Color(0xFF4CAF50), Color(0xFFC5E1A5)],
      lyrics: const <LyricLine>[
        LyricLine(
          time: Duration(seconds: 0),
          text: 'Malare ninne kaanathirunnal',
        ),
        LyricLine(
          time: Duration(seconds: 33),
          text: 'Manam thanne marannu pokum',
          translation: 'My heart forgets itself without you.',
        ),
        LyricLine(time: Duration(seconds: 68), text: 'Mazha pole nee vannu'),
      ],
    ),
    Song(
      id: 'zingaat',
      title: 'Zingaat Wedding Dhol',
      artist: 'Ajay-Atul',
      album: 'Shaadi Heat',
      language: 'Marathi',
      genre: 'Wedding',
      mood: 'Celebration',
      duration: const Duration(minutes: 3, seconds: 17),
      palette: const <Color>[Color(0xFFD1495B), Color(0xFFF4D35E)],
      lyrics: const <LyricLine>[
        LyricLine(time: Duration(seconds: 0), text: 'Zing zing zing zingaat'),
        LyricLine(
          time: Duration(seconds: 18),
          text: 'Mandap bharla naachane',
          translation: 'The whole mandap is dancing.',
        ),
        LyricLine(time: Duration(seconds: 42), text: 'Dhol vajto man rangto'),
      ],
    ),
    Song(
      id: 'dholna',
      title: 'Dholna Bhangra Boost',
      artist: 'Diljit Dosanjh',
      album: 'Punjab Nights',
      language: 'Punjabi',
      genre: 'Bhangra',
      mood: 'Workout',
      duration: const Duration(minutes: 3, seconds: 38),
      palette: const <Color>[Color(0xFF9E2A2B), Color(0xFFF77F00)],
      lyrics: const <LyricLine>[
        LyricLine(time: Duration(seconds: 0), text: 'Dholna ve dholna'),
        LyricLine(
          time: Duration(seconds: 21),
          text: 'Nachdi jawaani rave',
          translation: 'The youthful energy keeps dancing.',
        ),
        LyricLine(
          time: Duration(seconds: 48),
          text: 'Bass te dhol vajje zor naal',
        ),
      ],
    ),
    Song(
      id: 'bhromor',
      title: 'Bhromor Koiyo Rain Edit',
      artist: 'Anupam Roy',
      album: 'Kolkata Monsoon',
      language: 'Bengali',
      genre: 'Indie',
      mood: 'Rain',
      duration: const Duration(minutes: 4, seconds: 19),
      palette: const <Color>[Color(0xFF264653), Color(0xFF2A9D8F)],
      lyrics: const <LyricLine>[
        LyricLine(time: Duration(seconds: 0), text: 'Bhromor koiyo giya'),
        LyricLine(
          time: Duration(seconds: 25),
          text: 'Mon amar aaj meghla',
          translation: 'My heart wears a sky full of clouds.',
        ),
        LyricLine(time: Duration(seconds: 55), text: 'Brishti pore shei shure'),
      ],
    ),
    Song(
      id: 'garba',
      title: 'Garba Glow',
      artist: 'Falguni Pathak',
      album: 'Navratri Nights',
      language: 'Gujarati',
      genre: 'Folk Pop',
      mood: 'Festival',
      duration: const Duration(minutes: 3, seconds: 33),
      palette: const <Color>[Color(0xFFE76F51), Color(0xFFFFC857)],
      lyrics: const <LyricLine>[
        LyricLine(time: Duration(seconds: 0), text: 'Taali padse dhoom machse'),
        LyricLine(
          time: Duration(seconds: 21),
          text: 'Rangilo garbo ramva aavo',
          translation: 'Come join the colorful garba circle.',
        ),
        LyricLine(time: Duration(seconds: 46), text: 'Dandiya ni raat chamke'),
      ],
    ),
    Song(
      id: 'shiv-tandav',
      title: 'Shiv Tandav Live',
      artist: 'Shankar Mahadevan',
      album: 'Mahadev Sessions',
      language: 'Hindi',
      genre: 'Classical',
      mood: 'Power',
      duration: const Duration(minutes: 5, seconds: 34),
      palette: const <Color>[Color(0xFF283593), Color(0xFF90CAF9)],
      lyrics: const <LyricLine>[
        LyricLine(
          time: Duration(seconds: 0),
          text: 'Jatatavigalajjala pravahapavitasthale',
        ),
        LyricLine(
          time: Duration(seconds: 32),
          text: 'Damad damad damad daman ninada',
          translation: 'The cosmic drums thunder in waves.',
        ),
        LyricLine(time: Duration(seconds: 68), text: 'Har Har Mahadev ghoome'),
      ],
    ),
  ];

  static final List<Playlist> playlists = <Playlist>[
    Playlist(
      id: 'carvaan-gold',
      title: 'Carvaan Gold Hindi',
      subtitle: 'Evergreen warmth, remastered for long desktop sessions.',
      songs: <Song>[songs[0], songs[1], songs[8], songs[3]],
      curator: 'PULSE',
      gradient: const <Color>[Color(0xFFFF8A00), Color(0xFFFFD166)],
      members: const <String>['Asha', 'Vikram', 'Noor'],
    ),
    Playlist(
      id: 'holi-vibes',
      title: 'Holi Vibes 2026',
      subtitle: 'Colour-soaked party cuts and festival rush.',
      songs: <Song>[songs[4], songs[5], songs[10], songs[13]],
      curator: 'AI Chaska',
      gradient: const <Color>[Color(0xFFE44B8D), Color(0xFF834DFF)],
      members: const <String>['Aanya', 'Kabir', 'Meher'],
    ),
    Playlist(
      id: 'rainy-ghazal',
      title: 'Rainy Ghazal Night',
      subtitle: 'Late-night mehfil textures with soft rain ambience.',
      songs: <Song>[songs[1], songs[3], songs[8], songs[12]],
      curator: 'AI Chaska',
      gradient: const <Color>[Color(0xFF1E5E7D), Color(0xFF7DC9E8)],
      members: const <String>['Rhea', 'Farhan'],
    ),
    Playlist(
      id: 'punjabi-workout',
      title: 'Punjabi Workout',
      subtitle: 'High-BPM dhol, bass, and cardio-ready hooks.',
      songs: <Song>[songs[7], songs[11], songs[4], songs[10]],
      curator: 'Desi Gym Club',
      gradient: const <Color>[Color(0xFF9E2A2B), Color(0xFFF77F00)],
      members: const <String>['Guri', 'Simran', 'Aarav'],
    ),
    Playlist(
      id: 'bhakti-sunrise',
      title: 'Bhakti Sunrise',
      subtitle: 'Devotional calm for early mornings and temple time.',
      songs: <Song>[songs[2], songs[14], songs[9]],
      curator: 'Festival Hub',
      gradient: const <Color>[Color(0xFFB55400), Color(0xFFFFE082)],
      members: const <String>['Naina', 'Rudra'],
    ),
  ];

  static final List<Station> stations = <Station>[
    Station(
      id: 'artistes',
      title: 'Artistes',
      subtitle: 'Arijit, Lata, Rahman, and beyond',
      category: 'Carvaan',
      listeners: 12048,
      palette: const <Color>[Color(0xFFFF8A00), Color(0xFF6D3B10)],
      votes: 912,
    ),
    Station(
      id: 'moods',
      title: 'Moods',
      subtitle: 'From rainy nostalgia to shaadi power',
      category: 'Mood',
      listeners: 9824,
      palette: const <Color>[Color(0xFF4A4E69), Color(0xFFE7C98A)],
      votes: 641,
    ),
    Station(
      id: 'bhakti',
      title: 'Bhakti',
      subtitle: 'Aarti, stuti, shabad, and calm focus',
      category: 'Devotional',
      listeners: 8042,
      palette: const <Color>[Color(0xFF9C5A12), Color(0xFFFFBE5C)],
      votes: 503,
    ),
    Station(
      id: 'regional',
      title: 'Regional',
      subtitle: 'Tamil, Telugu, Bengali, Marathi, and more',
      category: 'Regional',
      listeners: 7345,
      palette: const <Color>[Color(0xFF26708D), Color(0xFF7CD5F5)],
      votes: 489,
    ),
    Station(
      id: 'sufi',
      title: 'Sufi & Qawwali',
      subtitle: 'Dargah spirit, expansive reverb, soul',
      category: 'Sufi',
      listeners: 6120,
      palette: const <Color>[Color(0xFF2B5B6F), Color(0xFFB8A46C)],
      votes: 455,
    ),
    Station(
      id: 'wedding',
      title: 'Wedding Specials',
      subtitle: 'Mehendi, sangeet, baraat, and reception',
      category: 'Event',
      listeners: 15110,
      palette: const <Color>[Color(0xFFD32F2F), Color(0xFFFFC857)],
      votes: 1021,
    ),
  ];

  static final List<DownloadTask> downloadTasks = <DownloadTask>[
    const DownloadTask(
      id: 'd1',
      title: 'Carvaan Gold Hindi',
      subtitle: 'Batch download - 18 tracks',
      progress: 0.74,
      status: DownloadStatus.downloading,
      format: '.m4a',
      syncedLyricsEmbedded: true,
    ),
    const DownloadTask(
      id: 'd2',
      title: 'Shiv Tandav Live',
      subtitle: 'Offline ready - 320 kbps Opus',
      progress: 1,
      status: DownloadStatus.completed,
      format: '.opus',
      syncedLyricsEmbedded: true,
    ),
    const DownloadTask(
      id: 'd3',
      title: 'Predictive cache - Next 10 songs',
      subtitle: 'Travel mode warm cache',
      progress: 0.4,
      status: DownloadStatus.cached,
      format: '.cache',
      syncedLyricsEmbedded: false,
    ),
  ];

  static const List<ArtistStory> artistStories = <ArtistStory>[
    ArtistStory(
      artist: 'Arijit Singh',
      headline:
          'The velvet bridge between modern heartbreak and classic melody.',
      storyEn:
          'Arijit\'s phrasing often leans intimate first, then blooms into wide cinematic peaks. That makes his catalogue ideal for desktop listening with gentle crossfade.',
      storyHi:
          'अरिजीत की गायकी पहले बेहद निजी लगती है, फिर अचानक बड़ी सिनेमैटिक ऊंचाई पकड़ लेती है। इसी वजह से उनकी प्लेलिस्ट लंबी सुनवाई में शानदार लगती है।',
      facts: <String>[
        'Best paired with Rainy Ghazal and Carvaan Gold presets.',
        'Crossfade sweet spot: 4 seconds.',
        'Works beautifully in low-light festival themes.',
      ],
    ),
    ArtistStory(
      artist: 'A.R. Rahman',
      headline: 'Texture-rich arrangements that reward spatial listening.',
      storyEn:
          'Rahman productions shine when layers breathe. Even a desktop prototype benefits from wider soundstage cues and silence-aware transitions around his intros.',
      storyHi:
          'रहमान के अरेंजमेंट तब खुलते हैं जब हर लेयर को सांस लेने की जगह मिले। इसलिए स्पेशल ऑडियो और साइलेंस-अवेयर ट्रांजिशन उनके संगीत पर खूब जंचते हैं।',
      facts: <String>[
        'Ideal for spatial audio demos.',
        'Monsoon theme pack complements his ambient palette.',
        'Use the Sufi Echo preset for vocal air.',
      ],
    ),
    ArtistStory(
      artist: 'Diljit Dosanjh',
      headline: 'Festival energy, Punjab punch, and arena-ready swagger.',
      storyEn:
          'Diljit tracks are easy anchors for workout queues and user-voted radio. Punchy percussion also makes them perfect candidates for the Bhangra Boost EQ preset.',
      storyHi:
          'दिलजीत के ट्रैक वर्कआउट कतारों और यूजर-वोटेड रेडियो के लिए शानदार एंकर बनते हैं। दमदार परकशन के कारण भांगड़ा बूस्ट EQ प्रीसेट उन पर खूब जमता है।',
      facts: <String>[
        'Best for community radio votes.',
        'Pairs with Punjabi Workout and Wedding Specials.',
        'Peak energy after 7 PM playlists.',
      ],
    ),
  ];

  static List<FestivalEvent> buildFestivals(DateTime now) {
    return <FestivalEvent>[
      FestivalEvent(
        name: 'Baisakhi',
        date: now.add(const Duration(days: 14)),
        tagline: 'Harvest gold, dhol energy, and open-sky Punjabi warmth.',
        playlistTitle: 'Baisakhi Dhol Parade',
        palette: const <Color>[Color(0xFFF77F00), Color(0xFFFFD166)],
      ),
      FestivalEvent(
        name: 'Eid Mehfil',
        date: now.add(const Duration(days: 21)),
        tagline: 'Soft qawwalis, sufi glow, and moonlit listening.',
        playlistTitle: 'Eid Sufi Glow',
        palette: const <Color>[Color(0xFF2B5B6F), Color(0xFFB8A46C)],
      ),
      FestivalEvent(
        name: 'Monsoon Season',
        date: now.add(const Duration(days: 64)),
        tagline: 'Rain textures, chai nostalgia, and window-seat ghazals.',
        playlistTitle: 'Monsoon Mehfil',
        palette: const <Color>[Color(0xFF26708D), Color(0xFF7CD5F5)],
      ),
      FestivalEvent(
        name: 'Navratri',
        date: now.add(const Duration(days: 189)),
        tagline: 'Dandiya circles, late-night garba, and bright reds.',
        playlistTitle: 'Garba Glow',
        palette: const <Color>[Color(0xFFD32F2F), Color(0xFFFFC857)],
      ),
    ];
  }
}
