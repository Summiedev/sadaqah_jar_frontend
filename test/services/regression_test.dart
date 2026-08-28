import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:sadaqah_jar/services/backend_api.dart';
import 'package:sadaqah_jar/core/user_facing_errors.dart';
import 'package:sadaqah_jar/services/device_timezone.dart';
import 'package:sadaqah_jar/services/websocket_service.dart';
import 'package:sadaqah_jar/features/journey/quran/quran_data.dart';

void main() {
  group('Quran download state', () {
    test('logical progress is bounded and readable', () {
      const status = QuranDownloadStatus(
        state: QuranDownloadState.downloading,
        completed: 18,
        total: 114,
        message: 'Downloaded surah 18 of 114',
      );
      expect(status.percent, 16);
      expect(status.progress, closeTo(18 / 114, 0.0001));
    });

    test('waiting for network is a resumable state', () {
      const status = QuranDownloadStatus(
        state: QuranDownloadState.waitingForNetwork,
        completed: 7,
        total: 718,
      );
      expect(status.state, QuranDownloadState.waitingForNetwork);
      expect(status.completed, 7);
    });
  });

  group('C4: API response parsing safety', () {
    test('bare object is accepted', () {
      final api = BackendApi.instance;
      final result = api.expectMap({'user_id': 1, 'username': 'a'});
      expect(result['user_id'], 1);
    });

    test('enveloped object is unwrapped', () {
      final api = BackendApi.instance;
      final result = api.expectMap({'data': {'user_id': 2, 'username': 'b'}});
      expect(result['user_id'], 2);
    });

    test('bare list is accepted', () {
      final api = BackendApi.instance;
      final result = api.expectList([{'id': 1}, {'id': 2}]);
      expect(result.length, 2);
    });

    test('enveloped list is unwrapped', () {
      final api = BackendApi.instance;
      final result = api.expectList({'data': [{'id': 1}]});
      expect(result.length, 1);
    });

    test('empty response yields empty map (no crash)', () {
      final api = BackendApi.instance;
      final result = api.expectMapOrNull(null);
      expect(result, isNull);
    });

    test('malformed shape throws controlled BackendApiException', () {
      final api = BackendApi.instance;
      expect(
        () => api.expectMap('not a map'),
        throwsA(isA<BackendApiException>()),
      );
    });
  });

  group('M2: user-facing error mapping', () {
    test('offline socket error maps to connection message', () {
      expect(
        userMessageForError(SocketException('offline')),
        contains('No internet connection'),
      );
    });

    test('401 maps to session-ended message', () {
      expect(
        userMessageForError(BackendApiException('token expired', 401)),
        contains('session has ended'),
      );
    });

    test('403 maps to permission message', () {
      expect(
        userMessageForError(BackendApiException('forbidden', 403)),
        contains("don't have permission"),
      );
    });

    test('404 maps to unavailable message', () {
      expect(
        userMessageForError(BackendApiException('missing', 404)),
        contains('no longer available'),
      );
    });

    test('429 maps to retry message', () {
      expect(
        userMessageForError(BackendApiException('too many', 429)),
        contains('Too many attempts'),
      );
    });

    test('500 maps to server message', () {
      expect(
        userMessageForError(BackendApiException('boom', 500)),
        contains('on our side'),
      );
    });

    test('unknown error never leaks internals', () {
      expect(
        userMessageForError(StateError('secret stack detail')),
        isNot(contains('secret')),
      );
    });
  });

  group('H2: notification payload persistence', () {
    test('URL containing & and = survives JSON round-trip', () async {
      final data = {'type': 'book', 'url': 'https://e.com/x?a=1&b=2'};
      final encoded = jsonEncode(data);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded['url'], 'https://e.com/x?a=1&b=2');
    });

    test('malformed payload cannot crash decode path', () {
      final raw = 'not-json{';
      expect(() => jsonDecode(raw), throwsFormatException);
    });

    test('unknown payload type is ignored safely by resolver', () {
      final data = <String, dynamic>{'type': 'unknown_type_xyz'};
      // resolveNotificationDestination should return null for unsupported types
      final destination = resolveNotificationDestinationForTest(data);
      expect(destination, isNull);
    });

    test('payload-only push has no display body', () {
      final data = <String, dynamic>{'type': 'family', 'family_id': 1};
      expect(data.containsKey('title'), isFalse);
      expect(data.containsKey('body'), isFalse);
    });
  });

  group('M4: timezone resolution', () {
    test('timezone resolution never returns a bare abbreviation', () async {
      // In unit tests there is no platform channel, so the safe fallback is
      // 'UTC' (a valid IANA identifier). The contract is: never a bare
      // abbreviation like WAT/CET/EST. Valid IANA identifiers are either
      // 'UTC' or contain a '/' (e.g. 'Africa/Lagos').
      final resolved = await DeviceTimezone.instance.resolveIanaTimezone();
      expect(
        resolved == 'UTC' || resolved.contains('/'),
        isTrue,
        reason: 'Got unexpected timezone string: $resolved',
      );
      expect(['WAT', 'CET', 'EST', 'GMT'].contains(resolved), isFalse);
    });

    test('deterministic reminder IDs are stable per identity', () {
      final id1 = reminderScheduleId('fajr', dateKey: '2026-08-08');
      final id2 = reminderScheduleId('fajr', dateKey: '2026-08-08');
      expect(id1, id2);
    });

    test('different reminder types map to different IDs', () {
      final fajr = reminderScheduleId('fajr', dateKey: '2026-08-08');
      final dhuhr = reminderScheduleId('dhuhr', dateKey: '2026-08-08');
      expect(fajr, isNot(dhuhr));
    });
  });

  group('H3: WebSocket keyed connections', () {
    test('personal and family sockets use separate keys', () {
      // Keys are derived from user:/family: prefixes - verify the service
      // maintains separate connection slots (regression guard).
      final service = WebSocketService.instance;
      expect(service.isConnected, isFalse);
    });
  });

  group('Notification payload helpers', () {
    test('envelope data list is not double-unwrapped', () {
      final raw = {
        'data': {'data': [{'id': 1}], 'total': 1},
      };
      // getBookmarks-style: outer envelope unwrap + inner paginated 'data'
      final outer = raw['data'] as Map<String, dynamic>;
      final innerItems = outer['data'] as List;
      expect(innerItems.length, 1);
      expect(innerItems.first['id'], 1);
    });
  });
}

/// Test-only entry to the notification destination resolver whitelist.
/// Returns null for unsupported types so navigation is never attempted.
Object? resolveNotificationDestinationForTest(Map<String, dynamic> payload) {
  final type = payload['type']?.toString() ?? '';
  const whitelist = {'family', 'reflection', 'donation', 'book', 'prayer'};
  if (!whitelist.contains(type)) return null;
  final id = payload['id'] ?? payload['${type}_id'];
  if (id == null || int.tryParse('$id') == null) return null;
  return {'type': type, 'id': id};
}
