import 'dart:convert';

/// Supported notification destination types.
///
/// Whitelisted destinations only - never blindly navigate to an arbitrary
/// backend-provided path.
enum NotificationDestination {
  family,
  familyReflection,
  familyPrayers,
  familyGoals,
  familyTimeline,
  familyMembers,
  familySettings,
  morningAdhkar,
  eveningAdhkar,
  addSadaqah,
  donation,
  book,
  reflection,
  notificationCenter,
  journey,
  quran,
  home,
}

extension NotificationDestinationExtension on NotificationDestination {
  String get routePath {
    switch (this) {
      case NotificationDestination.family:
        return '/family';
      case NotificationDestination.familyReflection:
        return '/family/reflections';
      case NotificationDestination.familyPrayers:
        return '/family/prayers';
      case NotificationDestination.familyGoals:
        return '/family/goals';
      case NotificationDestination.familyTimeline:
        return '/family/timeline';
      case NotificationDestination.familyMembers:
        return '/family/members';
      case NotificationDestination.familySettings:
        return '/family/settings';
      case NotificationDestination.morningAdhkar:
        return '/journey/adhkar/morning';
      case NotificationDestination.eveningAdhkar:
        return '/journey/adhkar/evening';
      case NotificationDestination.addSadaqah:
        return '/home?open=sadaqah';
      case NotificationDestination.donation:
        return '/charities';
      case NotificationDestination.book:
        return '/books';
      case NotificationDestination.reflection:
        return '/journey';
      case NotificationDestination.notificationCenter:
        return '/notifications';
      case NotificationDestination.journey:
        return '/journey';
      case NotificationDestination.quran:
        return '/journey?tab=quran';
      case NotificationDestination.home:
        return '/home';
    }
  }
}

/// A resolved, validated notification destination. If [resourceId] is provided
/// and valid, it is appended to the route path.
class ResolvedNotificationDestination {
  const ResolvedNotificationDestination({
    required this.destination,
    this.resourceId,
    this.extraQuery,
  });

  final NotificationDestination destination;
  final String? resourceId;
  final Map<String, String>? extraQuery;

  /// Builds the full safe route path for this destination.
  String get route {
    var path = destination.routePath;
    if (resourceId != null && resourceId!.isNotEmpty) {
      path = '$path/$resourceId';
    }
    if (extraQuery != null && extraQuery!.isNotEmpty) {
      final query = extraQuery!.entries
          .map(
            (e) =>
                '${Uri.encodeQueryComponent(e.key)}='
                '${Uri.encodeQueryComponent(e.value)}',
          )
          .join('&');
      path = '$path?$query';
    }
    return path;
  }
}

/// Central notification payload resolver.
///
/// Accepts a decoded notification payload map and returns a validated
/// [ResolvedNotificationDestination], or null if the payload does not map to a
/// supported, safe destination (unknown type, invalid/missing ID, etc.).
///
/// Never navigates to an arbitrary backend-provided path.
ResolvedNotificationDestination? resolveNotificationDestination(
  Map<String, dynamic> payload,
) {
  if (payload.isEmpty) return null;

  // Support both `type` and `notification_type` keys (backend may send either).
  final type = (payload['type'] ?? payload['notification_type'])?.toString();

  // Validate resource IDs. IDs are ints for family routes; books use ints.
  String? id;
  final rawId = payload['id'] ?? payload['resource_id'] ?? payload['target_id'];
  if (rawId != null) {
    final idStr = rawId.toString().trim();
    if (idStr.isNotEmpty) {
      // Reject non-numeric IDs for routes that require integer IDs.
      if (int.tryParse(idStr) == null) {
        return null;
      }
      id = idStr;
    }
  }

  switch (type) {
    case 'adhkar':
      final key = payload['template_key']?.toString();
      if (key != null && key.contains('morning')) {
        return const ResolvedNotificationDestination(
          destination: NotificationDestination.morningAdhkar,
        );
      }
      if (key != null && key.contains('evening')) {
        return const ResolvedNotificationDestination(
          destination: NotificationDestination.eveningAdhkar,
        );
      }
      return const ResolvedNotificationDestination(
        destination: NotificationDestination.journey,
      );

    case 'sadaqah_act':
      return const ResolvedNotificationDestination(
        destination: NotificationDestination.addSadaqah,
      );

    case 'reading':
      return const ResolvedNotificationDestination(
        destination: NotificationDestination.quran,
      );

    case 'family':
    case 'family_jar':
    case 'family_created':
      // Family routes require an ID.
      if (id == null) return null;
      return ResolvedNotificationDestination(
        destination: NotificationDestination.family,
        resourceId: id,
      );

    case 'family_reflection':
    case 'family_reflections':
      if (id == null) return null;
      return ResolvedNotificationDestination(
        destination: NotificationDestination.familyReflection,
        resourceId: id,
      );

    case 'family_prayer':
    case 'family_prayers':
      if (id == null) return null;
      return ResolvedNotificationDestination(
        destination: NotificationDestination.familyPrayers,
        resourceId: id,
      );

    case 'family_goal':
    case 'family_goals':
      if (id == null) return null;
      return ResolvedNotificationDestination(
        destination: NotificationDestination.familyGoals,
        resourceId: id,
      );

    case 'family_timeline':
    case 'family_activity':
      if (id == null) return null;
      return ResolvedNotificationDestination(
        destination: NotificationDestination.familyTimeline,
        resourceId: id,
      );

    case 'family_members':
      if (id == null) return null;
      return ResolvedNotificationDestination(
        destination: NotificationDestination.familyMembers,
        resourceId: id,
      );

    case 'family_settings':
      if (id == null) return null;
      return ResolvedNotificationDestination(
        destination: NotificationDestination.familySettings,
        resourceId: id,
      );

    case 'donation':
    case 'charity':
    case 'donation_campaign':
      // Donations/charities go to the charities list; a specific charity
      // would need a charity detail route which may not exist → go to list.
      return const ResolvedNotificationDestination(
        destination: NotificationDestination.donation,
      );

    case 'book':
    case 'new_book':
    case 'book_available':
      return const ResolvedNotificationDestination(
        destination: NotificationDestination.book,
      );

    case 'reflection':
    case 'journey_reflection':
      return const ResolvedNotificationDestination(
        destination: NotificationDestination.reflection,
      );

    case 'notification':
    case 'notification_center':
      return const ResolvedNotificationDestination(
        destination: NotificationDestination.notificationCenter,
      );

    case 'journey':
      return const ResolvedNotificationDestination(
        destination: NotificationDestination.journey,
      );

    case 'quran':
      return const ResolvedNotificationDestination(
        destination: NotificationDestination.quran,
      );

    case 'home':
      return const ResolvedNotificationDestination(
        destination: NotificationDestination.home,
      );

    default:
      // Unknown/unsupported type - ignore safely.
      return null;
  }
}

/// Decodes a persisted notification payload string.
///
/// The payload is stored as JSON. Returns an empty map for malformed JSON or
/// non-map values so old/corrupt payloads never crash the app.
Map<String, dynamic> decodeNotificationPayload(String? raw) {
  if (raw == null || raw.isEmpty) return const {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return const {};
  } catch (_) {
    // Malformed JSON - ignore safely.
    return const {};
  }
}

/// Encodes a notification payload map to a JSON string for persistence.
String encodeNotificationPayload(Map<String, dynamic> payload) {
  try {
    return jsonEncode(payload);
  } catch (_) {
    return '';
  }
}
