import 'package:flutter_test/flutter_test.dart';
import 'package:sadaqah_jar/core/back_navigation.dart';

void main() {
  group('systemBackFallback', () {
    test('only permits exit from the authenticated home root', () {
      expect(
        systemBackFallback(
          path: '/home',
          isAuthenticated: true,
          onboardingComplete: true,
        ),
        isNull,
      );
    });

    test('returns nested Family screens to Family', () {
      expect(
        systemBackFallback(
          path: '/family/reflections/42',
          isAuthenticated: true,
          onboardingComplete: true,
        ),
        '/family',
      );
    });

    test('returns Journey drills to Journey', () {
      expect(
        systemBackFallback(
          path: '/journey/adhkar/morning',
          isAuthenticated: true,
          onboardingComplete: true,
        ),
        '/journey',
      );
    });

    test('returns admin drills to Admin', () {
      expect(
        systemBackFallback(
          path: '/admin/broadcasts',
          isAuthenticated: true,
          onboardingComplete: true,
        ),
        '/admin',
      );
    });

    test('returns an authenticated top-level orphan to Home', () {
      expect(
        systemBackFallback(
          path: '/notifications',
          isAuthenticated: true,
          onboardingComplete: true,
        ),
        '/home',
      );
    });

    test('returns anonymous deep links to the appropriate auth entry point', () {
      expect(
        systemBackFallback(
          path: '/journey',
          isAuthenticated: false,
          onboardingComplete: true,
        ),
        '/auth',
      );
      expect(
        systemBackFallback(
          path: '/auth',
          isAuthenticated: false,
          onboardingComplete: true,
        ),
        isNull,
      );
    });
  });
}
