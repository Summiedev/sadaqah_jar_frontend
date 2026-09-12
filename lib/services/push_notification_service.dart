import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backend_api.dart';
import 'device_timezone.dart';
import 'location_service.dart';
import 'local_reminder_service.dart';
import '../firebase_options.dart';

const _kPendingPayloadKey = 'pending_notification_payload';

/// Persists an FCM data map as structured JSON. Never loses `=`, `&`, URLs,
/// or Unicode. Malformed/legacy payloads are ignored safely.
Future<void> persistFcmPayload(Map<String, dynamic> data) async {
  if (data.isEmpty) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPendingPayloadKey, jsonEncode(data));
  } catch (_) {
    // Corrupt/malformed local storage must never crash the handler.
  }
}

/// Background handler for Firebase messages. Runs in the background isolate.
///
/// [H2] Display policy:
/// * Message with a system `notification` payload  -> FCM/OS already displays
///   it. We only persist the routing payload; we MUST NOT show a duplicate
///   local notification.
/// * Data-only push  -> we intentionally display a local notification because
///   the OS will not show anything otherwise.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    final data = Map<String, dynamic>.from(message.data);
    await persistFcmPayload(data);

    final notification = message.notification;
    if (notification != null) {
      // System notification: let FCM/OS display it. Never duplicate.
      return;
    }

    final title = data['title']?.toString();
    final body = data['body']?.toString();
    if (title == null || title.isEmpty || body == null || body.isEmpty) {
      // payload-only push: routing is persisted; nothing to display.
      return;
    }

    // Data-only push requiring local display.
    await LocalReminderService.instance.showNow(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      payload: jsonEncode(data),
    );
  } catch (error, stack) {
    debugPrint('FCM background handling failed: $error');
    if (kDebugMode) debugPrintStack(stackTrace: stack);
    // Background handler must never throw into the framework.
  }
}

/// Opt-in push setup. Call only from an explicit reminder-enable action.
class PushNotificationService {
  PushNotificationService._();

  static final instance = PushNotificationService._();
  static const _deviceIdKey = 'push_device_id';
  bool _configured = false;
  bool _tokenRotatedForSession = false;
  Future<bool>? _tokenRegistrationFuture;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  final StreamController<RemoteMessage> _foregroundController =
      StreamController<RemoteMessage>.broadcast();

  /// Stream of messages received while the app is foregrounded. UI can
  /// subscribe to present an in-app banner/toast.
  Stream<RemoteMessage> get onForegroundMessage => _foregroundController.stream;

  Future<bool> enableForReminders() async {
    if (kIsWeb) return false;
    try {
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
    } catch (error) {
      debugPrint('Unable to enable Firebase messaging auto-init: $error');
    }
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final localAllowed =
        await LocalReminderService.instance.requestPermission();
    if ((settings.authorizationStatus != AuthorizationStatus.authorized &&
            settings.authorizationStatus != AuthorizationStatus.provisional) ||
        !localAllowed) {
      return false;
    }
    await _configureForegroundNotifications();
    // A device can keep an FCM token that Google has already invalidated.
    // Refresh it during explicit opt-in so scheduled reminders can recover
    // without requiring a reinstall.
    try {
      await FirebaseMessaging.instance.deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_deviceIdKey);
      _tokenRotatedForSession = true;
    } catch (_) {}
    final registered = await _registerCurrentToken();
    if (!registered) return false;
    await BackendApi.instance.updateNotificationPreferences(allEnabled: true);
    _listenForTokenRefresh();
    return true;
  }

  /// Initialize push notifications on app startup.
  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await syncAfterAuthentication();
    } catch (error) {
      debugPrint('Push initialization deferred: $error');
    }
  }

  /// Retry token registration after login. Startup can run before the
  /// authenticated session exists, so the first registration may receive 401.
  Future<void> syncAfterAuthentication() async {
    if (kIsWeb) return;
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _configureForegroundNotifications();
        // FCM can retain a token that the provider has already invalidated.
        // Rotate it once per authenticated app session so a previous
        // NotRegistered delivery does not require reinstalling Mizan.
        if (!_tokenRotatedForSession) {
          try {
            await FirebaseMessaging.instance.deleteToken();
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_deviceIdKey);
          } catch (_) {
            // A token rotation failure is recoverable; registration below can
            // still succeed with the current Firebase token.
          } finally {
            _tokenRotatedForSession = true;
          }
        }
        await _registerCurrentToken();
        _listenForTokenRefresh();
      }
    } catch (error) {
      debugPrint('Push authentication sync deferred: $error');
      // Permission or Firebase failures must not block authentication.
    }
  }

  /// [Phase 7] Must be called on logout/account switch. Cancels the token
  /// refresh subscription so the previous user's device token is never
  /// re-registered, and clears the device ID so the next account starts fresh.
  Future<void> resetForLogout() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    _foregroundSubscription = null;
    _openedAppSubscription = null;
    _configured = false;
    _tokenRotatedForSession = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
  }

  Future<void> _configureForegroundNotifications() async {
    if (_configured) return;
    try {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      _foregroundSubscription = FirebaseMessaging.onMessage.listen((
        message,
      ) async {
        final data = Map<String, dynamic>.from(message.data);
        await persistFcmPayload(data);
        // Android does not present FCM notification payloads while the app is
        // in the foreground. Mirror the message through the local channel so
        // foreground delivery is visible too. iOS uses its foreground
        // presentation options and must not receive a duplicate local alert.
        if (defaultTargetPlatform == TargetPlatform.android) {
          final notification = message.notification;
          final title = notification?.title ?? data['title']?.toString();
          final body = notification?.body ?? data['body']?.toString();
          if (title != null &&
              title.isNotEmpty &&
              body != null &&
              body.isNotEmpty) {
            await LocalReminderService.instance.showNow(
              id:
                  message.messageId?.hashCode ??
                  DateTime.now().millisecondsSinceEpoch,
              title: title,
              body: body,
              payload: jsonEncode(data),
            );
          }
        }
        _foregroundController.add(message);
      });

      _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
        message,
      ) async {
        try {
          await persistFcmPayload(Map<String, dynamic>.from(message.data));
        } catch (_) {}
      });
      _configured = true;
    } catch (error) {
      // Firebase may not be initialized yet. Keep this false so startup or
      // the next foreground transition can retry instead of permanently
      // caching a failed setup.
      debugPrint('Foreground notification setup deferred: $error');
    }
  }

  void _listenForTokenRefresh() {
    _tokenRefreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh
        .listen((_) => _registerCurrentToken());
  }

  /// [Phase 7] Single-flight token registration. Prevents duplicate backend
  /// token records when app opens repeatedly or parent rebuilds.
  Future<bool> _registerCurrentToken() async {
    final active = _tokenRegistrationFuture;
    if (active != null) return active;
    final registration = _performTokenRegistration();
    _tokenRegistrationFuture = registration;
    try {
      return await registration;
    } finally {
      if (identical(_tokenRegistrationFuture, registration)) {
        _tokenRegistrationFuture = null;
      }
    }
  }

  Future<bool> _performTokenRegistration() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        debugPrint(
          'FCM token registration skipped: Firebase returned no token.',
        );
        return false;
      }
      final preferences = await SharedPreferences.getInstance();
      var deviceId = preferences.getString(_deviceIdKey);
      if (deviceId == null) {
        deviceId =
            '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
        await preferences.setString(_deviceIdKey, deviceId);
      }
      // Keep the token, timezone, and coordinates together so the backend can
      // schedule reminders at the user's local prayer times.
      await BackendApi.instance.registerPushToken(
        deviceId: deviceId,
        platform: _platformName(),
        pushToken: token,
        timeZone: await DeviceTimezone.instance.resolveIanaTimezone(),
        coords: await _storedCoordinates(),
      );
      return true;
    } catch (error) {
      // Registration may retry on next refresh. Explicit opt-in callers get
      // a failure result so the UI does not claim reminders are enabled.
      debugPrint('FCM token registration failed: $error');
      return false;
    }
  }

  String _platformName() => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    TargetPlatform.android => 'android',
    _ => 'web',
  };

  Future<Map<String, double>?> _storedCoordinates() async {
    final stored = await LocationService.instance.getStoredPosition();
    if (stored == null) return null;
    final latitude = stored['lat'];
    final longitude = stored['lon'];
    if (latitude == null || longitude == null) return null;
    return {'latitude': latitude, 'longitude': longitude};
  }
}
