class MorningDua {
  final int id;
  final String? arabicMorning;
  final String? arabicEvening;
  final String? arabicOnly;
  final String transliteration;
  final String translation;
  final String? commonName;
  final String? notes;
  final String repetition;
  final String source;

  const MorningDua({
    required this.id,
    this.arabicMorning,
    this.arabicEvening,
    this.arabicOnly,
    required this.transliteration,
    required this.translation,
    this.commonName,
    this.notes,
    required this.repetition,
    required this.source,
  });

  String get arabic => arabicMorning ?? arabicOnly ?? '';
  bool get hasEvening => arabicEvening != null;
  bool get isQuranRef => notes?.contains("Qur'anic text") ?? false;
}

class MorningAdhkarData {
  static const source =
      'Hisnul Muslim (Fortress of the Muslim) - Sa\'id bin Ali Al-Qahtani';
  static const chapter = 'Remembrance said in the morning and evening';
  static const chapterNumber = 27;
  static const duaRange = '75-94';

  static const List<MorningDua> duas = [
    MorningDua(
      id: 0,
      arabicOnly:
          'الْحَمْدُ لِلَّهِ وَحْدَهُ، وَالصَّلَاةُ وَالسَّلَامُ عَلَى مَنْ لَا نَبِيَّ بَعْدَهُ',
      transliteration:
          'Alḥamdulillāhi waḥdah, waṣ-ṣalātu was-salāmu ʿalā man lā nabiyya baʿdah.',
      translation:
          'All praise belongs to Allah alone, and may prayers and peace be upon him after whom there is no prophet.',
      repetition: 'Once',
      source: 'Thabit ibn al-Ajlan',
    ),
    MorningDua(
      id: 1,
      arabicOnly:
          'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ وَلَا يَؤُودُهُ حِفْظُهُمَا وَهُوَ الْعَلِيُّ الْعَظِيمُ',
      transliteration:
          'Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum. La ta\'khudhuhu sinatun wa la nawm. Lahu ma fis-samawati wa ma fil-ard. Man dhal-ladhi yashfa\'u indahu illa bi-idhnih. Ya\'lamu ma bayna aydihim wa ma khalfahum, wa la yuhituna bishay\'in min ilmihi illa bima sha\'. Wasi\'a kursiyyuhus-samawati wal-ard, wa la ya\'uduhu hifzuhuma, wa Huwal-Aliyyul-Azim.',
      translation:
          'Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation does not burden Him. And He is the Most High, the Most Great.',
      commonName: 'Ayat al-Kursi (The Throne Verse)',
      repetition: 'Once',
      source: 'Quran 2:255',
    ),
    MorningDua(
      id: 2,
      arabicOnly:
          'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
      transliteration:
          'Qul huwa Allaahu ahad. Allaahus-samad. Lam yalid wa lam yoolad. Wa lam yakun lahu kufuwan ahad.',
      translation:
          'Say, "He is Allah, the One. Allah, the Eternal Refuge. He neither begets nor is born. Nor is there to Him any equivalent."',
      commonName: 'Surah Al-Ikhlas (The Sincerity)',
      repetition: 'Three times',
      source: 'Quran 112',
    ),
    MorningDua(
      id: 3,
      arabicOnly:
          'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِن شَرِّ مَا خَلَقَ ۝ وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ',
      transliteration:
          'Qul a\'oodhu birabbil-falaq. Min sharri maa khalaq. Wa min sharri ghasiqin idha waqab. Wa min sharrin-naffaathaati fil-\'uqad. Wa min sharri hasidin idha hasad.',
      translation:
          'Say, "I seek refuge in the Lord of daybreak. From the evil of that which He created. And from the evil of darkness when it settles. And from the evil of the blowers in knots. And from the evil of an envier when he envies."',
      commonName: 'Surah Al-Falaq (The Daybreak)',
      repetition: 'Three times',
      source: 'Quran 113',
    ),
    MorningDua(
      id: 4,
      arabicOnly:
          'قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَٰهِ النَّاسِ ۝ مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ',
      transliteration:
          'Qul a\'oodhu birabbin-naas. Malikin-naas. Ilaahin-naas. Min sharril-waswaasil-khannaas. Alladhee yuwaswisu fee sudoorin-naas. Minal-jinnati wan-naas.',
      translation:
          'Say, "I seek refuge in the Lord of mankind. The Sovereign of mankind. The God of mankind. From the evil of the retreating whisperer. Who whispers in the breasts of mankind. From among the jinn and mankind."',
      commonName: 'Surah An-Nas (The Mankind)',
      repetition: 'Three times',
      source: 'Quran 114',
    ),
    MorningDua(
      id: 5,
      arabicMorning:
          'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ',
      arabicEvening:
          'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ... رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا',
      transliteration:
          'Asbahnaa wa asbahal-mulku lillaah, wal-hamdu lillaah, laa ilaaha illallaahu wahdahu laa shareeka lah, lahul-mulku wa lahul-hamdu wa Huwa \'alaa kulli shay\'in Qadeer. Rabbi as\'aluka khayra maa fee haadhal-yawmi wa khayra maa ba\'dahu, wa a\'oodhu bika min sharri maa fee haadhal-yawmi wa sharri maa ba\'dahu. Rabbi a\'oodhu bika minal-kasali wa soo\'il-kibar. Rabbi a\'oodhu bika min \'adhaabin fin-naari wa \'adhaabin fil-qabr.',
      translation:
          'We have reached the morning and at this very time unto Allaah belongs all sovereignty, and all praise is for Allaah. None has the right to be worshipped except Allaah, alone, without partner, to Him belongs all sovereignty and praise and He is over all things omnipotent. My Lord, I ask You for the good of this day and the good of what follows it and I take refuge in You from the evil of this day and the evil of what follows it. My Lord, I take refuge in You from laziness and senility. My Lord, I take refuge in You from torment in the Fire and punishment in the grave.',
      repetition: 'Once, morning and evening',
      source: 'Muslim',
    ),
    MorningDua(
      id: 6,
      arabicMorning:
          'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ',
      arabicEvening:
          'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ الْمَصِيرُ',
      transliteration:
          'Allaahumma bika asbahnaa, wa bika amsaynaa, wa bika nahyaa, wa bika namootu wa ilaykan-nushoor.',
      translation:
          'O Allaah, by Your leave we have reached the morning and by Your leave we have reached the evening, by Your leave we live and die and unto You is our resurrection.',
      repetition: 'Once, morning and evening',
      source: 'at-Tirmidhi',
    ),
    MorningDua(
      id: 7,
      arabicOnly:
          'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
      transliteration:
          'Allaahumma anta Rabbee laa ilaaha illaa ant, khalaqtanee wa ana \'abduk, wa ana \'alaa \'ahdika wa wa\'dika mastata\'tu, a\'oodhu bika min sharri maa sana\'t, aboo\'u laka bini\'matika \'alayy, wa aboo\'u bidhanbee faghfir lee fa\'innahu laa yaghfirudh-dhunooba illaa ant.',
      translation:
          'O Allaah, You are my Lord, none has the right to be worshipped except You, You created me and I am Your servant and I abide to Your covenant and promise as best I can, I take refuge in You from the evil of which I have committed. I acknowledge Your favour upon me and I acknowledge my sin, so forgive me, for verily none can forgive sin except You.',
      repetition: 'Once, morning and evening',
      source: 'al-Bukhari',
    ),
    MorningDua(
      id: 8,
      arabicOnly:
          'اللَّهُمَّ إِنِّي أَصْبَحْتُ أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلَائِكَتَكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَهَ إِلَّا أَنْتَ وَحْدَكَ لَا شَرِيكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكَ',
      transliteration:
          'Allaahumma innee asbahtu ush-hiduka, wa ush-hidu hamalata \'arshika, wa malaa\'ikataka, wa jamee\'a khalqika, annaka antallaahu laa ilaaha illaa anta wahdaka laa shareeka lak, wa anna Muhammadan \'abduka wa rasooluk.',
      translation:
          'O Allaah, verily I have reached the morning and call on You, the bearers of Your throne, Your angels, and all of Your creation to witness that You are Allaah, none has the right to be worshipped except You, alone, without partner and that Muhammad is Your Servant and Messenger.',
      notes: 'For the evening, replace \'asbahtu\' with \'amsaytu\'',
      repetition: 'Four times, morning and evening',
      source: 'Abu Dawud',
    ),
    MorningDua(
      id: 9,
      arabicOnly:
          'اللَّهُمَّ مَا أَصْبَحَ بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ فَمِنْكَ وَحْدَكَ لَا شَرِيكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ',
      transliteration:
          'Allaahumma maa asbaha bee min ni\'matin aw bi-ahadin min khalqika faminka wahdaka laa shareeka lak, falakal-hamdu wa lakash-shukr.',
      translation:
          'O Allaah, what blessing I or any of Your creation have risen upon, is from You alone, without partner, so for You is all praise and unto You all thanks.',
      notes:
          'Whoever says this in the morning has offered his day\'s thanks; in the evening, his night\'s thanks',
      repetition: 'Once, morning and evening',
      source: 'Abu Dawud, an-Nasa\'i, Ibn Hibban',
    ),
    MorningDua(
      id: 10,
      arabicOnly:
          'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِينِي فِي بَصَرِي، لَا إِلَهَ إِلَّا أَنْتَ. اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ وَالْفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، لَا إِلَهَ إِلَّا أَنْتَ',
      transliteration:
          'Allaahumma \'aafinee fee badanee, Allaahumma \'aafinee fee sam\'ee, Allaahumma \'aafinee fee basaree, laa ilaaha illaa ant. Allaahumma innee a\'oodhu bika minal-kufri wal-faqr, wa a\'oodhu bika min \'adhaabil-qabr, laa ilaaha illaa ant.',
      translation:
          'O Allaah, grant my body health, O Allaah, grant my hearing health, O Allaah, grant my sight health. None has the right to be worshipped except You. O Allaah, I take refuge with You from disbelief and poverty, and I take refuge with You from the punishment of the grave. None has the right to be worshipped except You.',
      repetition: 'Three times each, morning and evening',
      source: 'Abu Dawud, Ahmad, an-Nasa\'i',
    ),
    MorningDua(
      id: 11,
      arabicOnly:
          'حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
      transliteration:
          'Hasbiyallaahu laa ilaaha illaa Huwa \'alayhi tawakkaltu wa Huwa Rabbul-\'Arshil-\'Adheem.',
      translation:
          'Allaah is Sufficient for me, none has the right to be worshipped except Him, upon Him I rely and He is Lord of the exalted throne.',
      repetition: 'Seven times, morning and evening',
      source: 'Abu Dawud',
    ),
    MorningDua(
      id: 12,
      arabicOnly:
          'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
      transliteration:
          'A\'oodhu bikalimaatillaahit-taammaati min sharri maa khalaq.',
      translation:
          'I take refuge in Allaah\'s perfect words from the evil He has created.',
      repetition: 'Three times',
      source: 'Muslim',
    ),
    MorningDua(
      id: 13,
      arabicOnly:
          'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَيْنِ يَدَيَّ وَمِنْ خَلْفِي وَعَنْ يَمِينِي وَعَنْ شِمَالِي وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي',
      transliteration:
          'Allaahumma innee as\'alukal-\'afwa wal-\'aafiyata fid-dunyaa wal-aakhirah, Allaahumma innee as\'alukal-\'afwa wal-\'aafiyata fee deenee wa dunyaaya wa ahlee wa maalee, Allaahummastur \'awraatee wa aamin raw\'aatee, Allaahummahfadhnee min bayni yadayya wa min khalfee wa \'an yameenee wa \'an shimaalee wa min fawqee, wa a\'oodhu bi\'adhamatika an ughtaala min tahtee.',
      translation:
          'O Allaah, I ask You for pardon and well-being in this life and the next. O Allaah, I ask You for pardon and well-being in my religious and worldly affairs, and my family and my wealth. O Allaah, veil my weaknesses and set at ease my dismay. O Allaah, preserve me from the front and from behind and on my right and on my left and from above, and I take refuge with You lest I be swallowed up by the earth.',
      repetition: 'Once, morning and evening',
      source: 'Abu Dawud, Ibn Majah, Ahmad',
    ),
    MorningDua(
      id: 14,
      arabicOnly:
          'اللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ فَاطِرَ السَّمَوَاتِ وَالْأَرْضِ رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي وَمِنْ شَرِّ الشَّيْطَانِ وَشِرْكِهِ، وَأَنْ أَقْتَرِفَ عَلَى نَفْسِي سُوءًا أَوْ أَجُرَّهُ إِلَى مُسْلِمٍ',
      transliteration:
          'Allaahumma \'Aalimal-ghaybi wash-shahaadah, Faatiras-samaawaati wal-ardh, Rabba kulli shay\'in wa maleekah, ash-hadu allaa ilaaha illaa ant, a\'oodhu bika min sharri nafsee wa min sharrish-shaytaani wa shirkih, wa an aqtarifa \'alaa nafsee soo\'an aw ajurrahu ilaa muslim.',
      translation:
          'O Allaah, Knower of the unseen and the seen, Creator of the heavens and the Earth, Lord and Sovereign of all things, I bear witness that none has the right to be worshipped except You. I take refuge in You from the evil of my soul and from the evil and shirk of the devil, and from committing wrong against my soul or bringing such upon another Muslim.',
      repetition: 'Once, morning and evening',
      source: 'at-Tirmidhi',
    ),
    MorningDua(
      id: 15,
      arabicOnly:
          'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
      transliteration:
          'Bismillaahil-ladhee laa yadhurru ma\'as-mihi shay\'un fil-ardhi wa laa fis-samaa\'i wa Huwas-Samee\'ul-\'Aleem.',
      translation:
          'In the name of Allaah with whose name nothing is harmed on earth nor in the heavens, and He is The All-Hearing, The All-Knowing.',
      repetition: 'Three times, morning and evening',
      source: 'Abu Dawud, at-Tirmidhi, Ibn Majah, Ahmad',
    ),
    MorningDua(
      id: 16,
      arabicOnly:
          'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا',
      transliteration:
          'Radheetu billaahi Rabbaa, wa bil-Islaami deenaa, wa bi-Muhammadin sallallaahu \'alayhi wa sallama Nabiyyaa.',
      translation:
          'I am pleased with Allaah as a Lord, and Islaam as a religion and Muhammad as a Prophet.',
      repetition: 'Three times, morning and evening',
      source: 'Ahmad, an-Nasa\'i, at-Tirmidhi',
    ),
    MorningDua(
      id: 17,
      arabicOnly:
          'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ',
      transliteration:
          'Subhaanallaahi wa bihamdihi, \'adada khalqihi, wa ridhaa nafsihi, wa zinata \'arshihi, wa midaada kalimaatih.',
      translation:
          'How perfect Allaah is and I praise Him by the number of His creation and His pleasure, and by the weight of His throne, and the ink of His words.',
      repetition: 'Three times',
      source: 'Muslim',
    ),
    MorningDua(
      id: 18,
      arabicOnly: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      transliteration: 'Subhaanallaahi wa bihamdih.',
      translation: 'How perfect Allaah is and I praise Him.',
      repetition: 'One hundred times',
      source: 'Muslim',
    ),
    MorningDua(
      id: 19,
      arabicOnly:
          'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
      transliteration:
          'Yaa Hayyu yaa Qayyoomu birahmatika astagheeth, aslih lee sha\'nee kullahu, wa laa takilnee ilaa nafsee tarfata \'ayn.',
      translation:
          'O Ever Living, O Self-Subsisting and Supporter of all, by Your mercy I seek assistance, rectify for me all of my affairs and do not leave me to myself, even for the blink of an eye.',
      repetition: 'Once, morning and evening',
      source: 'an-Nasa\'i, al-Hakim',
    ),
    MorningDua(
      id: 20,
      arabicOnly:
          'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      transliteration:
          'Laa ilaaha illallaahu wahdahu laa shareeka lah, lahul-mulku wa lahul-hamdu wa Huwa \'alaa kulli shay\'in Qadeer.',
      translation:
          'None has the right to be worshipped except Allaah, alone, without partner, to Him belongs all sovereignty and praise, and He is over all things omnipotent.',
      repetition: 'One hundred times every day',
      source: 'al-Bukhari, Muslim',
    ),
    MorningDua(
      id: 21,
      arabicOnly:
          'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ رَبِّ الْعَالَمِينَ، اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ هَذَا الْيَوْمِ فَتْحَهُ وَنَصْرَهُ وَنُورَهُ وَبَرَكَتَهُ وَهُدَاهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِيهِ وَشَرِّ مَا بَعْدَهُ',
      transliteration:
          'Asbahnaa wa asbahal-mulku lillaahi Rabbil-\'aalameen, Allaahumma innee as\'aluka khayra haadhal-yawmi fat-hahu wa nasrahu wa noorahu wa barakatahu wa hudaahu, wa a\'oodhu bika min sharri maa feehi wa sharri maa ba\'dah.',
      translation:
          'We have reached the morning and at this very time all sovereignty belongs to Allaah, Lord of the worlds. O Allaah, I ask You for the good of this day, its triumphs and its victories, its light and its blessings and its guidance, and I take refuge in You from the evil of this day and the evil that follows it.',
      notes: 'Adjusted similarly for the evening',
      repetition: 'Once, morning and evening',
      source: 'Abu Dawud',
    ),
    MorningDua(
      id: 22,
      notes:
          'Virtue narration attached to dua #20\'s dhikr (La ilaha illallah...): whoever recites it in the morning has the reward of freeing a slave, ten sins wiped away, raised ten degrees, and protection from the devil until evening - and vice versa if said in the evening.',
      translation:
          'Whoever says (the dhikr of #20) in the morning has indeed gained the reward of freeing a slave from the children of Ismaa\'eel, and ten of his sins are wiped away, and he is raised ten degrees, and he has found a safe retreat from the devil until evening. Similarly, if he says it at evening time, he will be protected until the morning.',
      transliteration: '',
      repetition: 'See dua #20',
      source: 'al-Bukhari, Muslim',
    ),
    MorningDua(
      id: 23,
      arabicOnly:
          'أَصْبَحْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ، حَنِيفًا مُسْلِمًا وَمَا كَانَ مِنَ الْمُشْرِكِينَ',
      transliteration:
          'Asbahnaa \'alaa fitratil-Islaam, wa \'alaa kalimatil-ikhlaas, wa \'alaa deeni Nabiyyinaa Muhammadin sallallaahu \'alayhi wa sallam, wa \'alaa millati abeenaa Ibraaheema haneefan musliman wa maa kaana minal-mushrikeen.',
      translation:
          'We rise upon the fitrah (natural religion) of Islaam, and the word of pure faith, and upon the religion of our Prophet Muhammad and the religion of our forefather Ibraaheem, who was a Muslim of true faith and was not of those who associate others with Allaah.',
      repetition: 'Once, morning and evening',
      source: 'Ahmad',
    ),
  ];
}
