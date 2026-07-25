class AfterSalahDua {
  final int id;
  final String? arabicOnly;
  final String transliteration;
  final String translation;
  final String? commonName;
  final String? notes;
  final String repetition;
  final String source;

  const AfterSalahDua({
    required this.id,
    this.arabicOnly,
    required this.transliteration,
    required this.translation,
    this.commonName,
    this.notes,
    required this.repetition,
    required this.source,
  });

  String get arabic => arabicOnly ?? '';
  bool get isQuranRef => notes?.contains("Qur'anic text") ?? false;
}

class AfterSalahAdhkarData {
  static const source = 'Hisnul Muslim (Fortress of the Muslim) — Sa\'id bin Ali Al-Qahtani';
  static const chapter = 'Remembrance after the prayer';
  static const chapterNumber = 18;
  static const duaRange = '58-68 (individual dhikr split out separately)';

  static const List<AfterSalahDua> duas = [
    AfterSalahDua(
      id: 0,
      arabicOnly: 'أَسْتَغْفِرُ اللَّهَ',
      transliteration: 'Astaghfirullaah.',
      translation: 'I seek the forgiveness of Allaah.',
      commonName: 'Istighfar after prayer',
      repetition: 'Three times, immediately after salaam',
      source: 'Muslim',
    ),
    AfterSalahDua(
      id: 1,
      arabicOnly: 'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
      transliteration: 'Allaahumma antas-salaam, wa minkas-salaam, tabaarakta yaa dhal-jalaali wal-ikraam.',
      translation: 'O Allaah, You are Peace and from You comes peace, blessed are You, O Owner of majesty and honour.',
      repetition: 'Once, after the three istighfars',
      source: 'Muslim',
    ),
    AfterSalahDua(
      id: 2,
      arabicOnly: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، اللَّهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ',
      transliteration: 'Laa ilaaha illallaahu wahdahu laa shareeka lah, lahul-mulku wa lahul-hamdu wa Huwa \'alaa kulli shay\'in Qadeer. Allaahumma laa maani\'a limaa a\'tayta, wa laa mu\'tiya limaa mana\'ta, wa laa yanfa\'u dhal-jaddi minkal-jadd.',
      translation: 'None has the right to be worshipped except Allaah, alone, without partner, to Him belongs all sovereignty and praise, and He is over all things omnipotent. O Allaah, none can withhold what You give, and none can give what You withhold, and the might of the mighty person cannot benefit him against You.',
      repetition: 'Once, after every obligatory prayer',
      source: 'al-Bukhari, Muslim',
    ),
    AfterSalahDua(
      id: 3,
      arabicOnly: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ، لَا إِلَهَ إِلَّا اللَّهُ، وَلَا نَعْبُدُ إِلَّا إِيَّاهُ، لَهُ النِّعْمَةُ وَلَهُ الْفَضْلُ وَلَهُ الثَّنَاءُ الْحَسَنُ، لَا إِلَهَ إِلَّا اللَّهُ مُخْلِصِينَ لَهُ الدِّينَ وَلَوْ كَرِهَ الْكَافِرُونَ',
      transliteration: 'Laa ilaaha illallaahu wahdahu laa shareeka lah, lahul-mulku wa lahul-hamdu wa Huwa \'alaa kulli shay\'in Qadeer, laa hawla wa laa quwwata illaa billaah, laa ilaaha illallaah, wa laa na\'budu illaa iyyaah, lahun-ni\'matu wa lahul-fadlu wa lahuth-thanaa\'ul-hasan, laa ilaaha illallaahu mukhliseena lahud-deena wa law karihal-kaafiroon.',
      translation: 'None has the right to be worshipped except Allaah, alone, without partner, to Him belongs all sovereignty and praise, and He is over all things omnipotent. There is no power and no strength except by Allaah. None has the right to be worshipped except Allaah, and we worship none but Him. His is the favour and grace, and to Him belongs the excellent praise. None has the right to be worshipped except Allaah, sincere and faithful is our religion to Him, even though the disbelievers dislike it.',
      repetition: 'Once, after Fajr and Maghrib',
      source: 'Ahmad',
    ),
    AfterSalahDua(
      id: 4,
      arabicOnly: 'سُبْحَانَ اللَّهِ',
      transliteration: 'Subhaanallaah.',
      translation: 'How perfect Allaah is.',
      commonName: 'Tasbeeh after prayer (1 of 4)',
      notes: 'First of four dhikr said after every obligatory prayer; whoever recites the full set will have sins forgiven even if like the foam of the sea',
      repetition: '33 times, once after every obligatory prayer',
      source: 'Muslim',
    ),
    AfterSalahDua(
      id: 5,
      arabicOnly: 'الْحَمْدُ لِلَّهِ',
      transliteration: 'Alhamdulillaah.',
      translation: 'All praise is for Allaah.',
      commonName: 'Tasbeeh after prayer (2 of 4)',
      repetition: '33 times, once after every obligatory prayer',
      source: 'Muslim',
    ),
    AfterSalahDua(
      id: 6,
      arabicOnly: 'اللَّهُ أَكْبَرُ',
      transliteration: 'Allaahu akbar.',
      translation: 'Allaah is the greatest.',
      commonName: 'Tasbeeh after prayer (3 of 4)',
      repetition: '33 times, once after every obligatory prayer',
      source: 'Muslim',
    ),
    AfterSalahDua(
      id: 7,
      arabicOnly: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      transliteration: 'Laa ilaaha illallaahu wahdahu laa shareeka lah, lahul-mulku wa lahul-hamdu wa Huwa \'alaa kulli shay\'in Qadeer.',
      translation: 'None has the right to be worshipped except Allaah, alone, without partner, to Him belongs all sovereignty and praise, and He is over all things omnipotent.',
      commonName: 'Tasbeeh after prayer (4 of 4 — completes the hundred)',
      repetition: 'Once, completing the set of one hundred',
      source: 'Muslim',
    ),
    AfterSalahDua(
      id: 8,
      arabicOnly: 'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
      transliteration: 'Qul huwa Allaahu ahad. Allaahus-samad. Lam yalid wa lam yoolad. Wa lam yakun lahu kufuwan ahad.',
      translation: 'Say, "He is Allah, the One. Allah, the Eternal Refuge. He neither begets nor is born. Nor is there to Him any equivalent."',
      commonName: 'Surah Al-Ikhlas (The Sincerity)',
      notes: 'Recited once after each prayer, and three times after Fajr and Maghrib',
      repetition: 'Once (three times after Fajr/Maghrib)',
      source: 'Quran 112',
    ),
    AfterSalahDua(
      id: 9,
      arabicOnly: 'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِن شَرِّ مَا خَلَقَ ۝ وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ',
      transliteration: 'Qul a\'oodhu birabbil-falaq. Min sharri maa khalaq. Wa min sharri ghasiqin idha waqab. Wa min sharrin-naffaathaati fil-\'uqad. Wa min sharri hasidin idha hasad.',
      translation: 'Say, "I seek refuge in the Lord of daybreak. From the evil of that which He created. And from the evil of darkness when it settles. And from the evil of the blowers in knots. And from the evil of an envier when he envies."',
      commonName: 'Surah Al-Falaq (The Daybreak)',
      notes: 'Recited once after each prayer, and three times after Fajr and Maghrib',
      repetition: 'Once (3times after Fajr/Maghrib)',
      source: 'Quran 113',
    ),
    AfterSalahDua(
      id: 10,
      arabicOnly: 'قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَٰهِ النَّاسِ ۝ مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ',
      transliteration: 'Qul a\'oodhu birabbin-naas. Malikin-naas. Ilaahin-naas. Min sharril-waswaasil-khannaas. Alladhee yuwaswisu fee sudoorin-naas. Minal-jinnati wan-naas.',
      translation: 'Say, "I seek refuge in the Lord of mankind. The Sovereign of mankind. The God of mankind. From the evil of the retreating whisperer. Who whispers in the breasts of mankind. From among the jinn and mankind."',
      commonName: 'Surah An-Nas (The Mankind)',
      notes: 'Recited once after each prayer, and three times after Fajr and Maghrib',
      repetition: 'Once (3 times after Fajr/Maghrib)',
      source: 'Quran 114',
    ),
    AfterSalahDua(
      id: 11,
      arabicOnly: 'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
      transliteration: 'Allaahumma a\'innee \'alaa dhikrika wa shukrika wa husni \'ibaadatik.',
      translation: 'O Allaah, help me to remember You, to thank You, and to worship You in the best of manners.',
      notes: 'The Prophet took the hand of Mu\'aadh and said this, instructing him to never omit it after every prayer',
      repetition: 'Once, after every prayer',
      source: 'Abu Dawud, an-Nasa\'i',
    ),
    AfterSalahDua(
      id: 12,
      arabicOnly: 'اللَّهُمَّ رَبَّ هَذِهِ الدَّعْوَةِ التَّامَّةِ، وَالصَّلَاةِ الْقَائِمَةِ، آتِ مُحَمَّدًا الْوَسِيلَةَ وَالْفَضِيلَةَ، وَابْعَثْهُ مَقَامًا مَحْمُودًا الَّذِي وَعَدْتَهُ',
      transliteration: 'Allaahumma Rabba haadhihid-da\'watit-taammah, was-salaatil-qaa\'imah, aati Muhammadanil-waseelata wal-fadeelah, wab\'ath-hu maqaamam mahmoodanil-ladhee wa\'adtah.',
      translation: 'O Allaah, Lord of this perfect call and established prayer, grant Muhammad the intercession and favour, and raise him to the honoured station which You have promised him.',
      notes: 'Recited after the adhan, but also transmitted among after-prayer remembrances in some narrations',
      repetition: 'Once',
      source: 'al-Bukhari',
    ),
    AfterSalahDua(
      id: 13,
      arabicOnly: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا',
      transliteration: 'Allaahumma innee as\'aluka \'ilman naafi\'an, wa rizqan tayyibaa, wa \'amalan mutaqabbalaa.',
      translation: 'O Allaah, I ask You for beneficial knowledge, good provision, and acceptable deeds.',
      notes: 'Recited especially after the Fajr prayer',
      repetition: 'Once, after Fajr',
      source: 'Ibn Majah',
    ),
    AfterSalahDua(
      id: 14,
      arabicOnly: 'اللَّهُمَّ أَجِرْنِي مِنَ النَّارِ',
      transliteration: 'Allaahumma ajirnee minan-naar.',
      translation: 'O Allaah, save me from the Fire.',
      notes: 'Said seven times after Fajr and after Maghrib',
      repetition: 'Seven times, after Fajr and Maghrib',
      source: 'Abu Dawud, Ahmad',
    ),
  ];
}