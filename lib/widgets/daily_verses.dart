class DailyVerse {
  final String text;
  final String source;
  final String category;
  final String shortText;

  const DailyVerse({
    required this.text,
    required this.source,
    required this.category,
    required this.shortText,
  });
}

const List<DailyVerse> kDailyVerses = [
  DailyVerse(
    text: 'Remember Allah with much remembrance.',
    source: 'Quran 33:41-42',
    category: 'remembrance',
    shortText: 'Remember Allah often',
  ),
  DailyVerse(
    text: 'If you are grateful, I will surely increase you.',
    source: 'Quran 14:7',
    category: 'gratitude',
    shortText: 'Gratitude brings increase',
  ),
  DailyVerse(
    text: 'By the remembrance of Allah hearts are assured.',
    source: 'Quran 13:28',
    category: 'peace',
    shortText: 'Peace in His remembrance',
  ),
  DailyVerse(
    text: 'All praise is due to Allah, Lord of the worlds.',
    source: 'Quran 1:2',
    category: 'praise',
    shortText: 'Praise be to Allah, Lord',
  ),
  DailyVerse(
    text: 'Whoever fears Allah - He will make a way out.',
    source: 'Quran 65:2-3',
    category: 'trust',
    shortText: 'Allah makes a way out',
  ),
  DailyVerse(
    text: 'Do not despair of the mercy of Allah.',
    source: 'Quran 39:53',
    category: 'mercy',
    shortText: 'Do not despair of mercy',
  ),
  DailyVerse(
    text: 'Allah is with the patient.',
    source: 'Quran 2:153',
    category: 'patience',
    shortText: 'Allah is with the patient',
  ),
  DailyVerse(
    text: 'My mercy encompasses all things.',
    source: 'Quran 7:156',
    category: 'mercy',
    shortText: 'His mercy encompasses all',
  ),
  DailyVerse(
    text: 'And He is with you wherever you are.',
    source: 'Quran 57:4',
    category: 'presence',
    shortText: 'He is with you everywhere',
  ),
  DailyVerse(
    text: 'Allah does not burden a soul beyond what it can bear.',
    source: 'Quran 2:286',
    category: 'ease',
    shortText: 'No soul bears beyond its means',
  ),
  DailyVerse(
    text: 'In the remembrance of Allah do hearts find rest.',
    source: 'Quran 13:28',
    category: 'peace',
    shortText: 'Hearts find rest in Him',
  ),
  DailyVerse(
    text: 'And give good news to those who are patient.',
    source: 'Quran 2:155',
    category: 'patience',
    shortText: 'Good news for the patient',
  ),
  DailyVerse(
    text: 'Call upon Me; I will respond to you.',
    source: 'Quran 40:60',
    category: 'dua',
    shortText: 'Call Him and He answers',
  ),
  DailyVerse(
    text: 'Your Lord has not forsaken you.',
    source: 'Quran 93:3',
    category: 'comfort',
    shortText: 'Your Lord has not forsaken you',
  ),
  // Expanded content pool
  DailyVerse(
    text: 'And He found you lost and guided you.',
    source: 'Quran 93:7',
    category: 'guidance',
    shortText: 'He guided you when you were lost',
  ),
  DailyVerse(
    text: 'For indeed, with hardship comes ease.',
    source: 'Quran 94:5',
    category: 'ease',
    shortText: 'With hardship comes ease',
  ),
  DailyVerse(
    text: 'And He found you poor and made you self-sufficient.',
    source: 'Quran 93:8',
    category: 'provision',
    shortText: 'He enriched you after poverty',
  ),
  DailyVerse(
    text:
        'Except those who repent, believe, and do righteous work - for them, Allah will replace their evil deeds with good.',
    source: 'Quran 25:70',
    category: 'repentance',
    shortText: 'Repentance rewrites your record',
  ),
  DailyVerse(
    text:
        'The example of those who spend their wealth in the way of Allah is like a seed that grows seven ears.',
    source: 'Quran 2:261',
    category: 'charity',
    shortText: 'Charity grows like a seed',
  ),
  DailyVerse(
    text:
        'Indeed, Allah will not change the condition of a people until they change what is within themselves.',
    source: 'Quran 13:11',
    category: 'change',
    shortText: 'Change begins within',
  ),
  DailyVerse(
    text: 'And whoever relies upon Allah - He is sufficient for him.',
    source: 'Quran 65:3',
    category: 'tawakkul',
    shortText: 'Allah suffices the one who trusts',
  ),
  DailyVerse(
    text: 'So remember Me; I will remember you.',
    source: 'Quran 2:152',
    category: 'remembrance',
    shortText: 'Remember Him and He remembers you',
  ),
  DailyVerse(
    text:
        'And hold firmly to the rope of Allah all together and do not become divided.',
    source: 'Quran 3:103',
    category: 'unity',
    shortText: 'Hold firm to the rope of Allah',
  ),
  DailyVerse(
    text: 'Every soul shall taste death.',
    source: 'Quran 3:185',
    category: 'hereafter',
    shortText: 'Every soul shall taste death',
  ),
  DailyVerse(
    text: 'And the life of this world is nothing but enjoyment of delusion.',
    source: 'Quran 3:185',
    category: 'hereafter',
    shortText: 'This world is a passing enjoyment',
  ),
  DailyVerse(
    text:
        'Actions are only by intentions, and every person will have only what they intended.',
    source: 'Sahih al-Bukhari 1',
    category: 'intention',
    shortText: 'Actions are by intentions',
  ),
  DailyVerse(
    text:
        'Allah does not look at your bodies or your forms, but He looks at your hearts and your deeds.',
    source: 'Sahih Muslim 2564',
    category: 'sincerity',
    shortText: 'Allah looks at your heart',
  ),
  DailyVerse(
    text: 'Charity does not decrease wealth.',
    source: 'Sahih Muslim 2588',
    category: 'charity',
    shortText: 'Charity never decreases wealth',
  ),
  DailyVerse(
    text:
        'Every good deed is charity. Smiling at your brother is charity; removing harm from the road is charity.',
    source: 'Jami at-Tirmidhi 1970',
    category: 'charity',
    shortText: 'Every good deed is charity',
  ),
  DailyVerse(
    text: 'Sadaqah extinguishes sin as water extinguishes fire.',
    source: 'Jami at-Tirmidhi 2616',
    category: 'charity',
    shortText: 'Sadaqah extinguishes sins',
  ),
  DailyVerse(
    text: 'Whoever does not thank people has not thanked Allah.',
    source: 'Jami at-Tirmidhi 1955',
    category: 'gratitude',
    shortText: 'Thank people, thank Allah',
  ),
  DailyVerse(
    text:
        'Amazing is the affair of the believer. All of it is good - if he is prosperous, he thanks; if he is afflicted, he is patient.',
    source: 'Sahih Muslim 2999',
    category: 'patience',
    shortText: 'All affairs of the believer are good',
  ),
  DailyVerse(
    text:
        'The strong one is not the one who overcomes people - the strong one is the one who controls himself at the time of anger.',
    source: 'Sahih al-Bukhari 6114',
    category: 'character',
    shortText: 'Strength is controlling anger',
  ),
  DailyVerse(
    text:
        'Allah is more delighted with the repentance of His servant than a man who finds his lost camel in the desert.',
    source: 'Sahih al-Bukhari 6309',
    category: 'repentance',
    shortText: 'Allah delights in your repentance',
  ),
  DailyVerse(
    text:
        'Two phrases are light on the tongue, heavy on the scales: SubhanAllahi wa bihamdih, SubhanAllahil-Adheem.',
    source: 'Sahih al-Bukhari 6406',
    category: 'dhikr',
    shortText: 'Two phrases heavy on the scales',
  ),
  DailyVerse(
    text: 'The best of you are those with the best character.',
    source: 'Sahih al-Bukhari 6035',
    category: 'character',
    shortText: 'Best character, best of you',
  ),
  DailyVerse(
    text: 'Your smile to your brother is charity.',
    source: 'Jami at-Tirmidhi 1956',
    category: 'charity',
    shortText: 'A smile is charity',
  ),
  DailyVerse(
    text: 'The one who severs ties of kinship will not enter Paradise.',
    source: 'Sahih al-Bukhari 5984',
    category: 'family',
    shortText: 'Keep ties of kinship',
  ),
  DailyVerse(
    text: 'Dua is worship.',
    source: 'Jami at-Tirmidhi 3371',
    category: 'dua',
    shortText: 'Dua is worship',
  ),
  DailyVerse(
    text:
        'Those who are merciful will be shown mercy by the Most Merciful. Be merciful to those on earth, and the One above the heavens will be merciful to you.',
    source: 'Jami at-Tirmidhi 1924',
    category: 'mercy',
    shortText: 'Be merciful, receive mercy',
  ),
  DailyVerse(
    text: 'Remember often the destroyer of pleasures - death.',
    source: 'Jami at-Tirmidhi 2307',
    category: 'hereafter',
    shortText: 'Remember the destroyer of pleasures',
  ),
  DailyVerse(
    text:
        'The grave is the first stage of the Hereafter. If one is saved from it, what follows is easier; if not, what follows is harder.',
    source: 'Jami at-Tirmidhi 2308',
    category: 'hereafter',
    shortText: 'The grave is the first station',
  ),
  DailyVerse(
    text:
        'Paradise is surrounded by hardships, and the Fire is surrounded by desires.',
    source: 'Sahih Muslim 2822',
    category: 'hereafter',
    shortText: 'Paradise is surrounded by hardships',
  ),
  DailyVerse(
    text:
        'In Paradise, there is what no eye has seen, no ear has heard, and no heart has conceived.',
    source: 'Sahih Muslim 2824',
    category: 'jannah',
    shortText: 'Jannah is beyond imagination',
  ),
  DailyVerse(
    text:
        'Whoever believes in Allah and the Last Day, let him speak good or remain silent.',
    source: 'Sahih al-Bukhari 6018',
    category: 'speech',
    shortText: 'Speak good or remain silent',
  ),
  DailyVerse(
    text:
        'Protect yourselves from the Fire, even with half a date given in charity.',
    source: 'Sahih al-Bukhari 1417',
    category: 'charity',
    shortText: 'Even half a date protects from Fire',
  ),
  DailyVerse(
    text:
        'The heart finds its true life in the remembrance of its Lord - like the fish finds its life in water.',
    source: 'Ibn al-Qayyim',
    category: 'dhikr',
    shortText: 'The heart lives by dhikr',
  ),
  DailyVerse(
    text:
        'O son of Adam, you are but days - whenever a day passes, part of you has gone.',
    source: 'Hasan al-Basri',
    category: 'time',
    shortText: 'Each day is part of you',
  ),
  DailyVerse(
    text: 'Take account of yourselves before you are taken to account.',
    source: 'Umar ibn al-Khattab',
    category: 'accountability',
    shortText: 'Take account of yourself first',
  ),
  DailyVerse(
    text: 'Patience is to the heart what the head is to the body.',
    source: 'Ali ibn Abi Talib',
    category: 'patience',
    shortText: 'Patience is the head of faith',
  ),
  DailyVerse(
    text:
        'Tawakkul is not to be idle - it is to act with your hands while trusting with your heart.',
    source: 'Ibn al-Qayyim',
    category: 'tawakkul',
    shortText: 'Trust Allah, tie your camel',
  ),
  DailyVerse(
    text:
        'What can my enemies do to me? My Paradise is in my heart; my garden is between my two breasts.',
    source: 'Ibn Taymiyyah',
    category: 'faith',
    shortText: 'Paradise is in your heart',
  ),
  DailyVerse(
    text:
        'Richness is not having many possessions. Richness is the contentment of the soul.',
    source: 'Sahih al-Bukhari 6446',
    category: 'contentment',
    shortText: 'Richness is contentment of soul',
  ),
  DailyVerse(
    text:
        'The most beloved deeds to Allah are those done consistently, even if they are small.',
    source: 'Sahih al-Bukhari 6464',
    category: 'consistency',
    shortText: 'Consistency is beloved to Allah',
  ),
  DailyVerse(
    text: 'O Allah, bless my nation in its early mornings.',
    source: 'Jami at-Tirmidhi 1212',
    category: 'morning',
    shortText: 'Blessed are the early mornings',
  ),
  DailyVerse(
    text:
        'The Prophet ﷺ said: The two rak\'ahs of Fajr are better than the world and everything in it.',
    source: 'Sahih Muslim 725',
    category: 'prayer',
    shortText: 'Fajr is better than the world',
  ),
  DailyVerse(
    text: 'Whoever prays Fajr is under the protection of Allah.',
    source: 'Sahih Muslim 657',
    category: 'prayer',
    shortText: 'Fajr brings Allah\'s protection',
  ),
  DailyVerse(
    text: 'Guard strictly the prayers, especially the middle prayer.',
    source: 'Quran 2:238',
    category: 'prayer',
    shortText: 'Guard the middle prayer',
  ),
  DailyVerse(
    text: 'The best prayer after the obligatory prayers is the night prayer.',
    source: 'Sahih Muslim 1163',
    category: 'prayer',
    shortText: 'Night prayer is the best voluntary',
  ),
  DailyVerse(
    text:
        'For every joint of the body, give charity each morning - two rak\'ahs of Duha suffice.',
    source: 'Sahih Muslim 720',
    category: 'prayer',
    shortText: 'Duha is charity for every joint',
  ),
  DailyVerse(
    text:
        'Allah has added a prayer for you - the Witr. Pray it, even a single rak\'ah.',
    source: 'Musnad Ahmad 24069',
    category: 'prayer',
    shortText: 'Pray Witr before you sleep',
  ),
  DailyVerse(
    text:
        'Whoever prays Fajr in congregation, then sits remembering Allah until the sun rises, then prays two rak\'ahs, will have a complete Hajj and Umrah reward.',
    source: 'Jami at-Tirmidhi 586',
    category: 'prayer',
    shortText: 'Ishraq brings Hajj and Umrah reward',
  ),
  DailyVerse(
    text:
        'Recite Ayat al-Kursi in the morning and you will be protected until the evening.',
    source: 'Sahih al-Bukhari 2311',
    category: 'protection',
    shortText: 'Ayat al-Kursi protects you',
  ),
  DailyVerse(
    text: 'Whoever says Bismillah in the morning, nothing will harm him.',
    source: 'Jami at-Tirmidhi 3388',
    category: 'protection',
    shortText: 'Begin with Bismillah',
  ),
  DailyVerse(
    text:
        'Say SubhanAllahi wa bihamdih 100 times in the morning - your sins will be forgiven even if they were like the foam of the sea.',
    source: 'Sahih al-Bukhari 6405',
    category: 'dhikr',
    shortText: 'Morning tasbih forgives sins',
  ),
  DailyVerse(
    text:
        'The Prophet ﷺ said Friday is the best day on which the sun has ever risen.',
    source: 'Sahih Muslim 854',
    category: 'friday',
    shortText: 'Friday is the best day',
  ),
  DailyVerse(
    text:
        'Send abundant salawat upon me on Friday - your salawat are presented to me.',
    source: 'Sunan Abi Dawud 1047',
    category: 'friday',
    shortText: 'Send salawat on Friday',
  ),
  DailyVerse(
    text:
        'Whoever recites Surah Al-Kahf on Friday, a light will shine for him between the two Fridays.',
    source: 'Al-Bayhaqi 6010',
    category: 'friday',
    shortText: 'Surah Al-Kahf is a light',
  ),
  DailyVerse(
    text:
        'There is an hour on Friday when no Muslim asks Allah for something but He gives it.',
    source: 'Sahih al-Bukhari 935',
    category: 'friday',
    shortText: 'Seek the hour of acceptance',
  ),
  DailyVerse(
    text:
        'Whoever fasts a day for the sake of Allah, Allah will distance his face from the Fire by seventy autumns.',
    source: 'Sahih Muslim 1153',
    category: 'fasting',
    shortText: 'Fasting distances you from Fire',
  ),
  DailyVerse(
    text:
        'The Prophet ﷺ used to fast Mondays and Thursdays - the days when deeds are presented to Allah.',
    source: 'Jami at-Tirmidhi 747',
    category: 'fasting',
    shortText: 'Fast Mondays and Thursdays',
  ),
  DailyVerse(
    text:
        'Fast the 13th, 14th, and 15th of the Islamic month - the white days - and receive the reward of fasting the whole month.',
    source: 'Sunan an-Nasa\'i 2419',
    category: 'fasting',
    shortText: 'Fast the white days',
  ),
  DailyVerse(
    text:
        'In Ramadan, the gates of Paradise are opened and the gates of Hell are closed.',
    source: 'Sahih al-Bukhari 1899',
    category: 'ramadan',
    shortText: 'Ramadan opens the gates of Jannah',
  ),
  DailyVerse(
    text: 'The Night of Decree is better than a thousand months.',
    source: 'Quran 97:3',
    category: 'ramadan',
    shortText: 'Laylatul Qadr is better than 1000 months',
  ),
  DailyVerse(
    text:
        'Fasting the day of Arafah expiates the sins of the past and coming year.',
    source: 'Sahih Muslim 1162',
    category: 'fasting',
    shortText: 'Arafah expiates two years of sins',
  ),
  DailyVerse(
    text: 'Fasting Ashura expiates the sins of the past year.',
    source: 'Sahih Muslim 1162',
    category: 'fasting',
    shortText: 'Ashura expiates the past year',
  ),
  DailyVerse(
    text:
        'Allah descends to the lowest heaven in the last third of the night and asks: Who is calling upon Me so I may answer?',
    source: 'Sahih al-Bukhari 1145',
    category: 'night',
    shortText: 'The last third of the night is special',
  ),
  DailyVerse(
    text: 'The dua of a Muslim for his brother in his absence is answered.',
    source: 'Sahih Muslim 2732',
    category: 'dua',
    shortText: 'Pray for others in their absence',
  ),
  DailyVerse(
    text: 'Allah helps the servant as long as the servant helps his brother.',
    source: 'Sahih Muslim 2699',
    category: 'help',
    shortText: 'Help others, Allah helps you',
  ),
  DailyVerse(
    text: 'Whoever feeds a fasting person gets the same reward.',
    source: 'Jami at-Tirmidhi 807',
    category: 'charity',
    shortText: 'Feed a fasting person',
  ),
  DailyVerse(
    text:
        'Every tasbih is sadaqah, every takbir is sadaqah, every tahmid is sadaqah.',
    source: 'Sahih Muslim 720',
    category: 'dhikr',
    shortText: 'Dhikr is charity for your soul',
  ),
  DailyVerse(
    text: 'Kind speech is sadaqah.',
    source: 'Sahih al-Bukhari 2989',
    category: 'kindness',
    shortText: 'Kind words are charity',
  ),
  DailyVerse(
    text:
        'Shall I tell you of a degree greater than fasting, prayer, and sadaqah? Reconciling between people.',
    source: 'Sunan Abi Dawud 4919',
    category: 'peace',
    shortText: 'Reconcile between people',
  ),
  DailyVerse(
    text:
        'Whoever visits a sick Muslim will continue in the garden of Paradise until he returns.',
    source: 'Sahih Muslim 2568',
    category: 'care',
    shortText: 'Visit the sick',
  ),
  DailyVerse(
    text:
        'Whoever guides someone to goodness has the same reward as the one who does it.',
    source: 'Sahih Muslim 1893',
    category: 'knowledge',
    shortText: 'Guide someone to goodness',
  ),
  DailyVerse(
    text:
        'Charity does not decrease wealth, and Allah increases the servant who forgives in honor.',
    source: 'Sahih Muslim 2588',
    category: 'forgiveness',
    shortText: 'Forgiveness increases honor',
  ),
  DailyVerse(
    text: 'The coolness of my eyes was placed in prayer.',
    source: 'Sunan an-Nasa\'i 3940',
    category: 'prayer',
    shortText: 'Prayer is the coolness of the eyes',
  ),
  DailyVerse(
    text:
        'The first thing a servant will be asked about is prayer. If it is sound, the rest will be sound.',
    source: 'Jami at-Tirmidhi 413',
    category: 'prayer',
    shortText: 'Prayer is the first question',
  ),
  DailyVerse(
    text:
        'The example of the one who remembers his Lord and the one who does not is like that of the living and the dead.',
    source: 'Sahih al-Bukhari 6407',
    category: 'dhikr',
    shortText: 'Dhikr is the life of the heart',
  ),
  DailyVerse(
    text:
        'When you pass by the gardens of Paradise, graze therein. The gardens of Paradise are the circles of dhikr.',
    source: 'Jami at-Tirmidhi 3510',
    category: 'dhikr',
    shortText: 'Circles of dhikr are gardens of Jannah',
  ),
  DailyVerse(
    text:
        'No two Muslims meet and shake hands without their sins being forgiven before they part.',
    source: 'Sunan Abi Dawud 5212',
    category: 'forgiveness',
    shortText: 'Handshakes forgive sins',
  ),
  DailyVerse(
    text:
        'Kinship is suspended from the Throne. Whoever connects it, Allah connects with him.',
    source: 'Sahih al-Bukhari 5989',
    category: 'family',
    shortText: 'Connect kinship, Allah connects with you',
  ),
  DailyVerse(
    text:
        'There is no Muslim who calls upon Allah with a supplication free from sin and cutting ties, but Allah will give him one of three: His request, store it for him, or repel an evil from him.',
    source: 'Musnad Ahmad 11133',
    category: 'dua',
    shortText: 'Every dua is answered in some way',
  ),
  DailyVerse(
    text: 'The believer is not the one who curses or slanders.',
    source: 'Jami at-Tirmidhi 1977',
    category: 'character',
    shortText: 'The believer is gentle',
  ),
  DailyVerse(
    text:
        'Whoever travels a path seeking knowledge, Allah makes easy for him a path to Paradise.',
    source: 'Sahih Muslim 2699',
    category: 'knowledge',
    shortText: 'Seeking knowledge leads to Jannah',
  ),
  DailyVerse(
    text:
        'None of you truly believes until he loves for his brother what he loves for himself.',
    source: 'Sahih al-Bukhari 13',
    category: 'brotherhood',
    shortText: 'Love for your brother what you love for yourself',
  ),
  DailyVerse(
    text:
        'The best of deeds is faith in Allah and His Messenger, then prayer at its proper time, then kindness to parents.',
    source: 'Sahih al-Bukhari 527',
    category: 'deeds',
    shortText: 'Faith, prayer, and kindness to parents',
  ),
  DailyVerse(
    text:
        'Look at those below you, not above you, for it is more fitting that you not underestimate the blessings of Allah.',
    source: 'Sahih Muslim 2963',
    category: 'gratitude',
    shortText: 'Look at those below you',
  ),
  DailyVerse(
    text: 'Alhamdulillah fills the scales.',
    source: 'Sahih Muslim 223',
    category: 'gratitude',
    shortText: 'Alhamdulillah fills the scales',
  ),
  DailyVerse(
    text: 'Real patience is at the first stroke of a calamity.',
    source: 'Sahih al-Bukhari 1302',
    category: 'patience',
    shortText: 'Patience at the first shock',
  ),
  DailyVerse(
    text:
        'If you did not commit sins, Allah would wipe you out and bring people who commit sins, then ask for forgiveness, and He would forgive them.',
    source: 'Sahih Muslim 2749',
    category: 'repentance',
    shortText: 'Allah loves to forgive',
  ),
  DailyVerse(
    text:
        'Whoever says Astaghfirullah, Allah will provide a way out of every distress and ease in every hardship.',
    source: 'Sunan Abi Dawud 1518',
    category: 'repentance',
    shortText: 'Istighfar brings ease',
  ),
  DailyVerse(
    text:
        'The upper hand is better than the lower hand. The upper hand gives, the lower hand receives.',
    source: 'Sahih al-Bukhari 1427',
    category: 'charity',
    shortText: 'The giving hand is better',
  ),
  DailyVerse(
    text: 'Allah is Good and accepts only what is good.',
    source: 'Sahih Muslim 1015',
    category: 'charity',
    shortText: 'Give from what is good',
  ),
  DailyVerse(
    text: 'Removing harmful things from the road is charity.',
    source: 'Sahih Muslim 1009',
    category: 'charity',
    shortText: 'Remove harm from the road',
  ),
  DailyVerse(
    text: 'The one who severs ties of kinship will not enter Paradise.',
    source: 'Sahih al-Bukhari 5984',
    category: 'family',
    shortText: 'Keep family ties',
  ),
  DailyVerse(
    text:
        'There is no Muslim who calls upon Allah at night but He answers him.',
    source: 'Sunan Abi Dawud 1319',
    category: 'dua',
    shortText: 'The night is for dua',
  ),
  DailyVerse(
    text: 'The believer is not the one who curses or slanders.',
    source: 'Jami at-Tirmidhi 1977',
    category: 'character',
    shortText: 'Choose gentle words',
  ),
  DailyVerse(
    text:
        'Whoever believes in Allah and the Last Day, let him honor his guest.',
    source: 'Sahih al-Bukhari 6018',
    category: 'character',
    shortText: 'Honor your guest',
  ),
  DailyVerse(
    text:
        'The most beloved of people to Allah are those most beneficial to people.',
    source: 'Al-Mu\'jam al-Awsat 6192',
    category: 'service',
    shortText: 'Be beneficial to others',
  ),
  DailyVerse(
    text:
        'Whoever removes a worldly grief from a believer, Allah will remove from him one of the griefs of the Day of Resurrection.',
    source: 'Sahih Muslim 2699',
    category: 'service',
    shortText: 'Remove grief, receive relief',
  ),
  DailyVerse(
    text: 'The believer is a mirror to his brother.',
    source: 'Sunan Abi Dawud 4918',
    category: 'brotherhood',
    shortText: 'Be a mirror for your brother',
  ),
  DailyVerse(
    text:
        'Do not envy one another, do not hate one another, do not turn away from one another, and be servants of Allah as brothers.',
    source: 'Sahih al-Bukhari 6065',
    category: 'brotherhood',
    shortText: 'Be servants of Allah as brothers',
  ),
  DailyVerse(
    text:
        'The strong believer is better and more beloved to Allah than the weak believer, though there is good in both.',
    source: 'Sahih Muslim 2664',
    category: 'strength',
    shortText: 'Be a strong believer',
  ),
  DailyVerse(
    text:
        'Whoever is not grateful for small things will not be grateful for large things.',
    source: 'Musnad Ahmad 2795',
    category: 'gratitude',
    shortText: 'Be grateful for the small things',
  ),
  DailyVerse(
    text: 'The best of you are those who are best to their families.',
    source: 'Jami at-Tirmidhi 3895',
    category: 'family',
    shortText: 'Be best to your family',
  ),
  DailyVerse(
    text:
        'Whoever believes in Allah and the Last Day, let him speak good or remain silent.',
    source: 'Sahih al-Bukhari 6018',
    category: 'speech',
    shortText: 'Speak good or stay silent',
  ),
  DailyVerse(
    text:
        'The most complete of believers in faith are those with the best character.',
    source: 'Jami at-Tirmidhi 1162',
    category: 'character',
    shortText: 'Best character, most complete faith',
  ),
  DailyVerse(
    text:
        'Whoever makes dua for his brother in his absence, the angel says: Ameen, and for you the same.',
    source: 'Sahih Muslim 2732',
    category: 'dua',
    shortText: 'Dua for others returns to you',
  ),
  DailyVerse(
    text:
        'The example of the believer is like a fresh tender plant, bent by the wind - it is bent but not broken.',
    source: 'Sahih Muslim 2809',
    category: 'resilience',
    shortText: 'The believer bends but never breaks',
  ),
  DailyVerse(
    text: 'Whoever is slow to good deeds, his lineage will not speed him up.',
    source: 'Sahih Muslim 2699',
    category: 'deeds',
    shortText: 'Deeds matter, not lineage',
  ),
  DailyVerse(
    text:
        'The world is a prison for the believer and a paradise for the disbeliever.',
    source: 'Sahih Muslim 2956',
    category: 'world',
    shortText: 'This world is a prison for the believer',
  ),
  DailyVerse(
    text: 'Whoever loves to meet Allah, Allah loves to meet him.',
    source: 'Sahih al-Bukhari 6507',
    category: 'hereafter',
    shortText: 'Love to meet Allah',
  ),
  DailyVerse(
    text:
        'The first thing to be judged among the deeds of a person on the Day of Resurrection is prayer.',
    source: 'Jami at-Tirmidhi 413',
    category: 'prayer',
    shortText: 'Prayer is judged first',
  ),
  DailyVerse(
    text:
        'Whoever prays the two cool prayers (Fajr and Asr) will enter Paradise.',
    source: 'Sahih al-Bukhari 574',
    category: 'prayer',
    shortText: 'Fajr and Asr lead to Jannah',
  ),
  DailyVerse(
    text: 'The gates of heaven are opened at midday.',
    source: 'Sahih Muslim 852',
    category: 'prayer',
    shortText: 'Midday is a time of opening',
  ),
  DailyVerse(
    text: 'Whoever misses Asr, it is as if he lost his family and wealth.',
    source: 'Sahih al-Bukhari 552',
    category: 'prayer',
    shortText: 'Never miss Asr',
  ),
  DailyVerse(
    text:
        'The angels witness the Asr prayer in shifts - morning and evening angels gather at it.',
    source: 'Sahih al-Bukhari 555',
    category: 'prayer',
    shortText: 'Angels witness Asr',
  ),
  DailyVerse(
    text:
        'Whoever prays Isha in congregation, it is as if he prayed half the night.',
    source: 'Sahih Muslim 656',
    category: 'prayer',
    shortText: 'Isha in congregation is half the night',
  ),
  DailyVerse(
    text:
        'The covenant between us and them is prayer, so whoever abandons it has committed disbelief.',
    source: 'Jami at-Tirmidhi 2621',
    category: 'prayer',
    shortText: 'Prayer is the covenant',
  ),
  DailyVerse(
    text: 'Prayer is a light.',
    source: 'Sahih Muslim 223',
    category: 'prayer',
    shortText: 'Prayer is light',
  ),
  DailyVerse(
    text:
        'The five prayers are like a river flowing at your door - if you bathe in it five times a day, no dirt remains.',
    source: 'Sahih al-Bukhari 528',
    category: 'prayer',
    shortText: 'Five prayers purify like a river',
  ),
  DailyVerse(
    text: 'Allah is odd (single) and loves the odd.',
    source: 'Jami at-Tirmidhi 453',
    category: 'prayer',
    shortText: 'Allah loves the odd (Witr)',
  ),
  DailyVerse(
    text: 'May Allah have mercy on the one who prays four rak\'ahs before Asr.',
    source: 'Jami at-Tirmidhi 430',
    category: 'prayer',
    shortText: 'Four rak\'ahs before Asr',
  ),
  DailyVerse(
    text: 'Voluntary prayers fill the gaps in your obligatory prayers.',
    source: 'Jami at-Tirmidhi 413',
    category: 'prayer',
    shortText: 'Nafl completes your fardh',
  ),
  DailyVerse(
    text: 'The Prophet ﷺ never missed praying two rak\'ahs before Fajr.',
    source: 'Sahih al-Bukhari 1169',
    category: 'prayer',
    shortText: 'Two rak\'ahs before Fajr',
  ),
  DailyVerse(
    text:
        'The night prayer is the most virtuous prayer after the obligatory ones.',
    source: 'Sahih Muslim 1163',
    category: 'prayer',
    shortText: 'Tahajjud is the best voluntary',
  ),
  DailyVerse(
    text:
        'The righteous predecessors would divide their night between prayer, quran, and dua.',
    source: 'Salaf',
    category: 'night',
    shortText: 'Divide your night with worship',
  ),
  DailyVerse(
    text: 'Tahajjud is the most intimate conversation you can have.',
    source: 'Salaf',
    category: 'night',
    shortText: 'Tahajjud is intimate conversation',
  ),
  DailyVerse(
    text:
        'The Prophet ﷺ sought forgiveness from Allah more than seventy times a day.',
    source: 'Sahih al-Bukhari 6307',
    category: 'repentance',
    shortText: 'Seek forgiveness like the Prophet',
  ),
  DailyVerse(
    text:
        'The night angels take your deeds to Allah. Let your last words be dhikr.',
    source: 'Salaf',
    category: 'evening',
    shortText: 'End your day with dhikr',
  ),
  DailyVerse(
    text:
        'Recite the last two ayahs of Surah al-Baqarah at night and they will suffice you.',
    source: 'Sahih al-Bukhari 5009',
    category: 'protection',
    shortText: 'Last two ayahs of Baqarah protect you',
  ),
  DailyVerse(
    text: 'The minutes before Maghrib are precious. Spend them in istighfar.',
    source: 'Salaf',
    category: 'evening',
    shortText: 'Istighfar before Maghrib',
  ),
  DailyVerse(
    text:
        'The Prophet ﷺ said: The best words after the Quran are: SubhanAllah, Alhamdulillah, Allahu Akbar, La ilaha illallah.',
    source: 'Sunan an-Nasa\'i 9259',
    category: 'dhikr',
    shortText: 'The best words after the Quran',
  ),
  DailyVerse(
    text:
        'Whoever says in the evening A\'udhu bi kalimatillahi\'t-tammati min sharri ma khalaq three times, nothing will harm him that night.',
    source: 'Sahih Muslim 2709',
    category: 'protection',
    shortText: 'Evening protection words',
  ),
  DailyVerse(
    text:
        'The Prophet ﷺ taught us to seek refuge with the Perfect Words of Allah in the morning - nothing will harm you after that.',
    source: 'Sahih Muslim 2708',
    category: 'protection',
    shortText: 'Morning refuge with Allah\'s words',
  ),
  DailyVerse(
    text:
        'Begin your morning with Alhamdulillah - gratitude opens the doors of more blessings.',
    source: 'Salaf',
    category: 'gratitude',
    shortText: 'Start with Alhamdulillah',
  ),
  DailyVerse(
    text:
        'The Prophet ﷺ said: The two rak\'ahs of Fajr are better than the world and everything in it.',
    source: 'Sahih Muslim 725',
    category: 'prayer',
    shortText: 'Fajr sunnah is better than the world',
  ),
  DailyVerse(
    text: 'Whoever prays Fajr is under the protection of Allah.',
    source: 'Sahih Muslim 657',
    category: 'prayer',
    shortText: 'Fajr brings divine protection',
  ),
  DailyVerse(
    text:
        'The Prophet ﷺ said: The best prayer after the obligatory prayers is the night prayer.',
    source: 'Sahih Muslim 1163',
    category: 'prayer',
    shortText: 'Night prayer is the best',
  ),
  DailyVerse(
    text:
        'For every joint of the body, give charity each morning - two rak\'ahs of Duha suffice.',
    source: 'Sahih Muslim 720',
    category: 'prayer',
    shortText: 'Duha is charity for every joint',
  ),
  DailyVerse(
    text:
        'Allah has added a prayer for you - the Witr. Pray it, even a single rak\'ah.',
    source: 'Musnad Ahmad 24069',
    category: 'prayer',
    shortText: 'Pray Witr before sleep',
  ),
  DailyVerse(
    text:
        'Whoever prays Fajr in congregation, then sits remembering Allah until the sun rises, then prays two rak\'ahs, will have a complete Hajj and Umrah reward.',
    source: 'Jami at-Tirmidhi 586',
    category: 'prayer',
    shortText: 'Ishraq brings Hajj and Umrah reward',
  ),
  DailyVerse(
    text:
        'Recite Ayat al-Kursi in the morning and you will be protected until the evening.',
    source: 'Sahih al-Bukhari 2311',
    category: 'protection',
    shortText: 'Ayat al-Kursi protects you',
  ),
  DailyVerse(
    text: 'Whoever says Bismillah in the morning, nothing will harm him.',
    source: 'Jami at-Tirmidhi 3388',
    category: 'protection',
    shortText: 'Begin with Bismillah',
  ),
  DailyVerse(
    text:
        'Say SubhanAllahi wa bihamdih 100 times in the morning - your sins will be forgiven even if they were like the foam of the sea.',
    source: 'Sahih al-Bukhari 6405',
    category: 'dhikr',
    shortText: 'Morning tasbih forgives sins',
  ),
  DailyVerse(
    text:
        'The Prophet ﷺ said Friday is the best day on which the sun has ever risen.',
    source: 'Sahih Muslim 854',
    category: 'friday',
    shortText: 'Friday is the best day',
  ),
  DailyVerse(
    text:
        'Send abundant salawat upon me on Friday - your salawat are presented to me.',
    source: 'Sunan Abi Dawud 1047',
    category: 'friday',
    shortText: 'Send salawat on Friday',
  ),
  DailyVerse(
    text:
        'Whoever recites Surah Al-Kahf on Friday, a light will shine for him between the two Fridays.',
    source: 'Al-Bayhaqi 6010',
    category: 'friday',
    shortText: 'Surah Al-Kahf is a light',
  ),
  DailyVerse(
    text:
        'There is an hour on Friday when no Muslim asks Allah for something but He gives it.',
    source: 'Sahih al-Bukhari 935',
    category: 'friday',
    shortText: 'Seek the hour of acceptance',
  ),
  DailyVerse(
    text:
        'Whoever fasts a day for the sake of Allah, Allah will distance his face from the Fire by seventy autumns.',
    source: 'Sahih Muslim 1153',
    category: 'fasting',
    shortText: 'Fasting distances you from Fire',
  ),
  DailyVerse(
    text:
        'The Prophet ﷺ used to fast Mondays and Thursdays - the days when deeds are presented to Allah.',
    source: 'Jami at-Tirmidhi 747',
    category: 'fasting',
    shortText: 'Fast Mondays and Thursdays',
  ),
  DailyVerse(
    text:
        'Fast the 13th, 14th, and 15th of the Islamic month - the white days - and receive the reward of fasting the whole month.',
    source: 'Sunan an-Nasa\'i 2419',
    category: 'fasting',
    shortText: 'Fast the white days',
  ),
  DailyVerse(
    text:
        'In Ramadan, the gates of Paradise are opened and the gates of Hell are closed.',
    source: 'Sahih al-Bukhari 1899',
    category: 'ramadan',
    shortText: 'Ramadan opens the gates of Jannah',
  ),
  DailyVerse(
    text: 'The Night of Decree is better than a thousand months.',
    source: 'Quran 97:3',
    category: 'ramadan',
    shortText: 'Laylatul Qadr is better than 1000 months',
  ),
  DailyVerse(
    text:
        'Fasting the day of Arafah expiates the sins of the past and coming year.',
    source: 'Sahih Muslim 1162',
    category: 'fasting',
    shortText: 'Arafah expiates two years of sins',
  ),
  DailyVerse(
    text: 'Fasting Ashura expiates the sins of the past year.',
    source: 'Sahih Muslim 1162',
    category: 'fasting',
    shortText: 'Ashura expiates the past year',
  ),
  DailyVerse(
    text:
        'Allah descends to the lowest heaven in the last third of the night and asks: Who is calling upon Me so I may answer?',
    source: 'Sahih al-Bukhari 1145',
    category: 'night',
    shortText: 'The last third of the night is special',
  ),
  DailyVerse(
    text: 'The dua of a Muslim for his brother in his absence is answered.',
    source: 'Sahih Muslim 2732',
    category: 'dua',
    shortText: 'Pray for others in their absence',
  ),
  DailyVerse(
    text: 'Allah helps the servant as long as the servant helps his brother.',
    source: 'Sahih Muslim 2699',
    category: 'help',
    shortText: 'Help others, Allah helps you',
  ),
  DailyVerse(
    text: 'Whoever feeds a fasting person gets the same reward.',
    source: 'Jami at-Tirmidhi 807',
    category: 'charity',
    shortText: 'Feed a fasting person',
  ),
  DailyVerse(
    text:
        'Every tasbih is sadaqah, every takbir is sadaqah, every tahmid is sadaqah.',
    source: 'Sahih Muslim 720',
    category: 'dhikr',
    shortText: 'Dhikr is charity for your soul',
  ),
  DailyVerse(
    text: 'Kind speech is sadaqah.',
    source: 'Sahih al-Bukhari 2989',
    category: 'kindness',
    shortText: 'Kind words are charity',
  ),
  DailyVerse(
    text:
        'Shall I tell you of a degree greater than fasting, prayer, and sadaqah? Reconciling between people.',
    source: 'Sunan Abi Dawud 4919',
    category: 'peace',
    shortText: 'Reconcile between people',
  ),
  DailyVerse(
    text:
        'Whoever visits a sick Muslim will continue in the garden of Paradise until he returns.',
    source: 'Sahih Muslim 2568',
    category: 'care',
    shortText: 'Visit the sick',
  ),
  DailyVerse(
    text:
        'Whoever guides someone to goodness has the same reward as the one who does it.',
    source: 'Sahih Muslim 1893',
    category: 'knowledge',
    shortText: 'Guide someone to goodness',
  ),
  DailyVerse(
    text:
        'Charity does not decrease wealth, and Allah increases the servant who forgives in honor.',
    source: 'Sahih Muslim 2588',
    category: 'forgiveness',
    shortText: 'Forgiveness increases honor',
  ),
  DailyVerse(
    text: 'The coolness of my eyes was placed in prayer.',
    source: 'Sunan an-Nasa\'i 3940',
    category: 'prayer',
    shortText: 'Prayer is the coolness of the eyes',
  ),
  DailyVerse(
    text:
        'The first thing a servant will be asked about is prayer. If it is sound, the rest will be sound.',
    source: 'Jami at-Tirmidhi 413',
    category: 'prayer',
    shortText: 'Prayer is the first question',
  ),
  DailyVerse(
    text:
        'The example of the one who remembers his Lord and the one who does not is like that of the living and the dead.',
    source: 'Sahih al-Bukhari 6407',
    category: 'dhikr',
    shortText: 'Dhikr is the life of the heart',
  ),
  DailyVerse(
    text:
        'When you pass by the gardens of Paradise, graze therein. The gardens of Paradise are the circles of dhikr.',
    source: 'Jami at-Tirmidhi 3510',
    category: 'dhikr',
    shortText: 'Circles of dhikr are gardens of Jannah',
  ),
  DailyVerse(
    text:
        'No two Muslims meet and shake hands without their sins being forgiven before they part.',
    source: 'Sunan Abi Dawud 5212',
    category: 'forgiveness',
    shortText: 'Handshakes forgive sins',
  ),
  DailyVerse(
    text:
        'Kinship is suspended from the Throne. Whoever connects it, Allah connects with him.',
    source: 'Sahih al-Bukhari 5989',
    category: 'family',
    shortText: 'Connect kinship, Allah connects with you',
  ),
  DailyVerse(
    text:
        'There is no Muslim who calls upon Allah with a supplication free from sin and cutting ties, but Allah will give him one of three: His request, store it for him, or repel an evil from him.',
    source: 'Musnad Ahmad 11133',
    category: 'dua',
    shortText: 'Every dua is answered in some way',
  ),
  DailyVerse(
    text: 'The believer is not the one who curses or slanders.',
    source: 'Jami at-Tirmidhi 1977',
    category: 'character',
    shortText: 'The believer is gentle',
  ),
  DailyVerse(
    text:
        'Whoever travels a path seeking knowledge, Allah makes easy for him a path to Paradise.',
    source: 'Sahih Muslim 2699',
    category: 'knowledge',
    shortText: 'Seeking knowledge leads to Jannah',
  ),
  DailyVerse(
    text:
        'None of you truly believes until he loves for his brother what he loves for himself.',
    source: 'Sahih al-Bukhari 13',
    category: 'brotherhood',
    shortText: 'Love for your brother what you love for yourself',
  ),
  DailyVerse(
    text:
        'The best of deeds is faith in Allah and His Messenger, then prayer at its proper time, then kindness to parents.',
    source: 'Sahih al-Bukhari 527',
    category: 'deeds',
    shortText: 'Faith, prayer, and kindness to parents',
  ),
  DailyVerse(
    text:
        'Look at those below you, not above you, for it is more fitting that you not underestimate the blessings of Allah.',
    source: 'Sahih Muslim 2963',
    category: 'gratitude',
    shortText: 'Look at those below you',
  ),
  DailyVerse(
    text: 'Alhamdulillah fills the scales.',
    source: 'Sahih Muslim 223',
    category: 'gratitude',
    shortText: 'Alhamdulillah fills the scales',
  ),
  DailyVerse(
    text: 'Real patience is at the first stroke of a calamity.',
    source: 'Sahih al-Bukhari 1302',
    category: 'patience',
    shortText: 'Patience at the first shock',
  ),
  DailyVerse(
    text:
        'If you did not commit sins, Allah would wipe you out and bring people who commit sins, then ask for forgiveness, and He would forgive them.',
    source: 'Sahih Muslim 2749',
    category: 'repentance',
    shortText: 'Allah loves to forgive',
  ),
  DailyVerse(
    text:
        'Whoever says Astaghfirullah, Allah will provide a way out of every distress and ease in every hardship.',
    source: 'Sunan Abi Dawud 1518',
    category: 'repentance',
    shortText: 'Istighfar brings ease',
  ),
  DailyVerse(
    text:
        'The upper hand is better than the lower hand. The upper hand gives, the lower hand receives.',
    source: 'Sahih al-Bukhari 1427',
    category: 'charity',
    shortText: 'The giving hand is better',
  ),
  DailyVerse(
    text: 'Allah is Good and accepts only what is good.',
    source: 'Sahih Muslim 1015',
    category: 'charity',
    shortText: 'Give from what is good',
  ),
  DailyVerse(
    text: 'Removing harmful things from the road is charity.',
    source: 'Sahih Muslim 1009',
    category: 'charity',
    shortText: 'Remove harm from the road',
  ),
  DailyVerse(
    text:
        'There is no Muslim who calls upon Allah at night but He answers him.',
    source: 'Sunan Abi Dawud 1319',
    category: 'dua',
    shortText: 'The night is for dua',
  ),
  DailyVerse(
    text:
        'Whoever believes in Allah and the Last Day, let him honor his guest.',
    source: 'Sahih al-Bukhari 6018',
    category: 'character',
    shortText: 'Honor your guest',
  ),
  DailyVerse(
    text:
        'The most beloved of people to Allah are those most beneficial to people.',
    source: 'Al-Mu\'jam al-Awsat 6192',
    category: 'service',
    shortText: 'Be beneficial to others',
  ),
  DailyVerse(
    text:
        'Whoever removes a worldly grief from a believer, Allah will remove from him one of the griefs of the Day of Resurrection.',
    source: 'Sahih Muslim 2699',
    category: 'service',
    shortText: 'Remove grief, receive relief',
  ),
  DailyVerse(
    text: 'The believer is a mirror to his brother.',
    source: 'Sunan Abi Dawud 4918',
    category: 'brotherhood',
    shortText: 'Be a mirror for your brother',
  ),
  DailyVerse(
    text:
        'Do not envy one another, do not hate one another, do not turn away from one another, and be servants of Allah as brothers.',
    source: 'Sahih al-Bukhari 6065',
    category: 'brotherhood',
    shortText: 'Be servants of Allah as brothers',
  ),
  DailyVerse(
    text:
        'The strong believer is better and more beloved to Allah than the weak believer, though there is good in both.',
    source: 'Sahih Muslim 2664',
    category: 'strength',
    shortText: 'Be a strong believer',
  ),
  DailyVerse(
    text:
        'Whoever is not grateful for small things will not be grateful for large things.',
    source: 'Musnad Ahmad 2795',
    category: 'gratitude',
    shortText: 'Be grateful for the small things',
  ),
  DailyVerse(
    text: 'The best of you are those who are best to their families.',
    source: 'Jami at-Tirmidhi 3895',
    category: 'family',
    shortText: 'Be best to your family',
  ),
  DailyVerse(
    text:
        'The most complete of believers in faith are those with the best character.',
    source: 'Jami at-Tirmidhi 1162',
    category: 'character',
    shortText: 'Best character, most complete faith',
  ),
  DailyVerse(
    text:
        'Whoever makes dua for his brother in his absence, the angel says: Ameen, and for you the same.',
    source: 'Sahih Muslim 2732',
    category: 'dua',
    shortText: 'Dua for others returns to you',
  ),
  DailyVerse(
    text:
        'The example of the believer is like a fresh tender plant, bent by the wind - it is bent but not broken.',
    source: 'Sahih Muslim 2809',
    category: 'resilience',
    shortText: 'The believer bends but never breaks',
  ),
  DailyVerse(
    text: 'Whoever is slow to good deeds, his lineage will not speed him up.',
    source: 'Sahih Muslim 2699',
    category: 'deeds',
    shortText: 'Deeds matter, not lineage',
  ),
  DailyVerse(
    text:
        'The world is a prison for the believer and a paradise for the disbeliever.',
    source: 'Sahih Muslim 2956',
    category: 'world',
    shortText: 'This world is a prison for the believer',
  ),
  DailyVerse(
    text: 'Whoever loves to meet Allah, Allah loves to meet him.',
    source: 'Sahih al-Bukhari 6507',
    category: 'hereafter',
    shortText: 'Love to meet Allah',
  ),
  DailyVerse(
    text:
        'The first thing to be judged among the deeds of a person on the Day of Resurrection is prayer.',
    source: 'Jami at-Tirmidhi 413',
    category: 'prayer',
    shortText: 'Prayer is judged first',
  ),
  DailyVerse(
    text:
        'Whoever prays the two cool prayers (Fajr and Asr) will enter Paradise.',
    source: 'Sahih al-Bukhari 574',
    category: 'prayer',
    shortText: 'Fajr and Asr lead to Jannah',
  ),
  DailyVerse(
    text: 'The gates of heaven are opened at midday.',
    source: 'Sahih Muslim 852',
    category: 'prayer',
    shortText: 'Midday is a time of opening',
  ),
  DailyVerse(
    text: 'Whoever misses Asr, it is as if he lost his family and wealth.',
    source: 'Sahih al-Bukhari 552',
    category: 'prayer',
    shortText: 'Never miss Asr',
  ),
  DailyVerse(
    text:
        'The angels witness the Asr prayer in shifts - morning and evening angels gather at it.',
    source: 'Sahih al-Bukhari 555',
    category: 'prayer',
    shortText: 'Angels witness Asr',
  ),
  DailyVerse(
    text:
        'Whoever prays Isha in congregation, it is as if he prayed half the night.',
    source: 'Sahih Muslim 656',
    category: 'prayer',
    shortText: 'Isha in congregation is half the night',
  ),
  DailyVerse(
    text:
        'The covenant between us and them is prayer, so whoever abandons it has committed disbelief.',
    source: 'Jami at-Tirmidhi 2621',
    category: 'prayer',
    shortText: 'Prayer is the covenant',
  ),
  DailyVerse(
    text: 'Prayer is a light.',
    source: 'Sahih Muslim 223',
    category: 'prayer',
    shortText: 'Prayer is light',
  ),
  DailyVerse(
    text:
        'The five prayers are like a river flowing at your door - if you bathe in it five times a day, no dirt remains.',
    source: 'Sahih al-Bukhari 528',
    category: 'prayer',
    shortText: 'Five prayers purify like a river',
  ),
  DailyVerse(
    text: 'Allah is odd (single) and loves the odd.',
    source: 'Jami at-Tirmidhi 453',
    category: 'prayer',
    shortText: 'Allah loves the odd (Witr)',
  ),

  DailyVerse(
    text: 'May Allah have mercy on the one who prays four rak\'ahs before Asr.',
    source: 'Jami at-Tirmidhi 430',
    category: 'prayer',
    shortText: 'Four rak\'ahs before Asr',
  ),
  DailyVerse(
    text: 'Voluntary prayers fill the gaps in your obligatory prayers.',
    source: 'Jami at-Tirmidhi 413',
    category: 'prayer',
    shortText: 'Nafl completes your fardh',
  ),
  DailyVerse(
    text: 'The Prophet ﷺ never missed praying two rak\'ahs before Fajr.',
    source: 'Sahih al-Bukhari 1169',
    category: 'prayer',
    shortText: 'Two rak\'ahs before Fajr',
  ),
  DailyVerse(
    text:
        'The night prayer is the most virtuous prayer after the obligatory ones.',
    source: 'Sahih Muslim 1163',
    category: 'prayer',
    shortText: 'Tahajjud is the best voluntary',
  ),
  DailyVerse(
    text:
        'The righteous predecessors would divide their night between prayer, quran, and dua.',
    source: 'Salaf',
    category: 'night',
    shortText: 'Divide your night with worship',
  ),
  DailyVerse(
    text: 'Tahajjud is the most intimate conversation you can have.',
    source: 'Salaf',
    category: 'night',
    shortText: 'Tahajjud is intimate conversation',
  ),
  DailyVerse(
    text:
        'The Prophet ﷺ sought forgiveness from Allah more than seventy times a day.',
    source: 'Sahih al-Bukhari 6307',
    category: 'repentance',
    shortText: 'Seek forgiveness like the Prophet',
  ),
  DailyVerse(
    text:
        'The night angels take your deeds to Allah. Let your last words be dhikr.',
    source: 'Salaf',
    category: 'evening',
    shortText: 'End your day with dhikr',
  ),
  DailyVerse(
    text:
        'Recite the last two ayahs of Surah al-Baqarah at night and they will suffice you.',
    source: 'Sahih al-Bukhari 5009',
    category: 'protection',
    shortText: 'Last two ayahs of Baqarah protect you',
  ),
  DailyVerse(
    text: 'The minutes before Maghrib are precious. Spend them in istighfar.',
    source: 'Salaf',
    category: 'evening',
    shortText: 'Istighfar before Maghrib',
  ),
  DailyVerse(
    text:
        'The Prophet ﷺ said: The best words after the Quran are: SubhanAllah, Alhamdulillah, Allahu Akbar, La ilaha illallah.',
    source: 'Sunan an-Nasa\'i 9259',
    category: 'dhikr',
    shortText: 'The best words after the Quran',
  ),
  DailyVerse(
    text:
        'Whoever says in the evening A\'udhu bi kalimatillahi\'t-tammati min sharri ma khalaq three times, nothing will harm him that night.',
    source: 'Sahih Muslim 2709',
    category: 'protection',
    shortText: 'Evening protection words',
  ),
  DailyVerse(
    text:
        'The Prophet ﷺ taught us to seek refuge with the Perfect Words of Allah in the morning - nothing will harm you after that.',
    source: 'Sahih Muslim 2708',
    category: 'protection',
    shortText: 'Morning refuge with Allah\'s words',
  ),
  DailyVerse(
    text:
        'Begin your morning with Alhamdulillah - gratitude opens the doors of more blessings.',
    source: 'Salaf',
    category: 'gratitude',
    shortText: 'Start with Alhamdulillah',
  ),
];

DailyVerse todaysVerse([DateTime? at]) =>
    verseForTimeSlot(at ?? DateTime.now());

DailyVerse verseForTimeSlot(DateTime now, {int rotation = 0}) {
  final category = _preferredCategory(now);
  final pool = kDailyVerses.where((v) => v.category == category).toList();
  final sourcePool = pool.isNotEmpty ? pool : kDailyVerses;
  final slot =
      now.hour < 11
          ? 0
          : now.hour < 16
          ? 1
          : now.hour < 21
          ? 2
          : 3;
  final index =
      (now.year * 366 + now.month * 31 + now.day + slot + rotation) %
      sourcePool.length;
  return sourcePool[index];
}

String _preferredCategory(DateTime now) {
  final minuteOfDay = now.hour * 60 + now.minute;
  const prayerWindows = [
    5 * 60 + 15,
    12 * 60 + 15,
    15 * 60 + 45,
    18 * 60 + 45,
    20 * 60 + 15,
  ];
  for (final prayerMinute in prayerWindows) {
    if ((minuteOfDay - prayerMinute).abs() <= 35) return 'prayer';
  }
  if (now.hour < 10) return 'remembrance';
  if (now.weekday == DateTime.friday && now.hour < 18) return 'quran';
  if (now.hour >= 21 || now.hour < 4) return 'protection';
  final cycle = (now.day + (now.hour ~/ 8)) % 4;
  return const ['peace', 'mercy', 'gratitude', 'trust'][cycle];
}
