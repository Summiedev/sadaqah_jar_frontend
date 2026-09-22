/// Resolves a safe destination when Android back has no navigator history.
///
/// Normal navigation should always pop first. This is only for route entries
/// opened as replacements (for example a cold-start deep link), where there is
/// no page in the navigator to return to.
String? systemBackFallback({
  required String path,
  required bool isAuthenticated,
  required bool onboardingComplete,
}) {
  final normalizedPath = path.isEmpty ? '/home' : path;

  if (!isAuthenticated) {
    if (normalizedPath == '/auth' || normalizedPath == '/onboarding') {
      return null;
    }
    return onboardingComplete ? '/auth' : '/onboarding';
  }

  if (normalizedPath == '/home') return null;

  if (normalizedPath.startsWith('/family/')) return '/family';
  if (normalizedPath == '/family') return '/home';

  if (normalizedPath.startsWith('/journey/')) return '/journey';
  if (normalizedPath == '/journey') return '/home';

  if (normalizedPath.startsWith('/admin/')) return '/admin';
  if (normalizedPath == '/admin') return '/home';

  // Top-level destinations and authenticated flows that do not have a more
  // specific parent return to the app's actual root instead of exiting.
  return '/home';
}
