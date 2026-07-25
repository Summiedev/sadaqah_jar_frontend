class TravelDua {
  final int id;
  final String? arabicOnly;
  final String transliteration;
  final String translation;
  final String? commonName;
  final String? notes;
  final String repetition;
  final String source;
  final int chapterNumber;
  final String chapterTitle;

  const TravelDua({
    required this.id,
    this.arabicOnly,
    required this.transliteration,
    required this.translation,
    this.commonName,
    this.notes,
    required this.repetition,
    required this.source,
    required this.chapterNumber,
    required this.chapterTitle,
  });

  String get arabic => arabicOnly ?? '';
}

class TravelAdhkarData {
  static const bookSource = 'Hisnul Muslim (Fortress of the Muslim) — Sa\'id bin Ali Al-Qahtani';
  static const chapterRange = '89-99';

  static const List<TravelDua> duas = [
    TravelDua(
      id: 0,
      arabicOnly: 'بِسْمِ اللَّهِ، الْحَمْدُ لِلَّهِ، سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ، الْحَمْدُ لِلَّهِ، الْحَمْدُ لِلَّهِ، الْحَمْدُ لِلَّهِ، اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، سُبْحَانَكَ اللَّهُمَّ إِنِّي ظَلَمْتُ نَفْسِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
      transliteration: 'Bismillaah, Alhamdu lillaah. Subhaanal-ladhee sakhkhara lanaa haadhaa wa maa kunnaa lahu muqrineen. Wa innaa ilaa Rabbinaa lamunqaliboon. Alhamdu lillaah, Alhamdu lillaah, Alhamdu lillaah. Allaahu akbar, Allaahu akbar, Allaahu akbar. Subhaanakal-laahumma innee dhalamtu nafsee, faghfir lee, fa\'innahu laa yaghfirudh-dhunooba illaa ant.',
      translation: 'In the name of Allaah, and all praise is for Allaah. How perfect He is, the One Who has placed this (transport) at our service, and we ourselves would not have been capable of that, and to our Lord is our final destiny. All praise is for Allaah, all praise is for Allaah, all praise is for Allaah. Allaah is the greatest, Allaah is the greatest, Allaah is the greatest. How perfect You are, O Allaah, verily I have wronged my soul, so forgive me, for surely none can forgive sins except You.',
      commonName: 'Supplication upon mounting an animal or any means of transport',
      repetition: 'Once, upon mounting',
      source: 'Abu Dawud, at-Tirmidhi',
      chapterNumber: 89,
      chapterTitle: 'Supplication said when mounting an animal or any means of transport',
    ),
    TravelDua(
      id: 1,
      arabicOnly: 'اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ، اللَّهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَذَا الْبِرَّ وَالتَّقْوَى، وَمِنَ الْعَمَلِ مَا تَرْضَى، اللَّهُمَّ هَوِّنْ عَلَيْنَا سَفَرَنَا هَذَا وَاطْوِ عَنَّا بُعْدَهُ، اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ، وَالْخَلِيفَةُ فِي الْأَهْلِ، اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ وَعْثَاءِ السَّفَرِ، وَكَآبَةِ الْمَنْظَرِ، وَسُوءِ الْمُنْقَلَبِ فِي الْمَالِ وَالْأَهْلِ',
      transliteration: 'Allaahu akbar, Allaahu akbar, Allaahu akbar. Subhaanal-ladhee sakhkhara lanaa haadhaa wa maa kunnaa lahu muqrineen. Wa innaa ilaa Rabbinaa lamunqaliboon. Allaahumma innaa nas\'aluka fee safarinaa haadhal-birra wat-taqwaa, wa minal-\'amali maa tardhaa. Allaahumma hawwin \'alaynaa safaranaa haadhaa watwi \'annaa bu\'dahu. Allaahumma antas-saahibu fis-safar, wal-khaleefatu fil-ahl. Allaahumma innee a\'oodhu bika min wa\'thaa\'is-safar, wa kaabatil-mandhar, wa soo\'il-munqalabi fil-maali wal-ahl.',
      translation: 'Allaah is the greatest, Allaah is the greatest, Allaah is the greatest. How perfect He is, The One Who has placed this (transport) at our service, and we ourselves would not have been capable of that, and to our Lord is our final destiny. O Allaah, we ask You for birr (righteousness) and taqwaa (piety) in this journey of ours, and we ask You for deeds which please You. O Allaah, facilitate our journey and let us cover its distance quickly. O Allaah, You are The Companion on the journey and the Successor over the family. O Allaah, I take refuge with You from the difficulties of travel, from having a change of hearts and being in a bad predicament, and I take refuge in You from an ill-fated outcome with wealth and family.',
      commonName: 'Supplication for travel',
      notes: 'Upon returning, the same supplication is recited with the addition: "Aayiboona, taa\'iboona, \'aabidoona, li-Rabbinaa haamidoon" (We return, repent, worship and praise our Lord)',
      repetition: 'Once, at the start of a journey',
      source: 'Muslim',
      chapterNumber: 90,
      chapterTitle: 'Supplication for travel',
    ),
    TravelDua(
      id: 2,
      arabicOnly: 'اللَّهُمَّ رَبَّ السَّمَاوَاتِ السَّبْعِ وَمَا أَظْلَلْنَ، وَرَبَّ الْأَرَضِينَ السَّبْعِ وَمَا أَقْلَلْنَ، وَرَبَّ الشَّيَاطِينِ وَمَا أَضْلَلْنَ، وَرَبَّ الرِّيَاحِ وَمَا ذَرَيْنَ، أَسْأَلُكَ خَيْرَ هَذِهِ الْقَرْيَةِ وَخَيْرَ أَهْلِهَا، وَخَيْرَ مَا فِيهَا، وَأَعُوذُ بِكَ مِنْ شَرِّهَا وَشَرِّ أَهْلِهَا، وَشَرِّ مَا فِيهَا',
      transliteration: 'Allaahumma Rabbas-samaawaatis-sab\'i wa maa adhlalna, wa Rabbal-aradheenas-sab\'i wa maa aqlalna, wa Rabbash-shayaateeni wa maa adhlalna, wa Rabbar-riyaahi wa maa dharayn. As\'aluka khayra haadhihil-qaryati wa khayra ahlihaa, wa khayra maa feehaa. Wa a\'oodhu bika min sharrihaa wa sharri ahlihaa, wa sharri maa feehaa.',
      translation: 'O Allaah, Lord of the seven heavens and all that they envelop, Lord of the seven earths and all that they carry, Lord of the devils and all whom they misguide, Lord of the winds and all whom they whisk away. I ask You for the goodness of this village, the goodness of its inhabitants, and all the goodness found within it, and I take refuge with You from the evil of this village, the evil of its inhabitants, and from all the evil found within it.',
      commonName: 'Supplication upon entering a town or village',
      repetition: 'Once, upon entry',
      source: 'Ibn as-Sunni',
      chapterNumber: 91,
      chapterTitle: 'Supplication upon entering a town or village, etc.',
    ),
    TravelDua(
      id: 3,
      arabicOnly: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، يُحْيِي وَيُمِيتُ وَهُوَ حَيٌّ لَا يَمُوتُ، بِيَدِهِ الْخَيْرُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      transliteration: 'Laa ilaaha illallaahu wahdahu laa shareeka lah, lahul-mulku wa lahul-hamd, yuhyee wa yumeetu wa Huwa hayyun laa yamoot, biyadihil-khayr, wa Huwa \'alaa kulli shay\'in Qadeer.',
      translation: 'None has the right to be worshipped except Allaah, alone, without partner, to Him belongs all sovereignty and praise. He gives life and causes death, and He is living and does not die. In His hand is all good and He is over all things omnipotent.',
      commonName: 'When entering the market',
      repetition: 'Once, upon entering',
      source: 'at-Tirmidhi',
      chapterNumber: 92,
      chapterTitle: 'When entering the market',
    ),
    TravelDua(
      id: 4,
      arabicOnly: 'بِسْمِ اللَّهِ',
      transliteration: 'Bismillaah.',
      translation: 'In the name of Allaah.',
      commonName: 'When the mounted animal (or means of transport) stumbles',
      repetition: 'Once, at the moment of stumbling',
      source: 'Abu Dawud',
      chapterNumber: 93,
      chapterTitle: 'Supplication for when the mounted animal (or means of transport) stumbles',
    ),
    TravelDua(
      id: 5,
      arabicOnly: 'أَسْتَوْدَعُكُمُ اللَّهَ الَّذِي لَا تَضِيعُ وَدَائِعُهُ',
      transliteration: 'Astawdi\'ukumullaahal-ladhee laa tadhee\'u wadaa\'i\'uh.',
      translation: 'I place you in the trust of Allaah, whose trust is never misplaced.',
      commonName: 'Supplication of the traveller for the resident',
      repetition: 'Once, when parting',
      source: 'Ibn Majah, Ahmad',
      chapterNumber: 94,
      chapterTitle: 'Supplication of the traveller for the resident',
    ),
    TravelDua(
      id: 6,
      arabicOnly: 'أَسْتَوْدَعُ اللَّهَ دِينَكَ وَأَمَانَتَكَ وَخَوَاتِيمَ عَمَلِكَ',
      transliteration: 'Astawdi\'ullaaha deenaka wa amaanataka wa khawaateema \'amalik.',
      translation: 'I place your religion, your faithfulness, and the ends of your deeds in the trust of Allaah.',
      commonName: 'Supplication of the resident for the traveller (i)',
      repetition: 'Once, when parting',
      source: 'at-Tirmidhi',
      chapterNumber: 95,
      chapterTitle: 'Supplication of the resident for the traveller',
    ),
    TravelDua(
      id: 7,
      arabicOnly: 'زَوَّدَكَ اللَّهُ التَّقْوَى، وَغَفَرَ ذَنْبَكَ، وَيَسَّرَ لَكَ الْخَيْرَ حَيْثُمَا كُنْتَ',
      transliteration: 'Zawwadakal-laahut-taqwaa, wa ghafara dhanbaka, wa yassara lakal-khayra haythumaa kunt.',
      translation: 'May Allaah endow you with taqwaa (piety), forgive your sins, and facilitate all good for you, wherever you be.',
      commonName: 'Supplication of the resident for the traveller (ii)',
      repetition: 'Once, when parting',
      source: 'at-Tirmidhi',
      chapterNumber: 95,
      chapterTitle: 'Supplication of the resident for the traveller',
    ),
    TravelDua(
      id: 8,
      arabicOnly: 'اللَّهُ أَكْبَرُ',
      transliteration: 'Allaahu akbar.',
      translation: 'Allaah is the greatest.',
      commonName: 'While ascending (going uphill)',
      notes: 'Jaabir said: while ascending we would say Allaahu akbar, and when descending we would say Subhaanallaah',
      repetition: 'Each time ascending',
      source: 'al-Bukhari',
      chapterNumber: 96,
      chapterTitle: 'Remembrance while ascending or descending',
    ),
    TravelDua(
      id: 9,
      arabicOnly: 'سُبْحَانَ اللَّهِ',
      transliteration: 'Subhaanallaah.',
      translation: 'How perfect Allaah is.',
      commonName: 'While descending (going downhill)',
      repetition: 'Each time descending',
      source: 'al-Bukhari',
      chapterNumber: 96,
      chapterTitle: 'Remembrance while ascending or descending',
    ),
    TravelDua(
      id: 10,
      arabicOnly: 'سَمِعَ سَامِعٌ بِحَمْدِ اللَّهِ وَحُسْنِ بَلَائِهِ عَلَيْنَا، رَبَّنَا صَاحِبْنَا وَأَفْضِلْ عَلَيْنَا، عَائِذًا بِاللَّهِ مِنَ النَّارِ',
      transliteration: 'Sami\'a saami\'un bihamdil-laahi wa husni balaa\'ihi \'alaynaa. Rabbanaa saahibnaa wa afdil \'alaynaa, \'aa\'idham-billaahi minan-naar.',
      translation: 'May a witness bear witness to our praise of Allaah for His favours and bounties upon us. Our Lord, accompany us and show favour upon us. I take refuge in Allaah from the Fire.',
      commonName: 'Prayer of the traveller as dawn approaches',
      repetition: 'Once, at dawn during travel',
      source: 'Muslim',
      chapterNumber: 97,
      chapterTitle: 'Prayer of the traveller as dawn approaches',
    ),
    TravelDua(
      id: 11,
      arabicOnly: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
      transliteration: 'A\'oodhu bikalimaatil-laahit-taammaati min sharri maa khalaq.',
      translation: 'I take refuge in Allaah\'s perfect words from the evil that He has created.',
      commonName: 'Stopping or lodging somewhere',
      repetition: 'Once, upon stopping',
      source: 'Muslim',
      chapterNumber: 98,
      chapterTitle: 'Stopping or lodging somewhere',
    ),
    TravelDua(
      id: 12,
      arabicOnly: 'اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ',
      transliteration: 'Allaahu akbar, Allaahu akbar, Allaahu akbar.',
      translation: 'Allaah is the greatest, Allaah is the greatest, Allaah is the greatest.',
      commonName: 'While returning from travel (i)',
      notes: 'Ibn \'Umar reported that the Messenger of Allaah, on return from a battle or from performing the pilgrimage, would say this at every high point',
      repetition: 'Three times, at every high point',
      source: 'al-Bukhari, Muslim',
      chapterNumber: 99,
      chapterTitle: 'While returning from travel',
    ),
    TravelDua(
      id: 13,
      arabicOnly: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، آيِبُونَ تَائِبُونَ عَابِدُونَ سَاجِدُونَ لِرَبِّنَا حَامِدُونَ، صَدَقَ اللَّهُ وَعْدَهُ، وَنَصَرَ عَبْدَهُ، وَهَزَمَ الْأَحْزَابَ وَحْدَهُ',
      transliteration: 'Laa ilaaha illallaahu wahdahu laa shareeka lah, lahul-mulku wa lahul-hamdu, wa Huwa \'alaa kulli shay\'in Qadeer. Aayiboona, taa\'iboona, \'aabidoona, saajidoona, li-Rabbinaa haamidoon. Sadaqal-laahu wa\'dah, wa nasara \'abdah, wa hazamal-ahzaaba wahdah.',
      translation: 'None has the right to be worshipped except Allaah, alone, without partner. To Him belongs all sovereignty and praise, and He is over all things omnipotent. We return, repent, worship, prostrate, and praise our Lord. Allaah fulfilled His promise, aided His servant, and single-handedly defeated the allies.',
      commonName: 'While returning from travel (ii)',
      repetition: 'Once, after the takbeer, at every high point',
      source: 'al-Bukhari, Muslim',
      chapterNumber: 99,
      chapterTitle: 'While returning from travel',
    ),
  ];
}
