class SleepDua {
  final int id;
  final String? arabicOnly;
  final String transliteration;
  final String translation;
  final String? commonName;
  final String? notes;
  final String repetition;
  final String source;

  const SleepDua({
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

class SleepAdhkarData {
  static const source = 'Hisnul Muslim (Fortress of the Muslim) — Sa\'id bin Ali Al-Qahtani';
  static const chapter = 'Supplication before sleeping';
  static const chapterNumber = 28;
  static const duaRange = '95-110';

  static const List<SleepDua> duas = [
    SleepDua(
      id: 0,
      arabicOnly: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ وَلَا يَؤُودُهُ حِفْظُهُمَا وَهُوَ الْعَلِيُّ الْعَظِيمُ',
      transliteration: 'Ayat al-Kursi — Allaahu laa ilaaha illaa Huwal-Hayyul-Qayyoom, laa ta\'khudhuhu sinatun wa laa nawm. Lahul-mulku wa lahul-hamdu wa Huwa \'alaa kulli shay\'in Qadeer.',
      translation: 'Allaah - there is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation does not burden Him. And He is the Most High, the Most Great.',
      commonName: 'Ayat al-Kursi (The Throne Verse)',
      notes: 'Whoever recites this upon lying down, an angel is appointed as a guard over him and Satan cannot approach him until morning',
      repetition: 'Once, before sleeping',
      source: 'Quran 2:255',
    ),
    SleepDua(
      id: 1,
      arabicOnly: 'آمَنَ الرَّسُولُ بِمَا أُنْزِلَ إِلَيْهِ مِنْ رَبِّهِ وَالْمُؤْمِنُونَ ۚ كُلٌّ آمَنَ بِاللَّهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ لَا نُفَرِّقُ بَيْنَ أَحَدٍ مِنْ رُسُلِهِ ۚ وَقَالُوا سَمِعْنَا وَأَطَعْنَا ۖ غُفْرَانَكَ رَبَّنَا وَإِلَيْكَ الْمَصِيرُ ۝ لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا ۚ لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ ۭ رَبَّنَا لَا تُؤَاخِذْنَا إِنْ نَسِينَا أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِنْ قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ۖ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ۚ أَنْتَ مَوْلَانَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ ۝',
      transliteration: 'Aamanar-Rasoolu bimaa unzila ilayhi min Rabbihil-Mu\'mineen, kullun aamana billaahi wa malaa\'ikatihi wa kutubihi wa Rusulih, laa nufarriqu bayna ahadin min Rusulih, wa qaaloo sami\'naa wa ata\'naa, ghufraanaka Rabbanaa wa ilaykal-maseer. Laa yukallifullaahu nafsan illaa wus\'ahaa, lahaa maa kasabat wa \'alayhaa maa iktasabat. Rabbanaa laa tu\'akhiznaa in naseenaa aw akh-ta\'naa, Rabbanaa wa laa tahmil \'alaynaa isran kamaa hamaltahuu \'alal-lazeena min qablinaa, Rabbanaa wa laa tuhammilnaa maa laa taqataanee bihi, wa\'fu \'annaa wa ghfir lanaa wa rhamnaa, anta Mawlaanaa fansurna \'alal-qawmil-kaafireen.',
      translation: 'The Messenger has believed in what was revealed to him from his Lord, and the believers likewise. All believe in Allaah, His angels, His books, and His messengers. We make no distinction between any of His messengers. They say, "We hear and we obey. Grant us Your forgiveness, our Lord, and to You is the final destination." Allaah does not burden a soul beyond its capacity. To its own credit is what it earns, and against it is what it commits. Our Lord, do not take us to task if we forget or make a mistake. Our Lord, do not burden us as You burdened those before us. Our Lord, do not lay on us more than we have strength to bear. Pardon us, and forgive us, and have mercy on us. You are our Master, so grant us victory over the disbelieving people.',
      commonName: 'The last two verses of Surah Al-Baqarah (2:285-286)',
      notes: 'Whoever recites these two verses at night, they will suffice him',
      repetition: 'Once, before sleeping',
      source: 'Quran 2:285-286',
    ),
    SleepDua(
      id: 2,
      arabicOnly: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      transliteration: 'Bismika Allaahumma amootu wa ahyaa.',
      translation: 'In Your name O Allaah, I die and I live.',
      repetition: 'Once, when lying down to sleep',
      source: 'al-Bukhari',
    ),
    SleepDua(
      id: 3,
      arabicOnly: 'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ',
      transliteration: 'Allaahumma qinee \'adhaabaka yawma tab\'athu \'ibaadak.',
      translation: 'O Allaah, save me from Your punishment on the Day You resurrect Your servants.',
      repetition: 'Three times',
      source: 'Abu Dawud, at-Tirmidhi',
    ),
    SleepDua(
      id: 4,
      arabicOnly: 'اللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَوَجَّهْتُ وَجْهِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، رَغْبَةً وَرَهْبَةً إِلَيْكَ، لَا مَلْجَأَ وَلَا مَنْجَا مِنْكَ إِلَّا إِلَيْكَ، آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ، وَبِنَبِيِّكَ الَّذِي أَرْسَلْتَ',
      transliteration: 'Allaahumma aslamtu nafsee ilayk, wa fawwadtu amree ilayk, wa wajjahtu wajhee ilayk, wa alja\'tu dhahree ilayk, raghbatan wa rahbatan ilayk, laa maljaa wa laa manjaa minka illaa ilayk, aamantu bikitaabikal-ladhee anzalta, wa binabiyyikal-ladhee arsalt.',
      translation: 'O Allaah, I submit myself to You, and I entrust my affair to You, and I turn my face to You, and I lay myself down depending upon You, hoping in You and fearing You. There is no refuge, nor safety, except with You. I believe in Your Book which You have revealed, and in Your Prophet whom You have sent.',
      notes: 'If one dies on the night this is recited, he dies upon the fitrah (natural belief in Allaah alone). Should be the last thing said before sleeping',
      repetition: 'Once',
      source: 'al-Bukhari, Muslim',
    ),
    SleepDua(
      id: 5,
      arabicOnly: 'اللَّهُمَّ رَبَّ السَّمَاوَاتِ السَّبْعِ وَرَبَّ الْأَرْضِ وَرَبَّ الْعَرْشِ الْعَظِيمِ، رَبَّنَا وَرَبَّ كُلِّ شَيْءٍ، فَالِقَ الْحَبِّ وَالنَّوَى، وَمُنْزِلَ التَّوْرَاةِ وَالْإِنْجِيلِ وَالْفُرْقَانِ، أَعُوذُ بِكَ مِنْ شَرِّ كُلِّ ذِي شَرٍّ أَنْتَ آخِذٌ بِنَاصِيَتِهِ، اللَّهُمَّ أَنْتَ الْأَوَّلُ فَلَيْسَ قَبْلَكَ شَيْءٌ، وَأَنْتَ الْآخِرُ فَلَيْسَ بَعْدَكَ شَيْءٌ، وَأَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَيْءٌ، وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَيْءٌ، اقْضِ عَنَّا الدَّيْنَ وَأَغْنِنَا مِنَ الْفَقْرِ',
      transliteration: 'Allaahumma Rabbas-samaawaatis-sab\'i wa Rabbal-\'Arshil-\'Adheem, Rabbanaa wa Rabba kulli shay\', Faaliqal-habbi wan-nawaa, wa Munzilat-Tawraati wal-Injeeli wal-Furqaan, a\'oodhu bika min sharri kulli dhee sharrin anta aakhidhun binaasiyatih, Allaahumma antal-Awwalu falaysa qablaka shay\', wa antal-Aakhiru falaysa ba\'daka shay\', wa antadh-Dhaahiru falaysa fawqaka shay\', wa antal-Baatinu falaysa doonaka shay\', iqdi \'annad-dayna wa aghninaa minal-faqr.',
      translation: 'O Allaah, Lord of the seven heavens and Lord of the earth and Lord of the exalted throne, our Lord and the Lord of all things, Splitter of the seed and the date stone, Revealer of the Torah, the Injeel and the Furqaan (Quran), I take refuge with You from the evil of all things that You will seize by the forelock. O Allaah, You are The First, nothing is before You. You are The Last, nothing is after You. You are Al-Dhaahir (The Most High), nothing is above You. You are Al-Baatin (The Most Near), nothing is nearer than You. Settle our debt on our behalf and enrich us from poverty.',
      repetition: 'Once',
      source: 'Muslim',
    ),
    SleepDua(
      id: 6,
      arabicOnly: 'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
      transliteration: 'Qul huwa Allaahu ahad. Allaahus-samad. Lam yalid wa lam yoolad. Wa lam yakun lahu kufuwan ahad.',
      translation: 'Say, "He is Allah, the One. Allah, the Eternal Refuge. He neither begets nor is born. Nor is there to Him any equivalent."',
      commonName: 'Surah Al-Ikhlas (The Sincerity)',
      notes: 'Recited with the other two Quls, blown into cupped hands, then wiped over the body — repeated three times',
      repetition: 'Three times (with Al-Falaq and An-Nas)',
      source: 'Quran 112 (al-Bukhari)',
    ),
    SleepDua(
      id: 7,
      arabicOnly: 'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِن شَرِّ مَا خَلَقَ ۝ وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ',
      transliteration: 'Qul a\'oodhu birabbil-falaq. Min sharri maa khalaq. Wa min sharri ghasiqin idha waqab. Wa min sharrin-naffaathaati fil-\'uqad. Wa min sharri hasidin idha hasad.',
      translation: 'Say, "I seek refuge in the Lord of daybreak. From the evil of that which He created. And from the evil of darkness when it settles. And from the evil of the blowers in knots. And from the evil of an envier when he envies."',
      commonName: 'Surah Al-Falaq (The Daybreak)',
      notes: 'Recited with the other two Quls, blown into cupped hands, then wiped over the body — repeated three times',
      repetition: 'Three times (with Al-Ikhlas and An-Nas)',
      source: 'Quran 113 (al-Bukhari)',
    ),
    SleepDua(
      id: 8,
      arabicOnly: 'قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَٰهِ النَّاسِ ۝ مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ',
      transliteration: 'Qul a\'oodhu birabbin-naas. Malikin-naas. Ilaahin-naas. Min sharril-waswaasil-khannaas. Alladhee yuwaswisu fee sudoorin-naas. Minal-jinnati wan-naas.',
      translation: 'Say, "I seek refuge in the Lord of mankind. The Sovereign of mankind. The God of mankind. From the evil of the retreating whisperer. Who whispers in the breasts of mankind. From among the jinn and mankind."',
      commonName: 'Surah An-Nas (The Mankind)',
      notes: 'Recited with the other two Quls, blown into cupped hands, then wiped over the body — repeated three times',
      repetition: 'Three times (with Al-Ikhlas and Al-Falaq)',
      source: 'Quran 114 (al-Bukhari)',
    ),
    SleepDua(
      id: 9,
      arabicOnly: 'سُبْحَانَ اللَّهِ (ثَلَاثًا وَثَلَاثِينَ)، وَالْحَمْدُ لِلَّهِ (ثَلَاثًا وَثَلَاثِينَ)، وَاللَّهُ أَكْبَرُ (أَرْبَعًا وَثَلَاثِينَ)',
      transliteration: 'Subhaanallaah (33 times), Alhamdulillaah (33 times), Allaahu akbar (34 times).',
      translation: 'How perfect Allaah is (33 times), all praise is for Allaah (33 times), Allaah is the greatest (34 times).',
      commonName: 'Tasbeeh Faatimah',
      notes: 'Taught by the Prophet to Faatimah and \'Alee instead of a servant, as better than what they asked for',
      repetition: '33, 33, 34 times, before sleeping',
      source: 'al-Bukhari, Muslim',
    ),
    SleepDua(
      id: 10,
      arabicOnly: 'اللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ فَاطِرَ السَّمَوَاتِ وَالْأَرْضِ رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي وَمِنْ شَرِّ الشَّيْطَانِ وَشِرْكِهِ',
      transliteration: 'Allaahumma \'Aalimal-ghaybi wash-shahaadah, Faatiras-samaawaati wal-ardh, Rabba kulli shay\'in wa maleekah, ash-hadu allaa ilaaha illaa ant, a\'oodhu bika min sharri nafsee wa min sharrish-shaytaani wa shirkih.',
      translation: 'O Allaah, Knower of the unseen and the seen, Creator of the heavens and the Earth, Lord and Sovereign of all things, I bear witness that none has the right to be worshipped except You. I take refuge in You from the evil of my soul and from the evil and shirk of the devil.',
      repetition: 'Once, before sleeping',
      source: 'at-Tirmidhi',
    ),
    SleepDua(
      id: 11,
      arabicOnly: 'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا، وَكَفَانَا، وَآوَانَا، فَكَمْ مِمَّنْ لَا كَافِيَ لَهُ وَلَا مُؤْوِيَ',
      transliteration: 'Alhamdu lillaahil-ladhee at\'amanaa wa saqaanaa, wa kafaanaa, wa aawaanaa, fakam mimman laa kaafiya lahu wa laa mu\'wee.',
      translation: 'All praise is for Allaah who has fed us and given us drink, and has been sufficient for us and has sheltered us, for how many have none to suffice them or shelter them.',
      repetition: 'Once, before sleeping',
      source: 'Muslim',
    ),
    SleepDua(
      id: 12,
      arabicOnly: 'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، إِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ',
      transliteration: 'Bismika Rabbee wada\'tu janbee, wa bika arfa\'uh, in amsakta nafsee farhamhaa, wa in arsaltahaa fahfadhhaa bimaa tahfadhu bihi \'ibaadakas-saaliheen.',
      translation: 'In Your name my Lord, I lay down my side, and by Your leave I raise it up. If You should take my soul then have mercy upon it, and if You should return my soul then protect it in the manner You do so with Your righteous slaves.',
      notes: 'Preceded by shaking out the bedding three times, since one does not know what has settled on it after being left',
      repetition: 'Once, before sleeping',
      source: 'al-Bukhari, Muslim',
    ),
    SleepDua(
      id: 13,
      arabicOnly: 'اللَّهُمَّ إِنَّكَ خَلَقْتَ نَفْسِي وَأَنْتَ تَوَفَّاهَا، لَكَ مَمَاتُهَا وَمَحْيَاهَا، إِنْ أَحْيَيْتَهَا فَاحْفَظْهَا، وَإِنْ أَمَتَّهَا فَاغْفِرْ لَهَا، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَافِيَةَ',
      transliteration: 'Allaahumma innaka khalaqta nafsee wa anta tawaffaahaa, laka mamaatuhaa wa mahyaahaa, in ahyaytahaa fahfadh-haa, wa in amattahaa faghfir lahaa. Allaahumma innee as\'alukal-\'aafiyah.',
      translation: 'O Allaah, verily You have created my soul and You shall take its life, to You belongs its life and death. If You should keep my soul alive then protect it, and if You should take its life then forgive it. O Allaah, I ask You to grant me good health.',
      repetition: 'Once, before sleeping',
      source: 'Muslim',
    ),
  ];
}
