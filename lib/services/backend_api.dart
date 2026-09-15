import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum SessionBootstrapState { none, restored, expired }

/// In-process signal used by screens that cache list responses. Mutations
/// publish only after the server accepted them, so listeners can refresh
/// without forcing a full app rebuild.
final ValueNotifier<int> reflectionRevision = ValueNotifier<int>(0);

class BackendApi {
  BackendApi._();

  static final BackendApi instance = BackendApi._();

  static const String _defaultBaseUrl = 'https://api.sad-aqah.app/api/v1';
  static const String _accessTokenKey = 'sadaqah_jar_access_token';
  static const String _refreshTokenKey = 'sadaqah_jar_refresh_token';
  static const String _accountKey = 'sadaqah_jar_account_snapshot';
  static const String _familyJarIdKey = 'sadaqah_jar_family_jar_id';
  // [M1] Intentional timeout categories. Ordinary reads must not leave the UI
  // spinning for a minute; uploads need a much longer window.
  static const Duration _receiveTimeout = Duration(seconds: 20);
  static const Duration _mutationTimeout = Duration(seconds: 30);
  static const Duration _uploadTimeout = Duration(minutes: 2);

  final String baseUrl = _resolveBaseUrl();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Completer<bool>? _refreshCompleter;
  Future<void> Function()? onSessionExpired;

  /// Guards against firing [onSessionExpired] more than once when several
  /// in-flight requests all fail their 401 retry at the same time. Reset via
  /// [resetSessionExpiredFlag] whenever a fresh session is established.
  bool _sessionExpiredNotified = false;

  /// Clears the one-shot session-expiry guard so a future expiry can notify
  /// again. Called after a successful login/refresh establishes a new session.
  void resetSessionExpiredFlag() {
    _sessionExpiredNotified = false;
  }

  static String _resolveBaseUrl() {
    final configured =
        const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: _defaultBaseUrl,
        ).trim();
    final normalized =
        configured.endsWith('/') && configured.length > 1
            ? configured.substring(0, configured.length - 1)
            : configured;
    final uri = Uri.tryParse(normalized);
    final validScheme = uri?.scheme == 'http' || uri?.scheme == 'https';
    if (uri == null || !validScheme || uri.host.isEmpty) {
      throw StateError(
        'Invalid API_BASE_URL. Use a full http(s) URL, e.g. http://127.0.0.1:8000/api/v1',
      );
    }
    return normalized;
  }

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _secureStorage.read(key: _accessTokenKey);
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: _accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> clearRefreshToken() async {
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  Future<void> saveSessionTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([saveToken(accessToken), saveRefreshToken(refreshToken)]);
    // A fresh session is now established - allow a future expiry to notify.
    resetSessionExpiredFlag();
  }

  Future<void> saveAccountSnapshot({
    int? userId,
    String? username,
    String? email,
    String? avatarData,
  }) async {
    final prefs = await _prefs;
    final snapshot = <String, dynamic>{
      if (userId != null) 'user_id': userId,
      if (username != null && username.isNotEmpty) 'username': username,
      if (email != null && email.isNotEmpty) 'email': email,
      if (avatarData != null && avatarData.isNotEmpty)
        'avatar_data': avatarData,
    };

    if (snapshot.isEmpty) {
      await prefs.remove(_accountKey);
      return;
    }
    await prefs.setString(_accountKey, jsonEncode(snapshot));
  }

  Future<AccountSnapshot?> getAccountSnapshot() async {
    try {
      final remote = AccountSnapshot.fromJson(await me());
      await saveAccountSnapshot(
        userId: remote.userId,
        username: remote.username,
        email: remote.email,
        avatarData: remote.avatarData,
      );
      return remote;
    } catch (e) {
      debugPrint('Account snapshot error: $e');
    }

    final prefs = await _prefs;
    final raw = prefs.getString(_accountKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return AccountSnapshot.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (e) {
      debugPrint('Local account snapshot parse error: $e');
      return null;
    }
  }

  Future<void> clearAccountSnapshot() async {
    final prefs = await _prefs;
    await prefs.remove(_accountKey);
  }

  Future<void> saveLastFamilyJarId(int? jarId) async {
    final prefs = await _prefs;
    if (jarId == null) {
      await prefs.remove(_familyJarIdKey);
    } else {
      await prefs.setInt(_familyJarIdKey, jarId);
    }
  }

  Future<int?> getLastFamilyJarId() async {
    final prefs = await _prefs;
    return prefs.getInt(_familyJarIdKey);
  }

  Future<void> clearSessionState() async {
    await clearToken();
    await clearRefreshToken();
    await clearAccountSnapshot();
    await saveLastFamilyJarId(null);
  }

  String get devicePlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'android';
    }
  }

  Future<bool> hasToken() async => (await getToken())?.isNotEmpty ?? false;

  Future<SessionBootstrapState> bootstrapSession() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      return (await _refreshSession())
          ? SessionBootstrapState.restored
          : SessionBootstrapState.expired;
    }

    final accessToken = await getToken();
    return accessToken != null && accessToken.isNotEmpty
        ? SessionBootstrapState.restored
        : SessionBootstrapState.none;
  }

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath').replace(
      queryParameters: query?.map((key, value) => MapEntry(key, '$value')),
    );
  }

  Future<http.Response> _request(
    Future<http.Response> Function(Map<String, String> headers) send, {
    bool auth = false,
    bool retryOnUnauthorized = true,
  }) async {
    final response = await send(await _headers(auth: auth));
    if (!auth || !retryOnUnauthorized || response.statusCode != 401) {
      return response;
    }

    if (await _refreshSession()) {
      final retry = await send(await _headers(auth: true));
      if (retry.statusCode != 401) {
        return retry;
      }
    }

    throw BackendApiException('Session expired', 401);
  }

  Future<http.Response> _get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = false,
    bool retryOnUnauthorized = true,
  }) {
    return _request(
      (headers) => http
          .get(_uri(path, query), headers: headers)
          .timeout(_receiveTimeout),
      auth: auth,
      retryOnUnauthorized: retryOnUnauthorized,
    );
  }

  Future<http.Response> _post(
    String path, {
    Map<String, dynamic>? query,
    bool auth = false,
    bool retryOnUnauthorized = true,
    Object? body,
  }) {
    return _request(
      (headers) => http
          .post(_uri(path, query), headers: headers, body: body)
          .timeout(_mutationTimeout),
      auth: auth,
      retryOnUnauthorized: retryOnUnauthorized,
    );
  }

  Future<http.Response> _patch(
    String path, {
    Map<String, dynamic>? query,
    bool auth = false,
    bool retryOnUnauthorized = true,
    Object? body,
  }) {
    return _request(
      (headers) => http
          .patch(_uri(path, query), headers: headers, body: body)
          .timeout(_mutationTimeout),
      auth: auth,
      retryOnUnauthorized: retryOnUnauthorized,
    );
  }

  Future<http.Response> _put(
    String path, {
    Map<String, dynamic>? query,
    bool auth = false,
    bool retryOnUnauthorized = true,
    Object? body,
  }) {
    return _request(
      (headers) => http
          .put(_uri(path, query), headers: headers, body: body)
          .timeout(_mutationTimeout),
      auth: auth,
      retryOnUnauthorized: retryOnUnauthorized,
    );
  }

  Future<http.Response> _delete(
    String path, {
    Map<String, dynamic>? query,
    bool auth = false,
    bool retryOnUnauthorized = true,
  }) {
    return _request(
      (headers) => http
          .delete(_uri(path, query), headers: headers)
          .timeout(_receiveTimeout),
      auth: auth,
      retryOnUnauthorized: retryOnUnauthorized,
    );
  }

  Future<bool> _refreshSession() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _expireSession();
        completer.complete(false);
        return false;
      }

      final response = await _post(
        '/auth/refresh',
        body: jsonEncode({'refresh_token': refreshToken}),
        retryOnUnauthorized: false,
      );
      if (response.statusCode >= 400) {
        await _expireSession();
        completer.complete(false);
        return false;
      }

      final decoded = _handleJson(response) as Map<String, dynamic>;
      final accessToken = decoded['access_token']?.toString();
      final nextRefreshToken = decoded['refresh_token']?.toString();
      if (accessToken == null ||
          accessToken.isEmpty ||
          nextRefreshToken == null ||
          nextRefreshToken.isEmpty) {
        await _expireSession();
        completer.complete(false);
        return false;
      }

      await saveSessionTokens(
        accessToken: accessToken,
        refreshToken: nextRefreshToken,
      );
      completer.complete(true);
      return true;
    } catch (_) {
      await _expireSession();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      return false;
    } finally {
      if (identical(_refreshCompleter, completer)) {
        _refreshCompleter = null;
      }
    }
  }

  Future<void> _expireSession() async {
    await clearSessionState();
    // Only notify once per expiry so that several concurrent requests failing
    // their 401 retry at the same time don't trigger multiple redirects.
    if (_sessionExpiredNotified) {
      return;
    }
    _sessionExpiredNotified = true;
    final handler = onSessionExpired;
    if (handler != null) {
      try {
        await handler();
      } catch (_) {}
    }
  }

  Future<void> revokeSessionOnServer() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return;
    }

    try {
      await _post(
        '/auth/logout',
        body: jsonEncode({'refresh_token': refreshToken}),
        retryOnUnauthorized: false,
      );
    } catch (_) {}
  }

  /// Unwraps a response that may or may not use the envelope format.
  ///
  /// The Mizan backend has two response styles:
  /// 1. **Envelope** - `{"data": ..., "meta": {...}, "message": "..."}` (newer routers)
  /// 2. **Bare** - The data object/list directly (legacy routers)
  ///
  /// This method handles both transparently. If a `data` key exists it unwraps;
  /// otherwise it returns the decoded body as-is.
  ///
  /// IMPORTANT: This only unwraps ONE level. If the unwrapped value is itself
  /// a map containing a `data` key that is part of the resource schema (e.g.
  /// a paginated response), callers must NOT unwrap again.
  dynamic _unwrap(dynamic decoded) {
    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      return decoded['data'];
    }
    return decoded;
  }

  /// Safely unwraps a decoded response body and returns it as a Map.
  ///
  /// Throws [BackendApiException] if the body is not a Map after unwrapping.
  Map<String, dynamic> expectMap(dynamic body, {String? context}) {
    final unwrapped = _unwrap(body);
    if (unwrapped is Map<String, dynamic>) {
      return unwrapped;
    }
    if (unwrapped is Map) {
      return Map<String, dynamic>.from(unwrapped);
    }
    throw BackendApiException(
      context == null
          ? 'Expected a JSON object but received ${_typeName(unwrapped)}'
          : 'Expected a JSON object for $context but received ${_typeName(unwrapped)}',
      0,
    );
  }

  /// Safely unwraps a decoded response body and returns it as a List.
  ///
  /// Throws [BackendApiException] if the body is not a List after unwrapping.
  List<dynamic> expectList(dynamic body, {String? context}) {
    final unwrapped = _unwrap(body);
    if (unwrapped is List) {
      return unwrapped;
    }
    throw BackendApiException(
      context == null
          ? 'Expected a JSON array but received ${_typeName(unwrapped)}'
          : 'Expected a JSON array for $context but received ${_typeName(unwrapped)}',
      0,
    );
  }

  /// Safely unwraps a decoded response body and returns it as a Map.
  ///
  /// Returns null if the body is null or empty after unwrapping.
  Map<String, dynamic>? expectMapOrNull(dynamic body, {String? context}) {
    final unwrapped = _unwrap(body);
    if (unwrapped == null) return null;
    if (unwrapped is Map<String, dynamic>) return unwrapped;
    if (unwrapped is Map) return Map<String, dynamic>.from(unwrapped);
    throw BackendApiException(
      context == null
          ? 'Expected a JSON object or null but received ${_typeName(unwrapped)}'
          : 'Expected a JSON object or null for $context but received ${_typeName(unwrapped)}',
      0,
    );
  }

  /// Safely unwraps a decoded response body and returns it as a List.
  ///
  /// Returns an empty list if the body is null or empty after unwrapping.
  List<dynamic> expectListOrEmpty(dynamic body, {String? context}) {
    final unwrapped = _unwrap(body);
    if (unwrapped == null) return const [];
    if (unwrapped is List) return unwrapped;
    throw BackendApiException(
      context == null
          ? 'Expected a JSON array or null but received ${_typeName(unwrapped)}'
          : 'Expected a JSON array or null for $context but received ${_typeName(unwrapped)}',
      0,
    );
  }

  String _typeName(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return 'a string';
    if (value is num) return 'a number';
    if (value is bool) return 'a boolean';
    if (value is List) return 'an array';
    if (value is Map) return 'an object';
    return 'an unexpected value';
  }

  Map<String, dynamic>? _getEnvelopeMeta(Map<String, dynamic> decoded) {
    final meta = decoded['meta'];
    if (meta is Map<String, dynamic>) return meta;
    return null;
  }

  String? _getEnvelopeMessage(Map<String, dynamic> decoded) {
    return decoded['message'] as String?;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? familyCode,
  }) async {
    final response = await _post(
      '/auth/register',
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        if (familyCode != null && familyCode.trim().isNotEmpty)
          'family_code': familyCode.trim().toUpperCase(),
      }),
    );
    final decoded = expectMap(_handleJson(response), context: 'auth');
    final accessToken = decoded['access_token']?.toString();
    final refreshToken = decoded['refresh_token']?.toString();
    if (accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty) {
      await saveSessionTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }
    await saveAccountSnapshot(username: username, email: email);
    return decoded;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _post(
      '/auth/login',
      body: jsonEncode({'email': email, 'password': password}),
    );
    final decoded = expectMap(_handleJson(response), context: 'auth');
    final accessToken = decoded['access_token']?.toString();
    final refreshToken = decoded['refresh_token']?.toString();
    if (accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty) {
      await saveSessionTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }
    await saveAccountSnapshot(
      username: email.contains('@') ? email.split('@').first : email,
      email: email,
    );
    return decoded;
  }

  Future<Map<String, dynamic>> googleAuth({required String idToken}) async {
    final response = await _post(
      '/auth/google',
      body: jsonEncode({'id_token': idToken}),
    );
    final decoded = expectMap(_handleJson(response), context: 'auth');
    final accessToken = decoded['access_token']?.toString();
    final refreshToken = decoded['refresh_token']?.toString();
    if (accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty) {
      await saveSessionTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }
    await saveAccountSnapshot(
      userId: (decoded['user_id'] as num?)?.toInt(),
      username: decoded['username']?.toString() ?? '',
      email: decoded['email']?.toString() ?? '',
    );
    return decoded;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _patch(
      '/users/me/password',
      auth: true,
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    // 204 on success
    if (response.statusCode != 204) {
      final decoded = _handleJson(response);
      if (decoded is Map<String, dynamic>) {
        throw BackendApiException(
          decoded['detail']?.toString() ?? 'Password change failed',
          response.statusCode,
        );
      }
    }
  }

  Future<void> resendVerificationEmail() async {
    await _post('/auth/resend-verification', auth: true, body: jsonEncode({}));
  }

  Future<AccountSnapshot> updateAccount({
    String? username,
    String? avatarData,
  }) async {
    final response = await _patch(
      '/auth/me',
      auth: true,
      body: jsonEncode({
        if (username != null) 'username': username,
        if (avatarData != null) 'avatar_data': avatarData,
      }),
    );
    final decoded = expectMap(_handleJson(response), context: 'update account');
    final snapshot = AccountSnapshot.fromJson(decoded);
    await saveAccountSnapshot(
      userId: snapshot.userId,
      username: snapshot.username,
      email: snapshot.email,
      avatarData: snapshot.avatarData,
    );
    return snapshot;
  }

  Future<Map<String, dynamic>> requestEmailChange({
    required String currentPassword,
    required String newEmail,
  }) async {
    final response = await _post(
      '/users/me/email/change-request',
      auth: true,
      body: jsonEncode({
        'current_password': currentPassword,
        'new_email': newEmail,
      }),
    );
    return expectMap(_handleJson(response), context: 'request email change');
  }

  Future<Map<String, dynamic>> confirmEmailChange({
    required String token,
  }) async {
    final response = await _post(
      '/users/me/email/confirm',
      auth: true,
      body: jsonEncode({'token': token}),
    );
    final decoded = expectMap(
      _handleJson(response),
      context: 'confirm email change',
    );
    if (decoded['access_token'] != null && decoded['refresh_token'] != null) {
      await saveSessionTokens(
        accessToken: decoded['access_token'].toString(),
        refreshToken: decoded['refresh_token'].toString(),
      );
    }
    return decoded;
  }

  Future<Map<String, dynamic>?> getPendingEmailChange() async {
    try {
      final response = await _get('/users/me/email/pending', auth: true);
      final decoded = _handleJson(response);
      return expectMapOrNull(decoded, context: 'pending email change');
    } on BackendApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> cancelEmailChange() async {
    await _post('/users/me/email/cancel', auth: true, body: '{}');
  }

  Future<void> resendEmailChangeVerification() async {
    await _post('/users/me/email/resend-verification', auth: true, body: '{}');
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _get('/auth/me', auth: true);
    return expectMap(_handleJson(response), context: 'me');
  }

  Future<UserProfile> getUserProfile() async {
    final response = await _get('/auth/me', auth: true);
    final decoded = _handleJson(response);
    // The /auth/me endpoint returns bare UserProfileResponse (not envelope-wrapped)
    return UserProfile.fromJson(expectMap(decoded, context: 'user profile'));
  }

  Future<UserPreferences> updatePreferences({
    bool? evidenceMode,
    bool? fridayReminder,
    bool? generalNotifications,
  }) async {
    final response = await _patch(
      '/auth/preferences',
      auth: true,
      body: jsonEncode({
        if (evidenceMode != null) 'evidence_mode': evidenceMode,
        if (fridayReminder != null) 'friday_reminder': fridayReminder,
        if (generalNotifications != null)
          'general_notifications': generalNotifications,
      }),
    );
    final decoded = expectMap(
      _handleJson(response),
      context: 'update preferences',
    );
    return UserPreferences.fromJson(decoded);
  }

  Future<void> registerPushToken({
    required String deviceId,
    required String platform,
    required String pushToken,
    String? timeZone,
    Map<String, double>? coords,
  }) async {
    final body = {
      'device_id': deviceId,
      'platform': platform,
      'push_token': pushToken,
      if (timeZone != null) 'time_zone': timeZone,
      if (coords != null) 'coords': coords,
    };
    await _post('/users/me/push-token', auth: true, body: jsonEncode(body));
  }

  Future<bool> isEmailVerified() async {
    final response = await me();
    return response['email_verified'] as bool? ?? false;
  }

  Future<bool> isCurrentUserAdmin() async {
    return (await getUserProfile()).role.toUpperCase() == 'ADMIN';
  }

  Future<void> forgotPassword({required String email}) async {
    await _post(
      '/auth/forgot-password',
      body: jsonEncode({'email': email}),
      retryOnUnauthorized: false,
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _post(
      '/auth/reset-password',
      body: jsonEncode({'token': token, 'new_password': newPassword}),
      retryOnUnauthorized: false,
    );
  }

  Future<void> verifyEmail({required String token}) async {
    final response = await _get(
      '/auth/verify-email',
      query: {'token': token},
      retryOnUnauthorized: false,
    );
    final decoded = expectMap(_handleJson(response), context: 'auth');
    final accessToken = decoded['access_token']?.toString();
    final refreshToken = decoded['refresh_token']?.toString();
    if (accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty) {
      await saveSessionTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }
  }

  Future<void> verifyEmailOtp({required String code}) async {
    final response = await _post(
      '/auth/verify-email',
      body: jsonEncode({'code': code}),
      retryOnUnauthorized: false,
    );
    final decoded = expectMap(_handleJson(response), context: 'auth');
    final accessToken = decoded['access_token']?.toString();
    final refreshToken = decoded['refresh_token']?.toString();
    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      throw BackendApiException(
        'Verification succeeded but no session was returned.',
        response.statusCode,
      );
    }
    await saveSessionTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> uploadAdminBookFile({
    required int bookId,
    required List<int> bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/admin/books/$bookId/file'),
    );
    final token = await getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );
    final streamed = await request.send().timeout(_uploadTimeout);
    final response = await http.Response.fromStream(streamed);
    _handleJson(response);
  }

  Future<AdminBookRecord> uploadAdminBookCover({
    required int bookId,
    required List<int> bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/admin/books/$bookId/cover'),
    );
    final token = await getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );
    final streamed = await request.send().timeout(_uploadTimeout);
    final response = await http.Response.fromStream(streamed);
    return AdminBookRecord.fromJson(
      expectMap(_handleJson(response), context: 'admin book'),
    );
  }

  Future<AdminBookRecord> uploadAdminBookPages({
    required int bookId,
    required List<PickedUploadFile> files,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/admin/books/$bookId/pages'),
    );
    final token = await getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    for (final file in files) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'files',
          file.bytes,
          filename: file.filename,
        ),
      );
    }
    final streamed = await request.send().timeout(_uploadTimeout);
    final response = await http.Response.fromStream(streamed);
    return AdminBookRecord.fromJson(
      expectMap(_handleJson(response), context: 'admin book'),
    );
  }

  Future<int?> getCurrentUserId() async {
    return (await getAccountSnapshot())?.userId;
  }

  Uri _webSocketUri(String path, String token) {
    final base = Uri.parse(baseUrl);
    final pathSegments = <String>[
      ...base.pathSegments.where((segment) => segment.isNotEmpty),
      ...path.split('/').where((segment) => segment.isNotEmpty),
    ];
    return Uri(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      host: base.host,
      port: base.hasPort && base.port > 0 ? base.port : null,
      pathSegments: pathSegments,
      queryParameters: <String, String>{'token': token},
    );
  }

  Uri userWebSocketUri(int userId, String token) {
    return _webSocketUri('websock/ws/jar/$userId', token);
  }

  Uri familyWebSocketUri(int jarId, String token) {
    return _webSocketUri('websock/ws/family-jar/$jarId', token);
  }

  Future<List<DailyAct>> getDailyActs() async {
    final response = await _get('/sadaqah/daily', auth: true);
    final decoded = _handleJson(response);
    return expectList(decoded, context: 'daily acts')
        .map(
          (item) =>
              DailyAct.fromJson(expectMap(item, context: 'daily act item')),
        )
        .toList();
  }

  Future<SadaqahActPage> getActs({int limit = 100, int offset = 0}) async {
    final response = await _get(
      '/sadaqah/acts',
      auth: true,
      query: {'limit': limit, 'offset': offset},
    );
    return SadaqahActPage.fromJson(_handleJson(response));
  }

  Future<SadaqahActDetail> getActDetail(int actId) async {
    final response = await _get('/sadaqah/acts/$actId', auth: true);
    return _handleJson(response);
  }

  Future<JarStats> getJar() async {
    final response = await _get('/sadaqah/jar', auth: true);
    final decoded = _handleJson(response);
    // Legacy /sadaqah/jar returns bare JSON, not envelope
    return JarStats.fromJson(expectMap(decoded, context: 'jar'));
  }

  Future<JarStats> addJarStar({
    int? actId,
    String? type,
    String? note,
    String? requestId,
  }) async {
    final response = await _post(
      '/sadaqah/jar/add-star',
      auth: true,
      query: {
        if (actId != null) 'act_id': actId,
        if (type != null && type.isNotEmpty) 'type': type,
        if (note != null && note.isNotEmpty) 'note': note,
        if (requestId != null && requestId.isNotEmpty) 'request_id': requestId,
      },
    );
    final decoded = _handleJson(response);
    // Legacy /sadaqah/jar/add-star returns bare snapshot, not envelope
    return JarStats.fromJson(expectMap(decoded, context: 'jar star'));
  }

  Future<CompletedJarPage> getCompletedJars({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _get(
      '/sadaqah/jars/completed',
      auth: true,
      query: {'limit': limit, 'offset': offset},
    );
    final decoded = _handleJson(response);
    // Legacy endpoint returns bare paginated response, not envelope
    return CompletedJarPage.fromJson(
      expectMap(decoded, context: 'completed jars'),
    );
  }

  Future<Map<String, int>> getHeatmap() async {
    final response = await _get('/dashboard/heatmap', auth: true);
    final decoded = _handleJson(response);
    // Legacy endpoint returns bare map, not envelope
    return expectMap(
      decoded,
      context: 'heatmap',
    ).map((key, value) => MapEntry(key, int.tryParse('$value') ?? 0));
  }

  Future<StreakInfo> getStreak() async {
    final response = await _get('/streak/streak', auth: true);
    final decoded = _handleJson(response);
    // Legacy endpoint returns bare response, not envelope
    return StreakInfo.fromJson(expectMap(decoded, context: 'streak'));
  }

  Future<RankSummary> getMyRank() async {
    final response = await _get('/leaderboard/me', auth: true);
    final decoded = _handleJson(response);
    // Legacy endpoint returns bare response, not envelope
    return RankSummary.fromJson(expectMap(decoded, context: 'rank'));
  }

  Future<List<LeaderboardEntry>> getFridayLeaderboard({int limit = 10}) async {
    final response = await _get(
      '/leaderboard/friday',
      auth: true,
      query: {'limit': limit},
    );
    return _leaderboardFromResponse(response);
  }

  Future<List<LeaderboardEntry>> getRamadanLeaderboard() async {
    final response = await _get('/leaderboard/ramadan', auth: true);
    return _leaderboardFromResponse(response);
  }

  Future<List<LeaderboardEntry>> getGlobalLeaderboard({int limit = 10}) async {
    final response = await _get(
      '/leaderboard/global',
      auth: true,
      query: {'limit': limit},
    );
    return _leaderboardFromResponse(response);
  }

  Future<FridayStats> getFridayStats() async {
    final response = await _get('/friday/stats', auth: true);
    final decoded = _handleJson(response);
    // Legacy endpoint returns bare JSON
    return FridayStats.fromJson(expectMap(decoded, context: 'friday stats'));
  }

  Future<int> getAdminDailyUsers() async {
    final response = await _get('/admin/analytics/daily-users', auth: true);
    final decoded = _handleJson(response);
    // Legacy endpoint returns bare JSON
    return (expectMap(decoded, context: 'admin daily users')['new_users_today']
                as num?)
            ?.toInt() ??
        0;
  }

  Future<List<AdminTopActEntry>> getAdminTopActs() async {
    final response = await _get('/admin/analytics/top-acts', auth: true);
    final decoded = _handleJson(response);
    return expectList(decoded, context: 'admin top acts')
        .map(
          (item) => AdminTopActEntry.fromJson(
            expectMap(item, context: 'admin top act'),
          ),
        )
        .toList();
  }

  Future<int> getAdminStarsToday() async {
    final response = await _get('/admin/analytics/stars-today', auth: true);
    final decoded = _handleJson(response);
    // Legacy endpoint returns bare JSON
    return (expectMap(decoded, context: 'admin stars today')['stars_today']
                as num?)
            ?.toInt() ??
        0;
  }

  Future<List<AdminDonationIntentEntry>> getAdminDonationIntents() async {
    final response = await _get(
      '/admin/analytics/donation-intents',
      auth: true,
    );
    final decoded = _handleJson(response);
    return expectList(decoded, context: 'admin donation intents')
        .map(
          (item) => AdminDonationIntentEntry.fromJson(
            expectMap(item, context: 'admin donation intent'),
          ),
        )
        .toList();
  }

  Future<DashboardStats> getDashboardStats() async {
    final response = await _get('/dashboard/stats', auth: true);
    final decoded = _handleJson(response);
    // Legacy endpoint returns bare JSON, not envelope
    return DashboardStats.fromJson(
      expectMap(decoded, context: 'dashboard stats'),
    );
  }

  Future<List<CategoryAnalyticsEntry>> getCategoryAnalytics() async {
    final response = await _get('/dashboard/category-analytics', auth: true);
    final decoded = _handleJson(response);
    return expectList(decoded, context: 'category analytics')
        .map(
          (item) => CategoryAnalyticsEntry.fromJson(
            expectMap(item, context: 'category analytics item'),
          ),
        )
        .toList();
  }

  Future<int> getUnreadNotificationCount() async {
    final response = await _get('/notifications/unread-count', auth: true);
    final decoded = _handleJson(response);
    final map = expectMap(decoded, context: 'unread count');
    return (map['count'] as num?)?.toInt() ?? 0;
  }

  Future<NotificationPage> getNotifications({
    bool unread = false,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _get(
      '/notifications/',
      auth: true,
      query: {if (unread) 'unread': true, 'limit': limit, 'offset': offset},
    );
    final decoded = _handleJson(response);
    final data = expectList(decoded, context: 'notifications');
    final meta =
        decoded is Map<String, dynamic> ? _getEnvelopeMeta(decoded) : null;
    return NotificationPage(
      total: (meta?['total'] as num?)?.toInt() ?? 0,
      limit: limit,
      offset: offset,
      data:
          data
              .map(
                (i) => NotificationItem.fromJson(
                  expectMap(i, context: 'notification item'),
                ),
              )
              .toList(),
    );
  }

  Future<void> markNotificationRead(int notificationId) async {
    final response = await _patch(
      '/notifications/$notificationId/read',
      auth: true,
      retryOnUnauthorized: true,
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    // B2/A0.1: a 2xx envelope may carry an informational message (e.g. Notification deleted).
    // _handleJson already throws for statusCode >= 400, so a message on success is NOT an error.
    _getEnvelopeMessage(decoded);
  }

  Future<void> markAllNotificationsRead() async {
    final response = await _post(
      '/notifications/read-all',
      auth: true,
      retryOnUnauthorized: true,
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    // B2/A0.1: a 2xx envelope may carry an informational message (e.g. Notification deleted).
    // _handleJson already throws for statusCode >= 400, so a message on success is NOT an error.
    _getEnvelopeMessage(decoded);
  }

  Future<void> deleteNotification(int notificationId) async {
    final response = await _delete(
      '/notifications/$notificationId',
      auth: true,
      retryOnUnauthorized: true,
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    // B2/A0.1: a 2xx envelope may carry an informational message (e.g. Notification deleted).
    // _handleJson already throws for statusCode >= 400, so a message on success is NOT an error.
    _getEnvelopeMessage(decoded);
  }

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    await _post(
      '/notifications/device-token',
      auth: true,
      body: jsonEncode({'token': token, 'platform': platform}),
    );
  }

  Future<int> sendTestPush() async {
    final response = await _post('/notifications/test-push', auth: true);
    final decoded = expectMap(_handleJson(response), context: 'test push');
    return (decoded['delivered'] as num?)?.toInt() ?? 0;
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final response = await _get('/notifications/preferences', auth: true);
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'notification preferences');
  }

  Future<Map<String, dynamic>> updateNotificationPreferences({
    bool? allEnabled,
    String? frequency,
    Map<String, bool>? categories,
    Map<String, dynamic>? quietHours,
    Map<String, dynamic>? reminderPreferences,
  }) async {
    final response = await _put(
      '/notifications/preferences',
      auth: true,
      body: jsonEncode({
        if (allEnabled != null) 'all_enabled': allEnabled,
        if (frequency != null) 'frequency': frequency,
        if (categories != null) 'categories': categories,
        if (quietHours != null) 'quiet_hours': quietHours,
        if (reminderPreferences != null)
          'reminder_preferences': reminderPreferences,
      }),
    );
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'notification preferences');
  }

  Future<List<CharityItem>> getFeaturedCharities() async {
    // Featured charities are public catalogue data. Requiring an access token
    // here made the donations screen fail for signed-out users and for users
    // whose token had expired, even though the backend endpoint is public.
    final response = await _get('/charities/featured', auth: false);
    final decoded = _handleJson(response);
    return expectList(decoded, context: 'featured charities')
        .map(
          (item) => CharityItem.fromJson(
            expectMap(item, context: 'featured charity'),
          ),
        )
        .toList();
  }

  Future<AdminCharityPage> getAdminCharities({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _get(
      '/admin/charities/',
      auth: true,
      query: {'limit': limit, 'offset': offset},
    );
    return AdminCharityPage.fromJson(
      expectMap(_handleJson(response), context: 'admin charities'),
    );
  }

  Future<AdminCharityRecord> createAdminCharity({
    required String name,
    String? websiteUrl,
    String? title,
    String donationType = 'external',
    String? caseName,
    String? description,
    String? category,
    double? targetAmount,
    double? amountRaised,
    String currency = 'NGN',
    String? evidence,
    List<String>? imageUrls,
    List<String>? evidenceUrls,
    String? contactInfo,
    String status = 'active',
    String? deadline,
    bool isPublished = true,
    bool isFeatured = false,
  }) async {
    final response = await _post(
      '/admin/charities/',
      auth: true,
      body: jsonEncode({
        'name': name,
        'donation_type': donationType,
        if (websiteUrl != null && websiteUrl.isNotEmpty)
          'website_url': websiteUrl,
        if (title != null) 'title': title,
        if (caseName != null) 'case_name': caseName,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (targetAmount != null) 'target_amount': targetAmount,
        if (amountRaised != null) 'amount_raised': amountRaised,
        'currency': currency,
        if (evidence != null) 'evidence': evidence,
        if (imageUrls != null) 'image_urls': imageUrls,
        if (evidenceUrls != null) 'evidence_urls': evidenceUrls,
        if (contactInfo != null) 'contact_info': contactInfo,
        'status': status,
        if (deadline != null) 'deadline': deadline,
        'is_published': isPublished,
        'is_featured': isFeatured,
      }),
    );
    return AdminCharityRecord.fromJson(
      expectMap(_handleJson(response), context: 'admin charity'),
    );
  }

  Future<AdminCharityRecord> updateAdminCharity({
    required int charityId,
    String? name,
    String? websiteUrl,
    String? title,
    String? donationType,
    String? caseName,
    String? description,
    String? category,
    double? targetAmount,
    double? amountRaised,
    String? currency,
    String? evidence,
    List<String>? imageUrls,
    List<String>? evidenceUrls,
    String? contactInfo,
    String? status,
    String? deadline,
    bool? isPublished,
    bool? isVerified,
    bool? isActive,
    bool? isFeatured,
  }) async {
    final response = await _patch(
      '/admin/charities/$charityId',
      auth: true,
      body: jsonEncode({
        if (name != null) 'name': name,
        if (websiteUrl != null) 'website_url': websiteUrl,
        if (title != null) 'title': title,
        if (donationType != null) 'donation_type': donationType,
        if (caseName != null) 'case_name': caseName,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (targetAmount != null) 'target_amount': targetAmount,
        if (amountRaised != null) 'amount_raised': amountRaised,
        if (currency != null) 'currency': currency,
        if (evidence != null) 'evidence': evidence,
        if (imageUrls != null) 'image_urls': imageUrls,
        if (evidenceUrls != null) 'evidence_urls': evidenceUrls,
        if (contactInfo != null) 'contact_info': contactInfo,
        if (status != null) 'status': status,
        if (deadline != null) 'deadline': deadline,
        if (isPublished != null) 'is_published': isPublished,
        if (isVerified != null) 'is_verified': isVerified,
        if (isActive != null) 'is_active': isActive,
        if (isFeatured != null) 'is_featured': isFeatured,
      }),
    );
    return AdminCharityRecord.fromJson(
      expectMap(_handleJson(response), context: 'admin charity'),
    );
  }

  Future<void> deleteAdminCharity(int charityId) async {
    await _delete('/admin/charities/$charityId', auth: true);
  }

  Future<AdminCharityRecord> uploadAdminCharityImages({
    required int charityId,
    required List<PickedUploadFile> files,
    bool replace = false,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/admin/charities/$charityId/images', {'replace': replace}),
    );
    final token = await getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    for (final file in files) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'files',
          file.bytes,
          filename: file.filename,
        ),
      );
    }
    final streamed = await request.send().timeout(_uploadTimeout);
    final response = await http.Response.fromStream(streamed);
    return AdminCharityRecord.fromJson(
      expectMap(_handleJson(response), context: 'admin charity'),
    );
  }

  Future<AdminCharityRecord> uploadAdminCharityEvidence({
    required int charityId,
    required List<PickedUploadFile> files,
    bool replace = false,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/admin/charities/$charityId/evidence', {'replace': replace}),
    );
    final token = await getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    for (final file in files) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'files',
          file.bytes,
          filename: file.filename,
        ),
      );
    }
    final streamed = await request.send().timeout(_uploadTimeout);
    final response = await http.Response.fromStream(streamed);
    return AdminCharityRecord.fromJson(
      expectMap(_handleJson(response), context: 'admin charity'),
    );
  }

  Future<CharityDetail> getCharity(int charityId) async {
    final response = await _get('/charities/$charityId', auth: false);
    return CharityDetail.fromJson(
      expectMap(_handleJson(response), context: 'charity'),
    );
  }

  Future<CharityPage> getCharities({
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _get(
      '/charities/',
      query: {
        if (category != null && category.isNotEmpty) 'category': category,
        'limit': limit,
        'offset': offset,
      },
      auth: false,
    );
    return CharityPage.fromJson(_handleJson(response));
  }

  Future<AdminEvidencePage> getAdminEvidence({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _get(
      '/admin/evidence/',
      auth: true,
      query: {'limit': limit, 'offset': offset},
    );
    return AdminEvidencePage.fromJson(
      expectMap(_handleJson(response), context: 'admin evidence'),
    );
  }

  Future<AdminEvidenceDetail> getAdminEvidenceForAct(int actId) async {
    final response = await _get('/admin/evidence/$actId', auth: true);
    return AdminEvidenceDetail.fromJson(
      expectMap(_handleJson(response), context: 'admin evidence for act'),
    );
  }

  Future<AdminEvidenceRecord> createAdminEvidence({
    required int actId,
    required String sourceType,
    required String reference,
    String? arabicText,
    String? englishText,
    String? grade,
  }) async {
    final response = await _post(
      '/admin/evidence/',
      auth: true,
      body: jsonEncode({
        'act_id': actId,
        'source_type': sourceType,
        'reference': reference,
        if (arabicText != null) 'arabic_text': arabicText,
        if (englishText != null) 'english_text': englishText,
        if (grade != null) 'grade': grade,
      }),
    );
    return AdminEvidenceRecord.fromJson(
      expectMap(_handleJson(response), context: 'admin evidence'),
    );
  }

  Future<AdminEvidenceRecord> updateAdminEvidence({
    required int evidenceId,
    int? actId,
    String? sourceType,
    String? reference,
    String? arabicText,
    String? englishText,
    String? grade,
    bool? isVerified,
  }) async {
    final response = await _patch(
      '/admin/evidence/$evidenceId',
      auth: true,
      body: jsonEncode({
        if (actId != null) 'act_id': actId,
        if (sourceType != null) 'source_type': sourceType,
        if (reference != null) 'reference': reference,
        if (arabicText != null) 'arabic_text': arabicText,
        if (englishText != null) 'english_text': englishText,
        if (grade != null) 'grade': grade,
        if (isVerified != null) 'is_verified': isVerified,
      }),
    );
    return AdminEvidenceRecord.fromJson(
      expectMap(_handleJson(response), context: 'admin evidence'),
    );
  }

  Future<void> deleteAdminEvidence(int evidenceId) async {
    await _delete('/admin/evidence/$evidenceId', auth: true);
  }

  Future<Map<String, dynamic>> createFamilyJar({
    required String name,
    int capacity = 33,
  }) async {
    final response = await _post(
      '/family/create',
      auth: true,
      query: {'name': name, 'capacity': capacity},
    );
    final decoded = _handleJson(response);
    final map = expectMap(decoded, context: 'family');
    await saveLastFamilyJarId((map['id'] as num?)?.toInt());
    return map;
  }

  Future<Map<String, dynamic>> joinFamilyJar({
    required String inviteCode,
  }) async {
    final normalizedCode = inviteCode.trim().toUpperCase();
    final response = await _post(
      '/family/join',
      auth: true,
      body: jsonEncode({'invite_code': normalizedCode}),
    );
    final decoded = _handleJson(response);
    final map = expectMap(decoded, context: 'family');
    await saveLastFamilyJarId((map['id'] as num?)?.toInt());
    return map;
  }

  Future<List<LeaderboardEntry>> getFamilyLeaderboard({
    required int jarId,
    int limit = 10,
  }) async {
    final response = await _get(
      '/family/$jarId/leaderboard',
      auth: true,
      query: {'limit': limit},
    );
    final decoded = _handleJson(response);
    return expectList(decoded, context: 'family leaderboard')
        .map(
          (i) => LeaderboardEntry.fromJson(
            expectMap(i, context: 'leaderboard entry'),
          ),
        )
        .toList();
  }

  Future<Map<String, dynamic>> getFamilyTopContributor({
    required int jarId,
  }) async {
    final response = await _get('/family/$jarId/top-contributor', auth: true);
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'notification preferences');
  }

  Future<Map<String, dynamic>> getFamilyJarDetail({required int jarId}) async {
    final response = await _get('/family/$jarId', auth: true);
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'notification preferences');
  }

  Future<List<Map<String, dynamic>>> getFridayRecommendations() async {
    final response = await _get('/friday/recommendations', auth: true);
    final decoded = _handleJson(response);
    return expectList(
      decoded,
      context: 'friday recommendations',
    ).map((item) => expectMap(item, context: 'friday recommendation')).toList();
  }

  Future<List<Map<String, dynamic>>> getMorningAdhkar() async {
    final response = await _get('/adhkar/morning', auth: true);
    final decoded = _handleJson(response);
    return expectList(
      decoded,
      context: 'friday recommendations',
    ).map((item) => expectMap(item, context: 'friday recommendation')).toList();
  }

  Future<List<Map<String, dynamic>>> getEveningAdhkar() async {
    final response = await _get('/adhkar/evening', auth: true);
    final decoded = _handleJson(response);
    return expectList(
      decoded,
      context: 'friday recommendations',
    ).map((item) => expectMap(item, context: 'friday recommendation')).toList();
  }

  Future<JourneyReflectionPage> getReflections({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _get(
      '/journey/reflections',
      auth: true,
      query: {'limit': limit, 'offset': offset},
    );
    final decoded = _handleJson(response);
    final data = expectList(decoded, context: 'reflections');
    final meta =
        decoded is Map<String, dynamic> ? _getEnvelopeMeta(decoded) : null;
    return JourneyReflectionPage(
      items:
          data
              .map(
                (i) => JourneyReflection.fromJson(
                  expectMap(i, context: 'reflection item'),
                ),
              )
              .toList(),
      total: (meta?['total'] as num?)?.toInt() ?? 0,
    );
  }

  Future<JourneyReflection> createReflection({
    required String title,
    required String body,
    required String mood,
    bool isPrivate = false,
    DateTime? date,
    String? requestId,
  }) async {
    final response = await _post(
      '/journey/reflections',
      auth: true,
      body: jsonEncode({
        'title': title,
        'body': body,
        'mood': mood,
        'is_private': isPrivate,
        if (date != null) 'date': date.toIso8601String(),
        if (requestId != null && requestId.isNotEmpty) 'request_id': requestId,
      }),
    );
    final decoded = _handleJson(response);
    final result = JourneyReflection.fromJson(
      expectMap(decoded, context: 'create reflection'),
    );
    reflectionRevision.value++;
    return result;
  }

  Future<JourneyReflection> updateReflection(
    int reflectionId, {
    String? title,
    String? body,
    String? mood,
    bool? isPrivate,
    DateTime? date,
  }) async {
    final response = await _patch(
      '/journey/reflections/$reflectionId',
      auth: true,
      body: jsonEncode({
        if (title != null) 'title': title,
        if (body != null) 'body': body,
        if (mood != null) 'mood': mood,
        if (isPrivate != null) 'is_private': isPrivate,
        if (date != null) 'date': date.toIso8601String(),
      }),
    );
    final decoded = _handleJson(response);
    final result = JourneyReflection.fromJson(
      expectMap(decoded, context: 'create reflection'),
    );
    reflectionRevision.value++;
    return result;
  }

  Future<void> deleteReflection(int reflectionId) async {
    await _delete('/journey/reflections/$reflectionId', auth: true);
    reflectionRevision.value++;
  }

  Future<JourneyAdhkarProgress> setAdhkarProgress(
    int adhkarId,
    int count,
  ) async {
    final response = await _post(
      '/journey/adhkar/$adhkarId/progress',
      auth: true,
      body: jsonEncode({'count': count}),
    );
    final decoded = _handleJson(response);
    return JourneyAdhkarProgress.fromJson(
      expectMap(decoded, context: 'set adhkar progress'),
    );
  }

  Future<List<JourneyAdhkarProgress>> getAdhkarProgress() async {
    final response = await _get('/journey/adhkar/progress', auth: true);
    final decoded = _handleJson(response);
    return expectList(decoded, context: 'adhkar progress')
        .map(
          (i) => JourneyAdhkarProgress.fromJson(
            expectMap(i, context: 'adhkar progress item'),
          ),
        )
        .toList();
  }

  Future<JourneyAdhkarProgress> getAdhkarProgressFor(int adhkarId) async {
    final response = await _get(
      '/journey/adhkar/$adhkarId/progress',
      auth: true,
    );
    final decoded = _handleJson(response);
    return JourneyAdhkarProgress.fromJson(
      expectMap(decoded, context: 'set adhkar progress'),
    );
  }

  Future<JourneyAdhkarFavorite> favoriteAdhkar(int adhkarId) async {
    final response = await _post(
      '/journey/adhkar/$adhkarId/favorite',
      auth: true,
    );
    final decoded = _handleJson(response);
    return JourneyAdhkarFavorite.fromJson(
      expectMap(decoded, context: 'favorite adhkar'),
    );
  }

  Future<void> unfavoriteAdhkar(int adhkarId) async {
    final response = await _delete(
      '/journey/adhkar/$adhkarId/favorite',
      auth: true,
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    // B2/A0.1: a 2xx envelope may carry an informational message (e.g. Notification deleted).
    // _handleJson already throws for statusCode >= 400, so a message on success is NOT an error.
    _getEnvelopeMessage(decoded);
  }

  Future<List<JourneyAdhkarFavorite>> getAdhkarFavorites() async {
    final response = await _get('/journey/adhkar/favorites', auth: true);
    final decoded = _handleJson(response);
    return expectList(decoded, context: 'adhkar favorites')
        .map(
          (i) => JourneyAdhkarFavorite.fromJson(
            expectMap(i, context: 'adhkar favorite item'),
          ),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getTodaysGentleActs({
    int limit = 3,
  }) async {
    final response = await _get(
      '/sadaqah/acts',
      auth: true,
      query: {'limit': limit, 'verified_only': 'true'},
    );
    final decoded = _handleJson(response);
    return expectList(
      decoded,
      context: 'gentle acts',
    ).map((i) => expectMap(i, context: 'gentle act')).toList();
  }

  Future<Map<String, dynamic>?> getLastReadingProgress() async {
    try {
      final response = await _get('/journey/reading/last', auth: true);
      final decoded = _handleJson(response);
      return expectMapOrNull(decoded, context: 'last reading progress');
    } on BackendApiException catch (_) {
      return null;
    }
  }

  Future<void> saveReadingProgress({
    required int bookId,
    required int chapterNumber,
  }) async {
    await _post(
      '/journey/reading/progress',
      auth: true,
      body: jsonEncode({'book_id': bookId, 'chapter_number': chapterNumber}),
    );
  }

  Future<Map<String, dynamic>?> getQuranProgress() async {
    try {
      final response = await _get('/journey/quran/progress', auth: true);
      final decoded = _handleJson(response);
      return expectMapOrNull(decoded, context: 'last reading progress');
    } on BackendApiException catch (_) {
      return null;
    }
  }

  Future<void> saveQuranProgress({
    required int surahId,
    required String verseKey,
    required int page,
  }) async {
    await _post(
      '/journey/quran/progress',
      auth: true,
      body: jsonEncode({
        'surah_id': surahId,
        'verse_key': verseKey,
        'page': page,
      }),
    );
  }

  Future<List<Map<String, dynamic>>> getQuranSurahs() async {
    final response = await _get('/quran/surahs', auth: true);
    final decoded = _handleJson(response);
    return expectList(
      decoded,
      context: 'quran surahs',
    ).map((item) => expectMap(item, context: 'quran surah')).toList();
  }

  Future<List<Map<String, dynamic>>> getQuranSurahAyahs(int surahId) async {
    final response = await _get('/quran/surahs/$surahId/ayahs', auth: true);
    final decoded = _handleJson(response);
    return expectList(
      decoded,
      context: 'quran ayahs',
    ).map((item) => expectMap(item, context: 'quran ayah')).toList();
  }

  Future<Set<String>> getPrayerCompletions(DateTime localDate) async {
    final response = await _get(
      '/journey/prayers/progress',
      auth: true,
      query: {'local_date': localDate.toIso8601String().substring(0, 10)},
    );
    final decoded = _handleJson(response);
    final data = expectMap(decoded, context: 'prayer progress');
    final completed = data['completed_prayers'];
    if (completed is! List) return <String>{};
    return completed.map((item) => item.toString().toLowerCase()).toSet();
  }

  Future<void> setPrayerCompletion({
    required DateTime localDate,
    required String prayerName,
    required bool completed,
  }) async {
    final response = await _put(
      '/journey/prayers/progress',
      auth: true,
      body: jsonEncode({
        'local_date': localDate.toIso8601String().substring(0, 10),
        'prayer_name': prayerName.toLowerCase(),
        'completed': completed,
      }),
    );
    _handleJson(response);
  }

  Future<List<Map<String, dynamic>>> getQuranJuzAyahs(int juzNumber) async {
    final response = await _get('/quran/juz/$juzNumber', auth: true);
    final decoded = _handleJson(response);
    return expectList(
      decoded,
      context: 'quran juz ayahs',
    ).map((item) => expectMap(item, context: 'quran juz ayah')).toList();
  }

  Future<List<Map<String, dynamic>>> getQuranHizbAyahs(int hizbNumber) async {
    final response = await _get('/quran/hizb/$hizbNumber', auth: true);
    final decoded = _handleJson(response);
    return expectList(
      decoded,
      context: 'quran hizb ayahs',
    ).map((item) => expectMap(item, context: 'quran hizb ayah')).toList();
  }

  Future<Map<String, dynamic>> getQuranPage(int pageNumber) async {
    final response = await _get('/quran/pages/$pageNumber', auth: true);
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'quran page');
  }

  Future<List<Map<String, dynamic>>> getTodaysReflections() async {
    final response = await _get(
      '/journey/reflections',
      auth: true,
      query: {'limit': 5},
    );
    final decoded = _handleJson(response);
    return expectListOrEmpty(
      decoded,
      context: 'today reflections',
    ).map((i) => expectMap(i, context: 'today reflection')).toList();
  }

  // ── Goals API ──────────────────────────────────────────────

  Future<Map<String, dynamic>> createGoal({
    required String title,
    String? subtitle,
    required int actsTarget,
    String? month,
  }) async {
    final response = await _post(
      '/goals',
      auth: true,
      body: jsonEncode({
        'title': title,
        if (subtitle != null && subtitle.isNotEmpty) 'subtitle': subtitle,
        'acts_target': actsTarget,
        if (month != null) 'month': month,
      }),
    );
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'goal creation');
  }

  Future<Map<String, dynamic>> getGoals({String? status, String? month}) async {
    final query = <String, dynamic>{};
    if (status != null) query['status'] = status;
    if (month != null) query['month'] = month;
    final response = await _get('/goals', auth: true, query: query);
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'goals');
  }

  Future<Map<String, dynamic>> getGoal(int goalId) async {
    final response = await _get('/goals/$goalId', auth: true);
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'goal');
  }

  Future<Map<String, dynamic>> updateGoal({
    required int goalId,
    String? title,
    String? subtitle,
    int? actsTarget,
  }) async {
    final response = await _patch(
      '/goals/$goalId',
      auth: true,
      body: jsonEncode({
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (actsTarget != null) 'acts_target': actsTarget,
      }),
    );
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'goal update');
  }

  /// Archives the current active goal and creates its successor in one
  /// backend transaction. Completed/replaced goals remain available in the
  /// goal history; only one personal goal can be active at a time.
  Future<Map<String, dynamic>> replaceGoal({
    required int goalId,
    required String title,
    String? subtitle,
    required int actsTarget,
    String? month,
  }) async {
    final response = await _post(
      '/goals/$goalId/replace',
      auth: true,
      body: jsonEncode({
        'title': title,
        if (subtitle != null && subtitle.isNotEmpty) 'subtitle': subtitle,
        'acts_target': actsTarget,
        if (month != null) 'month': month,
      }),
    );
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'replace goal');
  }

  Future<Map<String, dynamic>> updateGoalProgress(
    int goalId,
    int actsDone,
  ) async {
    final response = await _patch(
      '/goals/$goalId/progress',
      auth: true,
      body: jsonEncode({'acts_done': actsDone}),
    );
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'goal progress');
  }

  Future<Map<String, dynamic>> updateGoalStatus(
    int goalId,
    String status,
  ) async {
    final response = await _patch(
      '/goals/$goalId/status',
      auth: true,
      body: jsonEncode({'status': status}),
    );
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'goal status');
  }

  Future<void> deleteGoal(int goalId) async {
    await _delete('/goals/$goalId', auth: true);
  }

  Future<Map<String, dynamic>> checkMonthlyReview() async {
    final response = await _get('/goals/reviews/check', auth: true);
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'notification preferences');
  }

  Future<Map<String, dynamic>> submitMonthlyReview({
    String? actionTaken,
    String? notes,
    int goalsCompleted = 0,
    int goalsActive = 0,
    int totalActsDone = 0,
    int streakAtReview = 0,
  }) async {
    final response = await _post(
      '/goals/reviews',
      auth: true,
      body: jsonEncode({
        if (actionTaken != null) 'action_taken': actionTaken,
        if (notes != null) 'notes': notes,
        'goals_completed': goalsCompleted,
        'goals_active': goalsActive,
        'total_acts_done': totalActsDone,
        'streak_at_review': streakAtReview,
      }),
    );
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'notification preferences');
  }

  Future<void> leaveFamilyJar({required int jarId}) async {
    final response = await _post('/family/$jarId/leave', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    // B2/A0.1: a 2xx envelope may carry an informational message (e.g. Notification deleted).
    // _handleJson already throws for statusCode >= 400, so a message on success is NOT an error.
    _getEnvelopeMessage(decoded);
  }

  Future<List<Map<String, dynamic>>> getFamilyMembers({
    required int jarId,
  }) async {
    final response = await _get('/family/$jarId/members', auth: true);
    final decoded = _handleJson(response);
    return expectList(
      decoded,
      context: 'family members',
    ).map((i) => expectMap(i, context: 'family member')).toList();
  }

  Future<void> removeFamilyMember({
    required int jarId,
    required int memberId,
  }) async {
    final response = await _delete(
      '/family/$jarId/members/$memberId',
      auth: true,
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    // B2/A0.1: a 2xx envelope may carry an informational message (e.g. Notification deleted).
    // _handleJson already throws for statusCode >= 400, so a message on success is NOT an error.
    _getEnvelopeMessage(decoded);
  }

  Future<Map<String, dynamic>> updateFamilyMemberRole({
    required int familyId,
    required int memberId,
    required String role,
  }) async {
    final response = await _patch(
      '/family/$familyId/members/$memberId/role',
      auth: true,
      body: jsonEncode({'role': role.toLowerCase()}),
    );
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'family member role');
  }

  Future<Map<String, dynamic>> updateFamily({
    required int familyId,
    String? name,
    String? coverIcon,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (coverIcon != null) body['cover_icon'] = coverIcon;
    final response = await _patch(
      '/family/$familyId',
      auth: true,
      body: jsonEncode(body),
    );
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'family');
  }

  Future<List<Map<String, dynamic>>> getPendingInvitations() async {
    final response = await _get('/family/invitations', auth: true);
    final decoded = _handleJson(response);
    return expectList(
      decoded,
      context: 'family invitations',
    ).map((i) => expectMap(i, context: 'family invitation')).toList();
  }

  Future<List<Map<String, dynamic>>> getFamilyInvitations(int familyId) async {
    final response = await _get('/family/$familyId/invitations', auth: true);
    final decoded = _handleJson(response);
    return expectList(
      decoded,
      context: 'family invitations',
    ).map((i) => expectMap(i, context: 'family invitation')).toList();
  }

  Future<List<Map<String, dynamic>>> getIncomingFamilyInvitations() async {
    final response = await _get('/family/invitations/incoming', auth: true);
    final decoded = _handleJson(response);
    return expectList(
      decoded,
      context: 'incoming family invitations',
    ).map((i) => expectMap(i, context: 'incoming family invitation')).toList();
  }

  Future<Map<String, dynamic>> createTargetedFamilyInvitation({
    required int familyId,
    required String email,
  }) async {
    final response = await _post(
      '/family/$familyId/invitations',
      auth: true,
      body: jsonEncode({'invited_email': email.trim()}),
    );
    return expectMap(_handleJson(response), context: 'family invitation');
  }

  Future<void> acceptFamilyInvitation(int invitationId) async {
    await _post('/family/invitations/id/$invitationId/accept', auth: true);
  }

  Future<void> declineFamilyInvitation(int invitationId) async {
    await _post('/family/invitations/id/$invitationId/decline', auth: true);
  }

  Future<void> cancelFamilyInvitation({
    required int familyId,
    required int invitationId,
  }) async {
    await _delete('/family/$familyId/invitations/$invitationId', auth: true);
  }

  Future<List<Map<String, dynamic>>> getFamilyGoals(int familyId) async {
    final response = await _get('/family/$familyId/goals', auth: true);
    final decoded = _handleJson(response);
    return expectList(
      decoded,
      context: 'family members',
    ).map((i) => expectMap(i, context: 'family member')).toList();
  }

  Future<Map<String, dynamic>> createFamilyGoal(
    int familyId, {
    required String title,
    String? subtitle,
    required int actsTarget,
  }) async {
    final response = await _post(
      '/family/$familyId/goals',
      auth: true,
      body: jsonEncode({
        'title': title,
        if (subtitle != null && subtitle.isNotEmpty) 'subtitle': subtitle,
        'acts_target': actsTarget,
      }),
    );
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'notification preferences');
  }

  Future<List<Map<String, dynamic>>> getFamilyReflections(
    int familyId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _get(
      '/family/$familyId/reflections',
      auth: true,
      query: {'limit': limit, 'offset': offset},
    );
    final decoded = _handleJson(response);
    return expectList(
      decoded,
      context: 'family members',
    ).map((i) => expectMap(i, context: 'family member')).toList();
  }

  Future<Map<String, dynamic>> createFamilyReflection(
    int familyId, {
    required String text,
  }) async {
    final response = await _post(
      '/family/$familyId/reflections',
      auth: true,
      body: jsonEncode({'text': text}),
    );
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'notification preferences');
  }

  Future<Map<String, dynamic>> updateFamilyReflection(
    int familyId,
    int reflectionId, {
    required String text,
  }) async {
    final response = await _patch(
      '/family/$familyId/reflections/$reflectionId',
      auth: true,
      body: jsonEncode({'text': text}),
    );
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'notification preferences');
  }

  Future<Map<String, dynamic>> encourageFamilyReflection(
    int familyId,
    int reflectionId,
    String encouragementType,
  ) async {
    final response = await _post(
      '/family/$familyId/reflections/$reflectionId/encourage',
      auth: true,
      body: jsonEncode({'encouragement_type': encouragementType}),
    );
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'notification preferences');
  }

  Future<List<Map<String, dynamic>>> getFamilyPrayers(
    int familyId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _get(
      '/family/$familyId/prayers',
      auth: true,
      query: {'limit': limit, 'offset': offset},
    );
    final decoded = _handleJson(response);
    return expectList(
      decoded,
      context: 'family members',
    ).map((i) => expectMap(i, context: 'family member')).toList();
  }

  Future<Map<String, dynamic>> createFamilyPrayer(
    int familyId, {
    required String text,
    bool isPrivate = false,
  }) async {
    final response = await _post(
      '/family/$familyId/prayers',
      auth: true,
      body: jsonEncode({'text': text, 'is_private': isPrivate}),
    );
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'notification preferences');
  }

  Future<Map<String, dynamic>> respondToFamilyPrayer(
    int familyId,
    int prayerId,
    String responseType,
  ) async {
    final response = await _post(
      '/family/$familyId/prayers/$prayerId/respond',
      auth: true,
      body: jsonEncode({'response_type': responseType}),
    );
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'notification preferences');
  }

  Future<List<Map<String, dynamic>>> getPrayerComments(
    int familyId,
    int prayerId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _get(
      '/family/$familyId/prayers/$prayerId/comments',
      auth: true,
      query: {'limit': limit, 'offset': offset},
    );
    final decoded = _handleJson(response);
    return expectList(
      decoded,
      context: 'family members',
    ).map((i) => expectMap(i, context: 'family member')).toList();
  }

  Future<Map<String, dynamic>> createPrayerComment(
    int familyId,
    int prayerId, {
    required String text,
  }) async {
    final response = await _post(
      '/family/$familyId/prayers/$prayerId/comments',
      auth: true,
      body: jsonEncode({'text': text}),
    );
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'notification preferences');
  }

  Future<Map<String, dynamic>> updatePrayerComment(
    int familyId,
    int prayerId,
    int commentId, {
    required String text,
  }) async {
    final response = await _patch(
      '/family/$familyId/prayers/$prayerId/comments/$commentId',
      auth: true,
      body: jsonEncode({'text': text}),
    );
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'notification preferences');
  }

  Future<void> deletePrayerComment(
    int familyId,
    int prayerId,
    int commentId,
  ) async {
    await _delete(
      '/family/$familyId/prayers/$prayerId/comments/$commentId',
      auth: true,
    );
  }

  Future<Map<String, dynamic>> getFamilySettings(int familyId) async {
    final response = await _get('/family/$familyId/settings', auth: true);
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'notification preferences');
  }

  Future<Map<String, dynamic>> updateFamilySettings(
    int familyId, {
    Map<String, bool>? notificationPreferences,
  }) async {
    final response = await _patch(
      '/family/$familyId/settings',
      auth: true,
      body: jsonEncode({
        if (notificationPreferences != null)
          'notification_preferences': notificationPreferences,
      }),
    );
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'notification preferences');
  }

  Future<void> archiveFamilyJar(int familyId) async {
    final response = await _post('/family/$familyId/archive', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    // B2/A0.1: a 2xx envelope may carry an informational message (e.g. Notification deleted).
    // _handleJson already throws for statusCode >= 400, so a message on success is NOT an error.
    _getEnvelopeMessage(decoded);
  }

  Future<void> deleteFamilyJar(int familyId) async {
    await _delete('/family/$familyId', auth: true);
  }

  Future<List<Map<String, dynamic>>> getFamilies({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _get(
      '/family/',
      auth: true,
      query: {'limit': limit, 'offset': offset},
    );
    final decoded = _handleJson(response);
    return expectList(
      decoded,
      context: 'families',
    ).map((item) => expectMap(item, context: 'family item')).toList();
  }

  Future<Map<String, dynamic>> getFamilyDetail(int familyId) async {
    final response = await _get('/family/$familyId', auth: true);
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'notification preferences');
  }

  Future<Map<String, dynamic>?> getFamilyIntention(int familyId) async {
    final response = await _get('/family/$familyId/intention', auth: true);
    final decoded = _handleJson(response);
    if (decoded == null) return null;
    return expectMap(decoded, context: 'family intention');
  }

  Future<Map<String, dynamic>> saveFamilyIntention(
    int familyId, {
    required String title,
    String? prompt,
  }) async {
    final response = await _put(
      '/family/$familyId/intention',
      auth: true,
      body: jsonEncode({
        'title': title,
        if (prompt != null && prompt.trim().isNotEmpty) 'prompt': prompt.trim(),
      }),
    );
    return expectMap(_handleJson(response), context: 'family intention');
  }

  Future<Map<String, dynamic>> saveFamilyIntentionContribution(
    int familyId, {
    required bool completed,
    String? privateNote,
  }) async {
    final response = await _patch(
      '/family/$familyId/intention/contribution',
      auth: true,
      body: jsonEncode({
        'completed': completed,
        if (privateNote != null) 'private_note': privateNote,
      }),
    );
    return expectMap(_handleJson(response), context: 'family contribution');
  }

  Future<void> deleteFamilyReflection(int familyId, int reflectionId) async {
    await _delete('/family/$familyId/reflections/$reflectionId', auth: true);
  }

  Future<List<Map<String, dynamic>>> getFamilyReflectionComments(
    int familyId,
    int reflectionId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _get(
      '/family/$familyId/reflections/$reflectionId/comments',
      auth: true,
      query: {'limit': limit, 'offset': offset},
    );
    final decoded = _handleJson(response);
    return expectList(
      decoded,
      context: 'reflection comments',
    ).map((item) => expectMap(item, context: 'reflection comment')).toList();
  }

  Future<Map<String, dynamic>> createFamilyReflectionComment(
    int familyId,
    int reflectionId, {
    required String text,
  }) async {
    final response = await _post(
      '/family/$familyId/reflections/$reflectionId/comments',
      auth: true,
      body: jsonEncode({'text': text}),
    );
    return expectMap(_handleJson(response), context: 'reflection comment');
  }

  Future<void> deleteFamilyReflectionComment(
    int familyId,
    int reflectionId,
    int commentId,
  ) async {
    await _delete(
      '/family/$familyId/reflections/$reflectionId/comments/$commentId',
      auth: true,
    );
  }

  Future<List<Map<String, dynamic>>> getFamilyActivity(
    int familyId, {
    int limit = 30,
    String? cursor,
  }) async {
    final response = await _get(
      '/family/$familyId/activity',
      auth: false,
      query: {'limit': limit, if (cursor != null) 'cursor': cursor},
    );
    final decoded = _handleJson(response);
    return expectList(
      decoded,
      context: 'family activity',
    ).map((item) => expectMap(item, context: 'family activity item')).toList();
  }

  Future<Map<String, dynamic>> addFamilyAct(
    int familyId, {
    String? type,
    String? note,
    String? requestId,
  }) async {
    final response = await _post(
      '/family/$familyId/add-act',
      auth: true,
      body: jsonEncode({
        'act_type':
            (type == null || type.trim().isEmpty) ? 'sadaqah' : type.trim(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        if (requestId != null && requestId.isNotEmpty) 'request_id': requestId,
      }),
    );
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'notification preferences');
  }

  Future<Map<String, dynamic>> bookmarkBook({
    required int bookId,
    int? chapterNumber,
  }) async {
    final response = await _post(
      '/books/$bookId/bookmark',
      auth: true,
      body: jsonEncode({
        if (chapterNumber != null) 'chapter_number': chapterNumber,
      }),
    );
    final decoded = _handleJson(response);
    return expectMap(decoded, context: 'notification preferences');
  }

  Future<void> unbookmarkBook({required int bookId}) async {
    await _delete('/books/$bookId/bookmark', auth: true);
  }

  Future<List<Map<String, dynamic>>> getBookmarks({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _get(
      '/books/bookmarks',
      auth: true,
      query: {'limit': limit, 'offset': offset},
    );
    final decoded = _handleJson(response);
    // The /books/bookmarks endpoint returns an Envelope wrapping a paginated
    // object: {"data": {"data": [...], "total": N, ...}}. We unwrap the outer
    // envelope once, then read the inner `data` list from the paginated object.
    final unwrapped = _unwrap(decoded);
    final map = expectMap(unwrapped, context: 'bookmarks');
    return expectList(
      map['data'],
      context: 'bookmark items',
    ).map((i) => expectMap(i, context: 'bookmark item')).toList();
  }

  Future<List<BookRead>> getBooks({int limit = 50, int offset = 0}) async {
    final response = await _get(
      '/books/',
      auth: true,
      query: {'limit': limit, 'offset': offset},
    );
    final decoded = _handleJson(response);
    final data = expectList(decoded, context: 'books');
    return data
        .map((item) => BookRead.fromJson(expectMap(item, context: 'book item')))
        .toList();
  }

  Future<BookDetail> getBook(int bookId) async {
    final response = await _get('/books/$bookId', auth: true);
    final decoded = _handleJson(response);
    return BookDetail.fromJson(expectMap(decoded, context: 'book'));
  }

  Future<List<BookChapterRead>> getBookChapters(int bookId) async {
    final response = await _get('/books/$bookId/chapters', auth: true);
    final decoded = _handleJson(response);
    return expectList(decoded, context: 'book chapters')
        .map(
          (item) => BookChapterRead.fromJson(
            expectMap(item, context: 'book chapter'),
          ),
        )
        .toList();
  }

  Future<AdminBookPage> getAdminBooks({int limit = 50, int offset = 0}) async {
    final response = await _get(
      '/admin/books/',
      auth: true,
      query: {'limit': limit, 'offset': offset},
    );
    final decoded = _handleJson(response);
    final map = expectMap(decoded, context: 'admin books');
    final meta = _getEnvelopeMeta(map);
    final rows =
        expectListOrEmpty(map['data'], context: 'admin book items')
            .map(
              (item) => AdminBookRecord.fromJson(
                expectMap(item, context: 'admin book item'),
              ),
            )
            .toList();
    return AdminBookPage(
      total: (meta?['total'] as num?)?.toInt() ?? rows.length,
      limit: limit,
      offset: offset,
      data: rows,
    );
  }

  Future<AdminBookRecord> createAdminBook({
    required String title,
    required String author,
    String? description,
    String? coverUrl,
    required String category,
    String language = 'en',
    bool published = true,
    int sortOrder = 0,
  }) async {
    final response = await _post(
      '/admin/books/',
      auth: true,
      body: jsonEncode({
        'title': title,
        'author': author,
        'description': description,
        'cover_url': coverUrl,
        'category': category,
        'language': language,
        'published': published,
        'sort_order': sortOrder,
      }),
    );
    final decoded = _handleJson(response);
    return AdminBookRecord.fromJson(expectMap(decoded, context: 'admin book'));
  }

  Future<AdminBookRecord> updateAdminBook(
    int bookId, {
    String? title,
    String? author,
    String? description,
    String? coverUrl,
    String? category,
    String? language,
    bool? published,
    int? sortOrder,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (author != null) body['author'] = author;
    if (description != null) body['description'] = description;
    if (coverUrl != null) body['cover_url'] = coverUrl;
    if (category != null) body['category'] = category;
    if (language != null) body['language'] = language;
    if (published != null) body['published'] = published;
    if (sortOrder != null) body['sort_order'] = sortOrder;
    final response = await _patch(
      '/admin/books/$bookId',
      auth: true,
      body: jsonEncode(body),
    );
    final decoded = _handleJson(response);
    return AdminBookRecord.fromJson(expectMap(decoded, context: 'admin book'));
  }

  Future<void> deleteAdminBook(int bookId) async {
    await _delete('/admin/books/$bookId', auth: true);
  }

  Future<BookDetail> getAdminBook(int bookId) async {
    final response = await _get('/admin/books/$bookId', auth: true);
    return BookDetail.fromJson(
      expectMap(_handleJson(response), context: 'admin book'),
    );
  }

  String absoluteApiUrl(String pathOrUrl) {
    final uri = Uri.tryParse(pathOrUrl);
    if (uri != null && uri.hasScheme) return pathOrUrl;
    final path = pathOrUrl.startsWith('/') ? pathOrUrl : '/$pathOrUrl';
    return '$baseUrl$path';
  }

  List<LeaderboardEntry> _leaderboardFromResponse(http.Response response) {
    final decoded = _handleJson(response);
    return expectList(decoded, context: 'leaderboard')
        .map(
          (item) => LeaderboardEntry.fromJson(
            expectMap(item, context: 'leaderboard entry'),
          ),
        )
        .toList();
  }

  dynamic _handleJson(http.Response response) {
    final body = response.body.isEmpty ? '{}' : response.body;
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      decoded = <String, dynamic>{
        'detail': 'Invalid JSON response from server',
      };
    }
    if (response.statusCode >= 400) {
      String message = 'Request failed (${response.statusCode})';
      String? code;
      if (decoded is Map<String, dynamic>) {
        // A0.1/A0.2: backend error envelope is {"error": {code, message, details}}.
        final error = decoded['error'];
        if (error is Map) {
          message = error['message']?.toString() ?? message;
          code = error['code']?.toString();
          throw BackendApiException(message, response.statusCode, code: code);
        }
        final detail = decoded['detail'];
        if (detail is Map) {
          message =
              detail['message']?.toString() ??
              detail['detail']?.toString() ??
              message;
          code = detail['code']?.toString();
        } else if (detail != null) {
          message = detail.toString();
        }
        code ??= decoded['code']?.toString();
      }
      throw BackendApiException(message, response.statusCode, code: code);
    }
    return decoded;
  }
}

class BackendApiException implements Exception {
  BackendApiException(this.message, this.statusCode, {this.code});

  final String message;
  final int statusCode;
  final String? code;

  @override
  String toString() =>
      code == null
          ? 'BackendApiException($statusCode): $message'
          : 'BackendApiException($statusCode, $code): $message';
}

String backendErrorMessage(Object error, {required String fallback}) {
  if (error is BackendApiException && error.message.trim().isNotEmpty) {
    return error.message.trim();
  }
  return fallback;
}

class PickedUploadFile {
  const PickedUploadFile({required this.filename, required this.bytes});

  final String filename;
  final List<int> bytes;
}

class DailyAct {
  DailyAct({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
  });

  final int id;
  final String title;
  final String category;
  final int difficulty;

  factory DailyAct.fromJson(Map<String, dynamic> json) {
    return DailyAct(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
    );
  }
}

class SadaqahActPage {
  SadaqahActPage({
    required this.total,
    required this.limit,
    required this.offset,
    required this.data,
  });

  final int total;
  final int limit;
  final int offset;
  final List<SadaqahActItem> data;

  factory SadaqahActPage.fromJson(Map<String, dynamic> json) {
    final rows =
        (json['data'] as List<dynamic>? ?? [])
            .map(
              (item) => SadaqahActItem.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
    return SadaqahActPage(
      total: (json['total'] as num?)?.toInt() ?? rows.length,
      limit: (json['limit'] as num?)?.toInt() ?? rows.length,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      data: rows,
    );
  }
}

class SadaqahActItem {
  SadaqahActItem({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
  });

  final int id;
  final String title;
  final String category;
  final int difficulty;

  factory SadaqahActItem.fromJson(Map<String, dynamic> json) {
    return SadaqahActItem(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
    );
  }
}

class SadaqahEvidence {
  SadaqahEvidence({
    required this.sourceType,
    required this.reference,
    required this.isVerified,
    this.grade,
    this.arabicText,
    this.englishText,
  });

  final String sourceType;
  final String reference;
  final String? grade;
  final String? arabicText;
  final String? englishText;
  final bool isVerified;

  factory SadaqahEvidence.fromJson(Map<String, dynamic> json) {
    return SadaqahEvidence(
      sourceType: json['source_type']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      grade: json['grade']?.toString(),
      arabicText: json['arabic_text']?.toString(),
      englishText: json['english_text']?.toString(),
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }
}

class SadaqahActDetail {
  SadaqahActDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.rewardWeight,
    this.estimatedTimeMinutes,
    this.evidence,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final int difficulty;
  final int rewardWeight;
  final int? estimatedTimeMinutes;
  final SadaqahEvidence? evidence;

  factory SadaqahActDetail.fromJson(Map<String, dynamic> json) {
    return SadaqahActDetail(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      rewardWeight: (json['reward_weight'] as num?)?.toInt() ?? 1,
      estimatedTimeMinutes: (json['estimated_time_minutes'] as num?)?.toInt(),
      evidence:
          json['evidence'] == null
              ? null
              : SadaqahEvidence.fromJson(
                Map<String, dynamic>.from(json['evidence'] as Map),
              ),
    );
  }
}

class CompletedJarPage {
  CompletedJarPage({
    required this.total,
    required this.limit,
    required this.offset,
    required this.data,
  });

  final int total;
  final int limit;
  final int offset;
  final List<CompletedJarItem> data;

  factory CompletedJarPage.fromJson(Map<String, dynamic> json) {
    final rows =
        (json['data'] as List<dynamic>? ?? [])
            .map(
              (item) => CompletedJarItem.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
    return CompletedJarPage(
      total: (json['total'] as num?)?.toInt() ?? rows.length,
      limit: (json['limit'] as num?)?.toInt() ?? rows.length,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      data: rows,
    );
  }
}

class CompletedJarItem {
  CompletedJarItem({
    required this.id,
    required this.currentStars,
    required this.capacity,
    this.completedAt,
    this.createdAt,
    this.daysToComplete,
  });

  final int id;
  final int currentStars;
  final int capacity;
  final String? completedAt;
  final String? createdAt;
  final int? daysToComplete;

  factory CompletedJarItem.fromJson(Map<String, dynamic> json) {
    return CompletedJarItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      currentStars: (json['current_stars'] as num?)?.toInt() ?? 0,
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      completedAt: json['completed_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      daysToComplete: (json['days_to_complete'] as num?)?.toInt(),
    );
  }
}

class JarStats {
  JarStats({
    required this.currentStars,
    required this.capacity,
    this.completedAt,
  });

  final int currentStars;
  final int capacity;
  final String? completedAt;

  factory JarStats.fromJson(Map<String, dynamic> json) {
    return JarStats(
      currentStars: (json['current_stars'] as num?)?.toInt() ?? 0,
      capacity: (json['capacity'] as num?)?.toInt() ?? 33,
      completedAt: json['completed_at']?.toString(),
    );
  }
}

class StreakInfo {
  StreakInfo({
    required this.currentStreak,
    required this.longestStreak,
    required this.source,
  });

  final int currentStreak;
  final int longestStreak;
  final String source;

  factory StreakInfo.fromJson(Map<String, dynamic> json) {
    return StreakInfo(
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      source: json['source']?.toString() ?? 'database',
    );
  }
}

class RankSummary {
  RankSummary({required this.globalData, required this.ramadanData});

  final dynamic globalData;
  final dynamic ramadanData;

  factory RankSummary.fromJson(Map<String, dynamic> json) {
    return RankSummary(
      globalData: json['global'],
      ramadanData: json['ramadan'],
    );
  }

  int? get globalRank => _rankFrom(globalData);
  int? get globalScore => _scoreFrom(globalData);
  int? get ramadanRank => _rankFrom(ramadanData);
  int? get ramadanScore => _scoreFrom(ramadanData);

  static int? _rankFrom(dynamic value) {
    if (value is Map) {
      final raw = value['rank'];
      if (raw is num) {
        return raw.toInt();
      }
      return int.tryParse(raw?.toString() ?? '');
    }
    return null;
  }

  static int? _scoreFrom(dynamic value) {
    if (value is Map) {
      final raw = value['score'];
      if (raw is num) {
        return raw.toInt();
      }
      return int.tryParse(raw?.toString() ?? '');
    }
    return null;
  }
}

class LeaderboardEntry {
  LeaderboardEntry({required this.userId, required this.stars});

  final int userId;
  final int stars;

  factory LeaderboardEntry.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return LeaderboardEntry(
        userId: (json['user_id'] as num?)?.toInt() ?? 0,
        stars:
            (json['stars'] as num?)?.toInt() ??
            (json['total'] as num?)?.toInt() ??
            0,
      );
    }
    final list = List<dynamic>.from(json as List<dynamic>);
    return LeaderboardEntry(
      userId: (list.isNotEmpty ? list[0] as num? : 0)?.toInt() ?? 0,
      stars: (list.length > 1 ? list[1] as num? : 0)?.toInt() ?? 0,
    );
  }
}

class FridayStats {
  FridayStats({required this.fridayStars, required this.activeUsers});

  final int fridayStars;
  final int activeUsers;

  factory FridayStats.fromJson(Map<String, dynamic> json) {
    return FridayStats(
      fridayStars: (json['friday_stars'] as num?)?.toInt() ?? 0,
      activeUsers: (json['active_users'] as num?)?.toInt() ?? 0,
    );
  }
}

class AccountSnapshot {
  AccountSnapshot({this.userId, this.username, this.email, this.avatarData});

  final int? userId;
  final String? username;
  final String? email;
  final String? avatarData;

  Uint8List? get avatarBytes {
    if (avatarData == null || avatarData!.isEmpty) {
      return null;
    }
    try {
      return base64Decode(avatarData!);
    } catch (_) {
      return null;
    }
  }

  factory AccountSnapshot.fromJson(Map<String, dynamic> json) {
    return AccountSnapshot(
      userId: (json['user_id'] as num?)?.toInt(),
      username: json['username']?.toString(),
      email: json['email']?.toString(),
      avatarData: json['avatar_data']?.toString(),
    );
  }
}

class CharityItem {
  CharityItem({
    required this.id,
    required this.name,
    required this.description,
    required this.websiteUrl,
    required this.category,
    required this.isFeatured,
    this.title,
    this.donationType = 'external',
    this.caseName,
    this.externalUrl,
    this.targetAmount,
    this.amountRaised,
    this.currency = 'NGN',
    this.imageUrls = const [],
    this.status = 'active',
    this.deadline,
  });

  final int id;
  final String name;
  final String? title;
  final String donationType;
  final String? caseName;
  final String? description;
  final String websiteUrl;
  final String? externalUrl;
  final String? category;
  final double? targetAmount;
  final double? amountRaised;
  final String currency;
  final List<String> imageUrls;
  final String status;
  final String? deadline;
  final bool isFeatured;

  factory CharityItem.fromJson(Map<String, dynamic> json) {
    return CharityItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      title: json['title']?.toString(),
      donationType: json['donation_type']?.toString() ?? 'external',
      caseName: json['case_name']?.toString(),
      description: json['description']?.toString(),
      websiteUrl: json['website_url']?.toString() ?? '',
      externalUrl: json['external_url']?.toString(),
      category: json['category']?.toString(),
      targetAmount: (json['target_amount'] as num?)?.toDouble(),
      amountRaised: (json['amount_raised'] as num?)?.toDouble(),
      currency: json['currency']?.toString() ?? 'NGN',
      imageUrls:
          (json['image_urls'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList(),
      status: json['status']?.toString() ?? 'active',
      deadline: json['deadline']?.toString(),
      isFeatured: json['is_featured'] as bool? ?? false,
    );
  }
}

class CharityDetail {
  CharityDetail({
    required this.id,
    required this.name,
    required this.websiteUrl,
    required this.isFeatured,
    required this.isVerified,
    required this.isActive,
    this.description,
    this.category,
    this.title,
    this.donationType = 'external',
    this.caseName,
    this.externalUrl,
    this.targetAmount,
    this.amountRaised,
    this.currency = 'NGN',
    this.imageUrls = const [],
    this.evidence,
    this.evidenceUrls = const [],
    this.contactInfo,
    this.status = 'active',
    this.deadline,
  });

  final int id;
  final String name;
  final String? title;
  final String donationType;
  final String? caseName;
  final String? description;
  final String websiteUrl;
  final String? externalUrl;
  final String? category;
  final double? targetAmount;
  final double? amountRaised;
  final String currency;
  final List<String> imageUrls;
  final String? evidence;
  final List<String> evidenceUrls;
  final String? contactInfo;
  final String status;
  final String? deadline;
  final bool isFeatured;
  final bool isVerified;
  final bool isActive;

  factory CharityDetail.fromJson(Map<String, dynamic> json) {
    return CharityDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      title: json['title']?.toString(),
      donationType: json['donation_type']?.toString() ?? 'external',
      caseName: json['case_name']?.toString(),
      description: json['description']?.toString(),
      websiteUrl: json['website_url']?.toString() ?? '',
      externalUrl: json['external_url']?.toString(),
      category: json['category']?.toString(),
      targetAmount: (json['target_amount'] as num?)?.toDouble(),
      amountRaised: (json['amount_raised'] as num?)?.toDouble(),
      currency: json['currency']?.toString() ?? 'NGN',
      imageUrls:
          (json['image_urls'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList(),
      evidence: json['evidence']?.toString(),
      evidenceUrls:
          (json['evidence_urls'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList(),
      contactInfo: json['contact_info']?.toString(),
      status: json['status']?.toString() ?? 'active',
      deadline: json['deadline']?.toString(),
      isFeatured: json['is_featured'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class CharityPage {
  CharityPage({
    required this.total,
    required this.limit,
    required this.offset,
    required this.data,
  });

  final int total;
  final int limit;
  final int offset;
  final List<CharityItem> data;

  factory CharityPage.fromJson(dynamic raw) {
    if (raw is List) {
      final rows =
          raw
              .whereType<Map>()
              .map(
                (item) => CharityItem.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList();
      return CharityPage(
        total: rows.length,
        limit: rows.length,
        offset: 0,
        data: rows,
      );
    }
    final json =
        raw is Map<String, dynamic>
            ? raw
            : raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};
    final rows =
        (json['data'] as List<dynamic>? ?? [])
            .map(
              (item) =>
                  CharityItem.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
    return CharityPage(
      total: (json['total'] as num?)?.toInt() ?? rows.length,
      limit: (json['limit'] as num?)?.toInt() ?? 50,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      data: rows,
    );
  }
}

class UserProfile {
  UserProfile({
    required this.userId,
    required this.username,
    required this.email,
    required this.emailVerified,
    required this.role,
    required this.evidenceMode,
    required this.fridayReminder,
    required this.generalNotifications,
    this.avatarData,
  });

  final int userId;
  final String username;
  final String email;
  final bool emailVerified;
  final String role;
  final String? avatarData;
  final bool evidenceMode;
  final bool fridayReminder;
  final bool generalNotifications;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      emailVerified: json['email_verified'] as bool? ?? false,
      role: json['role']?.toString() ?? 'USER',
      avatarData: json['avatar_data']?.toString(),
      evidenceMode: json['evidence_mode'] as bool? ?? false,
      fridayReminder: json['friday_reminder'] as bool? ?? false,
      generalNotifications: json['general_notifications'] as bool? ?? false,
    );
  }
}

class UserPreferences {
  UserPreferences({
    required this.theme,
    required this.language,
    required this.notificationPreferences,
    required this.reminderPreferences,
    required this.accessibilityPreferences,
    required this.privacyPreferences,
    this.timezone,
    required this.selectedMode,
  });

  final String theme;
  final String language;
  final Map<String, dynamic> notificationPreferences;
  final Map<String, dynamic> reminderPreferences;
  final Map<String, dynamic> accessibilityPreferences;
  final Map<String, dynamic> privacyPreferences;
  final String? timezone;
  final String selectedMode;

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme: json['theme']?.toString() ?? 'light',
      language: json['language']?.toString() ?? 'en',
      notificationPreferences: Map<String, dynamic>.from(
        json['notification_preferences'] as Map? ?? const {},
      ),
      reminderPreferences: Map<String, dynamic>.from(
        json['reminder_preferences'] as Map? ?? const {},
      ),
      accessibilityPreferences: Map<String, dynamic>.from(
        json['accessibility_preferences'] as Map? ?? const {},
      ),
      privacyPreferences: Map<String, dynamic>.from(
        json['privacy_preferences'] as Map? ?? const {},
      ),
      timezone: json['timezone']?.toString(),
      selectedMode: json['selected_mode']?.toString() ?? 'personal',
    );
  }
}

class DashboardStats {
  DashboardStats({
    required this.totalActsCompleted,
    required this.totalStarsEarned,
    required this.totalJarsCompleted,
    required this.currentStreak,
    required this.longestStreak,
    this.mostCommonCategory,
    required this.donationsMadeCount,
  });

  final int totalActsCompleted;
  final int totalStarsEarned;
  final int totalJarsCompleted;
  final int currentStreak;
  final int longestStreak;
  final String? mostCommonCategory;
  final int donationsMadeCount;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalActsCompleted: (json['total_acts_completed'] as num?)?.toInt() ?? 0,
      totalStarsEarned: (json['total_stars_earned'] as num?)?.toInt() ?? 0,
      totalJarsCompleted: (json['total_jars_completed'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      mostCommonCategory: json['most_common_category']?.toString(),
      donationsMadeCount: (json['donations_made_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class CategoryAnalyticsEntry {
  CategoryAnalyticsEntry({
    required this.category,
    required this.count,
    required this.stars,
  });

  final String category;
  final int count;
  final int stars;

  factory CategoryAnalyticsEntry.fromJson(Map<String, dynamic> json) {
    return CategoryAnalyticsEntry(
      category: json['category']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      stars: (json['stars'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminCharityRecord {
  AdminCharityRecord({
    required this.id,
    required this.name,
    required this.websiteUrl,
    required this.isVerified,
    required this.isActive,
    required this.isFeatured,
    required this.isPublished,
    this.title,
    this.donationType = 'external',
    this.caseName,
    this.description,
    this.externalUrl,
    this.category,
    this.targetAmount,
    this.amountRaised,
    this.currency = 'NGN',
    this.imageUrls = const [],
    this.evidence,
    this.evidenceUrls = const [],
    this.contactInfo,
    this.status = 'active',
    this.deadline,
  });

  final int id;
  final String name;
  final String? title;
  final String donationType;
  final String? caseName;
  final String? description;
  final String websiteUrl;
  final String? externalUrl;
  final String? category;
  final double? targetAmount;
  final double? amountRaised;
  final String currency;
  final List<String> imageUrls;
  final String? evidence;
  final List<String> evidenceUrls;
  final String? contactInfo;
  final String status;
  final String? deadline;
  final bool isVerified;
  final bool isActive;
  final bool isFeatured;
  final bool isPublished;

  factory AdminCharityRecord.fromJson(Map<String, dynamic> json) {
    return AdminCharityRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      title: json['title']?.toString(),
      donationType: json['donation_type']?.toString() ?? 'external',
      caseName: json['case_name']?.toString(),
      description: json['description']?.toString(),
      websiteUrl: json['website_url']?.toString() ?? '',
      externalUrl: json['external_url']?.toString(),
      category: json['category']?.toString(),
      targetAmount: (json['target_amount'] as num?)?.toDouble(),
      amountRaised: (json['amount_raised'] as num?)?.toDouble(),
      currency: json['currency']?.toString() ?? 'NGN',
      imageUrls:
          (json['image_urls'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList(),
      evidence: json['evidence']?.toString(),
      evidenceUrls:
          (json['evidence_urls'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList(),
      contactInfo: json['contact_info']?.toString(),
      status: json['status']?.toString() ?? 'active',
      deadline: json['deadline']?.toString(),
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      isPublished: json['is_published'] as bool? ?? true,
    );
  }
}

class AdminCharityPage {
  AdminCharityPage({
    required this.total,
    required this.limit,
    required this.offset,
    required this.data,
  });

  final int total;
  final int limit;
  final int offset;
  final List<AdminCharityRecord> data;

  factory AdminCharityPage.fromJson(Map<String, dynamic> json) {
    final rows =
        (json['data'] as List<dynamic>? ?? [])
            .map(
              (item) => AdminCharityRecord.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
    return AdminCharityPage(
      total: (json['total'] as num?)?.toInt() ?? rows.length,
      limit: (json['limit'] as num?)?.toInt() ?? rows.length,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      data: rows,
    );
  }
}

class AdminEvidenceRecord {
  AdminEvidenceRecord({
    required this.id,
    required this.actId,
    required this.sourceType,
    required this.reference,
    required this.isVerified,
    this.arabicText,
    this.englishText,
    this.grade,
  });

  final int id;
  final int actId;
  final String sourceType;
  final String reference;
  final String? arabicText;
  final String? englishText;
  final String? grade;
  final bool isVerified;

  factory AdminEvidenceRecord.fromJson(Map<String, dynamic> json) {
    return AdminEvidenceRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      actId: (json['act_id'] as num?)?.toInt() ?? 0,
      sourceType: json['source_type']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      arabicText: json['arabic_text']?.toString(),
      englishText: json['english_text']?.toString(),
      grade: json['grade']?.toString(),
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }
}

class AdminEvidenceDetail {
  AdminEvidenceDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.evidence,
  });

  final int id;
  final String name;
  final String description;
  final List<AdminEvidenceRecord> evidence;

  factory AdminEvidenceDetail.fromJson(Map<String, dynamic> json) {
    final rows =
        (json['evidence'] as List<dynamic>? ?? [])
            .map(
              (item) => AdminEvidenceRecord.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
    return AdminEvidenceDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      evidence: rows,
    );
  }
}

class AdminEvidencePage {
  AdminEvidencePage({
    required this.total,
    required this.limit,
    required this.offset,
    required this.data,
  });

  final int total;
  final int limit;
  final int offset;
  final List<AdminEvidenceRecord> data;

  factory AdminEvidencePage.fromJson(Map<String, dynamic> json) {
    final rows =
        (json['data'] as List<dynamic>? ?? [])
            .map(
              (item) => AdminEvidenceRecord.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
    return AdminEvidencePage(
      total: (json['total'] as num?)?.toInt() ?? rows.length,
      limit: (json['limit'] as num?)?.toInt() ?? rows.length,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      data: rows,
    );
  }
}

class AdminTopActEntry {
  AdminTopActEntry({required this.actId, required this.count});

  final int actId;
  final int count;

  factory AdminTopActEntry.fromJson(Map<String, dynamic> json) {
    return AdminTopActEntry(
      actId: (json['act_id'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminDonationIntentEntry {
  AdminDonationIntentEntry({required this.charityId, required this.count});

  final int charityId;
  final int count;

  factory AdminDonationIntentEntry.fromJson(Map<String, dynamic> json) {
    return AdminDonationIntentEntry(
      charityId: (json['charity_id'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminBookRecord {
  AdminBookRecord({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    this.coverUrl,
    this.fileUrl,
    this.fileFormat,
    this.fileType,
    required this.category,
    required this.language,
    required this.published,
    this.sortOrder,
    this.pageCount = 0,
  });

  final int id;
  final String title;
  final String author;
  final String? description;
  final String? coverUrl;
  final String? fileUrl;
  final String? fileFormat;
  final String? fileType;
  final String category;
  final String language;
  final bool published;
  final int? sortOrder;
  final int pageCount;

  factory AdminBookRecord.fromJson(Map<String, dynamic> json) {
    return AdminBookRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      description: json['description']?.toString(),
      coverUrl: json['cover_url']?.toString(),
      fileUrl: json['file_url']?.toString(),
      fileFormat: json['file_format']?.toString(),
      fileType: json['file_type']?.toString(),
      category: json['category']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
      published: json['published'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt(),
      pageCount: (json['page_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminBookPage {
  AdminBookPage({
    required this.total,
    required this.limit,
    required this.offset,
    required this.data,
  });

  final int total;
  final int limit;
  final int offset;
  final List<AdminBookRecord> data;

  factory AdminBookPage.fromJson(Map<String, dynamic> json) {
    final rows =
        (json['data'] as List<dynamic>? ?? [])
            .map(
              (item) => AdminBookRecord.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
    return AdminBookPage(
      total: (json['total'] as num?)?.toInt() ?? rows.length,
      limit: (json['limit'] as num?)?.toInt() ?? rows.length,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      data: rows,
    );
  }
}

class BookRead {
  BookRead({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.coverUrl,
    this.fileUrl,
    this.fileFormat,
    this.fileType,
    required this.category,
    required this.language,
    required this.published,
    this.chapterCount,
    this.totalReadingTime,
    this.pageCount = 0,
  });

  final int id;
  final String title;
  final String author;
  final String? description;
  final String? coverUrl;
  final String? fileUrl;
  final String? fileFormat;
  final String? fileType;
  final String category;
  final String language;
  final bool published;
  final int? chapterCount;
  final int? totalReadingTime;
  final int pageCount;

  factory BookRead.fromJson(Map<String, dynamic> json) {
    return BookRead(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      description: json['description']?.toString(),
      coverUrl: json['cover_url']?.toString(),
      fileUrl: json['file_url']?.toString(),
      fileFormat: json['file_format']?.toString(),
      fileType: json['file_type']?.toString(),
      category: json['category']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
      published: json['published'] as bool? ?? true,
      chapterCount: (json['chapter_count'] as num?)?.toInt(),
      totalReadingTime: (json['total_reading_time'] as num?)?.toInt(),
      pageCount: (json['page_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class BookDetail {
  BookDetail({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    this.coverUrl,
    this.fileUrl,
    this.fileFormat,
    this.fileType,
    required this.category,
    required this.language,
    required this.published,
    this.chapterCount,
    this.totalReadingTime,
    this.pageCount = 0,
    this.chapters = const [],
    this.pages = const [],
  });

  final int id;
  final String title;
  final String author;
  final String? description;
  final String? coverUrl;
  final String? fileUrl;
  final String? fileFormat;
  final String? fileType;
  final String category;
  final String language;
  final bool published;
  final int? chapterCount;
  final int? totalReadingTime;
  final int pageCount;
  final List<BookChapterRead> chapters;
  final List<BookPageRead> pages;

  factory BookDetail.fromJson(Map<String, dynamic> json) {
    return BookDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      description: json['description']?.toString(),
      coverUrl: json['cover_url']?.toString(),
      fileUrl: json['file_url']?.toString(),
      fileFormat: json['file_format']?.toString(),
      fileType: json['file_type']?.toString(),
      category: json['category']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
      published: json['published'] as bool? ?? true,
      chapterCount: (json['chapter_count'] as num?)?.toInt(),
      totalReadingTime: (json['total_reading_time'] as num?)?.toInt(),
      pageCount: (json['page_count'] as num?)?.toInt() ?? 0,
      chapters:
          (json['chapters'] as List<dynamic>? ?? const [])
              .map(
                (item) => BookChapterRead.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
      pages:
          (json['pages'] as List<dynamic>? ?? const [])
              .map(
                (item) => BookPageRead.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
    );
  }
}

class BookPageRead {
  BookPageRead({
    required this.id,
    required this.bookId,
    required this.pageNumber,
    required this.imageUrl,
    this.imageType,
  });

  final int id;
  final int bookId;
  final int pageNumber;
  final String imageUrl;
  final String? imageType;

  factory BookPageRead.fromJson(Map<String, dynamic> json) {
    return BookPageRead(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bookId: (json['book_id'] as num?)?.toInt() ?? 0,
      pageNumber: (json['page_number'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url']?.toString() ?? '',
      imageType: json['image_type']?.toString(),
    );
  }
}

class BookChapterRead {
  BookChapterRead({
    required this.id,
    required this.bookId,
    required this.chapterNumber,
    required this.title,
    this.content,
  });

  final int id;
  final int bookId;
  final int chapterNumber;
  final String title;
  final String? content;

  factory BookChapterRead.fromJson(Map<String, dynamic> json) {
    return BookChapterRead(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bookId: (json['book_id'] as num?)?.toInt() ?? 0,
      chapterNumber: (json['chapter_number'] as num?)?.toInt() ?? 1,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString(),
    );
  }
}

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.action,
    this.data,
  });

  final int id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final String createdAt;
  final String? action;
  final Map<String, dynamic>? data;

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
    id: id,
    type: type,
    title: title,
    body: body,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
    action: action,
    data: data,
  );

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: (json['type'] ?? json['category'] ?? '').toString(),
      title: json['title']?.toString() ?? '',
      body: (json['body'] ?? json['message'] ?? '').toString(),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at']?.toString() ?? '',
      action: json['action']?.toString(),
      data:
          json['data'] is Map
              ? Map<String, dynamic>.from(json['data'] as Map)
              : null,
    );
  }
}

class NotificationPage {
  NotificationPage({
    required this.total,
    required this.limit,
    required this.offset,
    required this.data,
  });

  final int total;
  final int limit;
  final int offset;
  final List<NotificationItem> data;

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    final rows =
        (json['data'] as List<dynamic>? ?? [])
            .map(
              (item) => NotificationItem.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
    return NotificationPage(
      total: (json['total'] as num?)?.toInt() ?? rows.length,
      limit: (json['limit'] as num?)?.toInt() ?? rows.length,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      data: rows,
    );
  }
}

class JourneyReflection {
  JourneyReflection({
    required this.id,
    required this.title,
    required this.body,
    required this.mood,
    required this.isPrivate,
    required this.createdAt,
    this.date,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String body;
  final String mood;
  final bool isPrivate;
  final String createdAt;
  final String? date;
  final String? updatedAt;

  factory JourneyReflection.fromJson(Map<String, dynamic> json) {
    return JourneyReflection(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      mood: json['mood']?.toString() ?? '',
      isPrivate: json['is_private'] as bool? ?? false,
      createdAt: json['created_at']?.toString() ?? '',
      date: json['date']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

class JourneyReflectionPage {
  JourneyReflectionPage({required this.items, required this.total});

  final List<JourneyReflection> items;
  final int total;
}

class JourneyAdhkarProgress {
  JourneyAdhkarProgress({
    required this.id,
    required this.adhkarId,
    required this.count,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int adhkarId;
  final int count;
  final String createdAt;
  final String updatedAt;

  factory JourneyAdhkarProgress.fromJson(Map<String, dynamic> json) {
    return JourneyAdhkarProgress(
      id: (json['id'] as num?)?.toInt() ?? 0,
      adhkarId: (json['adhkar_id'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

class JourneyAdhkarFavorite {
  JourneyAdhkarFavorite({
    required this.id,
    required this.adhkarId,
    required this.createdAt,
  });

  final int id;
  final int adhkarId;
  final String createdAt;

  factory JourneyAdhkarFavorite.fromJson(Map<String, dynamic> json) {
    return JourneyAdhkarFavorite(
      id: (json['id'] as num?)?.toInt() ?? 0,
      adhkarId: (json['adhkar_id'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
