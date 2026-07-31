import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has completed goal setup during onboarding.
final goalSetupCompleteProvider = StateProvider<bool>((ref) => false);

/// Tracks the last monthly review date (YYYY-MM format).
final lastMonthlyReviewProvider = StateProvider<String?>((ref) => null);

/// Tracks whether the monthly review has been shown this month.
final monthlyReviewShownProvider = StateProvider<bool>((ref) => false);

/// Personal goal suggestions for onboarding
const List<Map<String, dynamic>> kPersonalGoalSuggestions = [
  {
    'title': 'Complete 100 acts of charity',
    'subtitle': 'A beautiful milestone of giving',
    'target': 100,
    'icon': 'volunteer_activism',
  },
  {
    'title': 'Maintain a 30-day consistency streak',
    'subtitle': 'Build a gentle daily rhythm',
    'target': 30,
    'icon': 'local_fire_department',
  },
  {
    'title': 'Read 10 Islamic books',
    'subtitle': 'Nourish your mind and soul',
    'target': 10,
    'icon': 'menu_book',
  },
  {
    'title': 'Memorize selected duas',
    'subtitle': "Keep the Prophet's ﷺ teachings close",
    'target': 20,
    'icon': 'auto_stories',
  },
];

/// Family goal suggestions for onboarding
const List<Map<String, dynamic>> kFamilyGoalSuggestions = [
  {
    'title': 'Reach 500 collective good deeds',
    'subtitle': 'Together, every act counts',
    'target': 500,
    'icon': 'groups',
  },
  {
    'title': 'Complete a family charity challenge',
    'subtitle': 'Give as a family, grow as a family',
    'target': 50,
    'icon': 'volunteer_activism',
  },
  {
    'title': 'Finish a shared reading goal',
    'subtitle': 'Read and reflect together',
    'target': 5,
    'icon': 'menu_book',
  },
  {
    'title': 'Achieve a monthly consistency target',
    'subtitle': 'Show up together, every day',
    'target': 30,
    'icon': 'calendar_month',
  },
];

Future<void> saveGoalSetupComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('mizan.goal_setup_complete', true);
}

Future<bool> isGoalSetupComplete() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('mizan.goal_setup_complete') ?? false;
}

Future<void> saveLastMonthlyReview(String yearMonth) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('mizan.last_monthly_review', yearMonth);
}

Future<String?> getLastMonthlyReview() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('mizan.last_monthly_review');
}