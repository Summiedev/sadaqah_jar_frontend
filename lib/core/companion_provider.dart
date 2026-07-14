import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected companion mode, shared across onboarding and profile.
/// 0 = Personal Sanctuary, 1 = Family Household, 2 = Integrated Balanced.
final companionModeProvider = StateProvider<int>((ref) => 1);
