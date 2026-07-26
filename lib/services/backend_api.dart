import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum SessionBootstrapState { none, restored, expired }

class BackendApi {
  BackendApi._();

  static final BackendApi instance = BackendApi._();

  static const String _defaultBaseUrl = 'https://api.sad-aqah.app/api/v1';
  static const String _accessTokenKey = 'sadaqah_jar_access_token';
  static const String _refreshTokenKey = 'sadaqah_jar_refresh_token';
  static const String _accountKey = 'sadaqah_jar_account_snapshot';
  static const String _familyJarIdKey = 'sadaqah_jar_family_jar_id';
  static const Duration _requestTimeout = Duration(seconds: 60);

  final String baseUrl = _resolveBaseUrl();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Completer<bool>? _refreshCompleter;
  Future<void> Function()? onSessionExpired;

  static String _resolveBaseUrl() {
    final configured = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: _defaultBaseUrl,
    ).trim();
    final normalized = configured.endsWith('/') && configured.length > 1
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

  Future<void> saveSessionTokens({required String accessToken, required String refreshToken}) async {
    await Future.wait([
      saveToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  Future<void> saveAccountSnapshot({int? userId, String? username, String? email, String? avatarData}) async {
    final prefs = await _prefs;
    final snapshot = <String, dynamic>{
      if (userId != null) 'user_id': userId,
      if (username != null && username.isNotEmpty) 'username': username,
      if (email != null && email.isNotEmpty) 'email': email,
      if (avatarData != null && avatarData.isNotEmpty) 'avatar_data': avatarData,
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
    } catch (_) {
      // fall back to cached local snapshot below
    }

    final prefs = await _prefs;
    final raw = prefs.getString(_accountKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return AccountSnapshot.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
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
      return (await _refreshSession()) ? SessionBootstrapState.restored : SessionBootstrapState.expired;
    }

    final accessToken = await getToken();
    return accessToken != null && accessToken.isNotEmpty ? SessionBootstrapState.restored : SessionBootstrapState.none;
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
      (headers) => http.get(_uri(path, query), headers: headers).timeout(_requestTimeout),
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
      (headers) => http.post(_uri(path, query), headers: headers, body: body).timeout(_requestTimeout),
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
      (headers) => http.patch(_uri(path, query), headers: headers, body: body).timeout(_requestTimeout),
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
      (headers) => http.delete(_uri(path, query), headers: headers).timeout(_requestTimeout),
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
      if (accessToken == null || accessToken.isEmpty || nextRefreshToken == null || nextRefreshToken.isEmpty) {
        await _expireSession();
        completer.complete(false);
        return false;
      }

      await saveSessionTokens(accessToken: accessToken, refreshToken: nextRefreshToken);
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

  T _unwrapEnvelope<T>(Map<String, dynamic> decoded, T Function(dynamic) parser) {
    final data = decoded['data'];
    if (data == null) {
      throw BackendApiException('Empty response data', 500);
    }
    return parser(data);
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
  }) async {
    final response = await _post(
      '/auth/register',
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final accessToken = decoded['access_token']?.toString();
    final refreshToken = decoded['refresh_token']?.toString();
    if (accessToken != null && accessToken.isNotEmpty && refreshToken != null && refreshToken.isNotEmpty) {
      await saveSessionTokens(accessToken: accessToken, refreshToken: refreshToken);
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
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final accessToken = decoded['access_token']?.toString();
    final refreshToken = decoded['refresh_token']?.toString();
    if (accessToken != null && accessToken.isNotEmpty && refreshToken != null && refreshToken.isNotEmpty) {
      await saveSessionTokens(accessToken: accessToken, refreshToken: refreshToken);
    }
    await saveAccountSnapshot(username: email.contains('@') ? email.split('@').first : email, email: email);
    return decoded;
  }

  Future<Map<String, dynamic>> googleAuth({required String idToken}) async {
    final response = await _post(
      '/auth/google',
      body: jsonEncode({
        'id_token': idToken,
      }),
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final accessToken = decoded['access_token']?.toString();
    final refreshToken = decoded['refresh_token']?.toString();
    if (accessToken != null && accessToken.isNotEmpty && refreshToken != null && refreshToken.isNotEmpty) {
      await saveSessionTokens(accessToken: accessToken, refreshToken: refreshToken);
    }
    await saveAccountSnapshot(
      userId: (decoded['user_id'] as num?)?.toInt(),
      username: decoded['username']?.toString() ?? '',
      email: decoded['email']?.toString() ?? '',
    );
    return decoded;
  }

  Future<void> resendVerificationEmail() async {
    await _post('/auth/resend-verification', auth: true);
  }

  Future<AccountSnapshot> updateAccount({String? username, String? email, String? avatarData}) async {
    final response = await _patch(
      '/auth/me',
      auth: true,
      body: jsonEncode({
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (avatarData != null) 'avatar_data': avatarData,
      }),
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final snapshot = AccountSnapshot.fromJson(decoded);
    await saveAccountSnapshot(
      userId: snapshot.userId,
      username: snapshot.username,
      email: snapshot.email,
      avatarData: snapshot.avatarData,
    );
    return snapshot;
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _get('/auth/me', auth: true);
    return _handleJson(response);
  }

  Future<UserProfile> getUserProfile() async {
    final response = await me();
    return UserProfile.fromJson(response);
  }

  Future<UserPreferences> updatePreferences({bool? evidenceMode, bool? fridayReminder}) async {
    final response = await _patch(
      '/auth/preferences',
      auth: true,
      body: jsonEncode({
        if (evidenceMode != null) 'evidence_mode': evidenceMode,
        if (fridayReminder != null) 'friday_reminder': fridayReminder,
      }),
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    return UserPreferences.fromJson(decoded);
  }

  Future<void> registerPushToken({
    required String deviceId,
    required String platform,
    required String pushToken,
  }) async {
    await _post(
      '/users/me/push-token',
      auth: true,
      body: jsonEncode({
        'device_id': deviceId,
        'platform': platform,
        'push_token': pushToken,
      }),
    );
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

  Future<void> resetPassword({required String token, required String newPassword}) async {
    await _post(
      '/auth/reset-password',
      body: jsonEncode({'token': token, 'new_password': newPassword}),
      retryOnUnauthorized: false,
    );
  }

  Future<void> verifyEmail({required String token}) async {
    await _get(
      '/auth/verify-email',
      query: {'token': token},
      retryOnUnauthorized: false,
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
    final decoded = _handleJson(response) as List<dynamic>;
    return decoded.map((item) => DailyAct.fromJson(Map<String, dynamic>.from(item as Map))).toList();
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
    return SadaqahActDetail.fromJson(_handleJson(response));
  }

  Future<JarStats> getJar() async {
    final response = await _get('/sadaqah/jar', auth: true);
    return JarStats.fromJson(_handleJson(response));
  }

  Future<JarStats> addJarStar({int? actId, String? type, String? note, String? requestId}) async {
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
    return JarStats.fromJson(_handleJson(response));
  }

  Future<CompletedJarPage> getCompletedJars({int limit = 20, int offset = 0}) async {
    final response = await _get(
      '/sadaqah/jars/completed',
      auth: true,
      query: {'limit': limit, 'offset': offset},
    );
    return CompletedJarPage.fromJson(_handleJson(response));
  }

  Future<Map<String, int>> getHeatmap() async {
    final response = await _get('/dashboard/heatmap', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, int.tryParse('$value') ?? 0));
  }

  Future<StreakInfo> getStreak() async {
    final response = await _get('/streak/streak', auth: true);
    return StreakInfo.fromJson(_handleJson(response));
  }

  Future<RankSummary> getMyRank() async {
    final response = await _get('/leaderboard/me', auth: true);
    return RankSummary.fromJson(_handleJson(response));
  }

  Future<List<LeaderboardEntry>> getFridayLeaderboard({int limit = 10}) async {
    final response = await _get('/leaderboard/friday', auth: true, query: {'limit': limit});
    return _leaderboardFromResponse(response);
  }

  Future<List<LeaderboardEntry>> getRamadanLeaderboard() async {
    final response = await _get('/leaderboard/ramadan', auth: true);
    return _leaderboardFromResponse(response);
  }

  Future<List<LeaderboardEntry>> getGlobalLeaderboard({int limit = 10}) async {
    final response = await _get('/leaderboard/global', auth: true, query: {'limit': limit});
    return _leaderboardFromResponse(response);
  }

  Future<FridayStats> getFridayStats() async {
    final response = await _get('/friday/stats', auth: true);
    return FridayStats.fromJson(_handleJson(response));
  }

  Future<int> getAdminDailyUsers() async {
    final response = await _get('/admin/analytics/daily-users', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    return (decoded['new_users_today'] as num?)?.toInt() ?? 0;
  }

  Future<List<AdminTopActEntry>> getAdminTopActs() async {
    final response = await _get('/admin/analytics/top-acts', auth: true);
    final decoded = _handleJson(response) as List<dynamic>;
    return decoded
        .map((item) => AdminTopActEntry.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<int> getAdminStarsToday() async {
    final response = await _get('/admin/analytics/stars-today', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    return (decoded['stars_today'] as num?)?.toInt() ?? 0;
  }

  Future<List<AdminDonationIntentEntry>> getAdminDonationIntents() async {
    final response = await _get('/admin/analytics/donation-intents', auth: true);
    final decoded = _handleJson(response) as List<dynamic>;
    return decoded
        .map((item) => AdminDonationIntentEntry.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<DashboardStats> getDashboardStats() async {
    final response = await _get('/dashboard/stats', auth: true);
    return DashboardStats.fromJson(_handleJson(response));
  }

  Future<List<CategoryAnalyticsEntry>> getCategoryAnalytics() async {
    final response = await _get('/dashboard/category-analytics', auth: true);
    final decoded = _handleJson(response) as List<dynamic>;
    return decoded
        .map((item) => CategoryAnalyticsEntry.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<int> getUnreadNotificationCount() async {
    final response = await _get('/notifications/unread-count', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    final map = Map<String, dynamic>.from(data as Map);
    return (map['count'] as num?)?.toInt() ?? 0;
  }

  Future<NotificationPage> getNotifications({bool unread = false, int limit = 20, int offset = 0}) async {
    final response = await _get(
      '/notifications/',
      auth: true,
      query: {
        if (unread) 'unread': true,
        'limit': limit,
        'offset': offset,
      },
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    return _unwrapEnvelope(decoded, (data) {
      final meta = _getEnvelopeMeta(decoded);
      return NotificationPage(
        total: (meta?['total'] as num?)?.toInt() ?? 0,
        limit: limit,
        offset: offset,
        data: (data as List).map((i) => NotificationItem.fromJson(Map<String, dynamic>.from(i as Map))).toList(),
      );
    });
  }

  Future<void> markNotificationRead(int notificationId) async {
    final response = await _post('/notifications/read/$notificationId', auth: true, retryOnUnauthorized: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final message = _getEnvelopeMessage(decoded);
    if (message != null) {
      throw BackendApiException(message, response.statusCode);
    }
  }

  Future<void> markAllNotificationsRead() async {
    final response = await _post('/notifications/read-all', auth: true, retryOnUnauthorized: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final message = _getEnvelopeMessage(decoded);
    if (message != null) {
      throw BackendApiException(message, response.statusCode);
    }
  }

  Future<void> registerDeviceToken({required String token, required String platform}) async {
    await _post(
      '/notifications/device-token',
      auth: true,
      body: jsonEncode({'token': token, 'platform': platform}),
    );
  }

  Future<List<CharityItem>> getFeaturedCharities() async {
    final response = await _get('/charities/featured', auth: true);
    final decoded = _handleJson(response) as List<dynamic>;
    return decoded.map((item) => CharityItem.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<AdminCharityPage> getAdminCharities({int limit = 50, int offset = 0}) async {
    final response = await _get('/admin/charities/', auth: true, query: {'limit': limit, 'offset': offset});
    return AdminCharityPage.fromJson(_handleJson(response));
  }

  Future<AdminCharityRecord> createAdminCharity({
    required String name,
    required String websiteUrl,
    String? description,
    String? category,
  }) async {
    final response = await _post(
      '/admin/charities/',
      auth: true,
      body: jsonEncode({
        'name': name,
        'website_url': websiteUrl,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
      }),
    );
    return AdminCharityRecord.fromJson(_handleJson(response));
  }

  Future<AdminCharityRecord> updateAdminCharity({
    required int charityId,
    String? name,
    String? websiteUrl,
    String? description,
    String? category,
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
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (isVerified != null) 'is_verified': isVerified,
        if (isActive != null) 'is_active': isActive,
        if (isFeatured != null) 'is_featured': isFeatured,
      }),
    );
    return AdminCharityRecord.fromJson(_handleJson(response));
  }

  Future<void> deleteAdminCharity(int charityId) async {
    await _delete('/admin/charities/$charityId', auth: true);
  }

  Future<CharityDetail> getCharity(int charityId) async {
    final response = await _get('/charities/$charityId', auth: true);
    return CharityDetail.fromJson(_handleJson(response));
  }

  Future<CharityPage> getCharities({String? category, int limit = 50, int offset = 0}) async {
    final response = await _get(
      '/charities/',
      query: {
        if (category != null && category.isNotEmpty) 'category': category,
        'limit': limit,
        'offset': offset,
      },
      auth: true,
    );
    return CharityPage.fromJson(_handleJson(response));
  }

  Future<AdminEvidencePage> getAdminEvidence({int limit = 50, int offset = 0}) async {
    final response = await _get('/admin/evidence/', auth: true, query: {'limit': limit, 'offset': offset});
    return AdminEvidencePage.fromJson(_handleJson(response));
  }

  Future<AdminEvidenceDetail> getAdminEvidenceForAct(int actId) async {
    final response = await _get('/admin/evidence/$actId', auth: true);
    return AdminEvidenceDetail.fromJson(_handleJson(response));
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
    return AdminEvidenceRecord.fromJson(_handleJson(response));
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
    return AdminEvidenceRecord.fromJson(_handleJson(response));
  }

  Future<void> deleteAdminEvidence(int evidenceId) async {
    await _delete('/admin/evidence/$evidenceId', auth: true);
  }

  Future<Map<String, dynamic>> createFamilyJar({required String name, int capacity = 33}) async {
    final response = await _post('/family/create', auth: true, query: {'name': name, 'capacity': capacity});
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    final map = Map<String, dynamic>.from(data as Map);
    await saveLastFamilyJarId((map['id'] as num?)?.toInt());
    return map;
  }

  Future<Map<String, dynamic>> joinFamilyJar({required String inviteCode}) async {
    final response = await _post('/family/join', auth: true, query: {'invite_code': inviteCode});
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    final map = Map<String, dynamic>.from(data as Map);
    await saveLastFamilyJarId((map['id'] as num?)?.toInt());
    return map;
  }

  Future<List<LeaderboardEntry>> getFamilyLeaderboard({required int jarId, int limit = 10}) async {
    final response = await _get('/family/$jarId/leaderboard', auth: true, query: {'limit': limit});
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    return (data as List).map((i) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(i as Map))).toList();
  }

  Future<Map<String, dynamic>> getFamilyTopContributor({required int jarId}) async {
    final response = await _get('/family/$jarId/top-contributor', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> getFamilyJarDetail({required int jarId}) async {
    final response = await _get('/family/$jarId', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<Map<String, dynamic>>> getFridayRecommendations() async {
    final response = await _get('/friday/recommendations', auth: true);
    final decoded = _handleJson(response) as List<dynamic>;
    return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getMorningAdhkar() async {
    final response = await _get('/adhkar/morning', auth: true);
    final decoded = _handleJson(response) as List<dynamic>;
    return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getEveningAdhkar() async {
    final response = await _get('/adhkar/evening', auth: true);
    final decoded = _handleJson(response) as List<dynamic>;
    return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<JourneyReflectionPage> getReflections({int limit = 20, int offset = 0}) async {
    final response = await _get(
      '/journey/reflections',
      auth: true,
      query: {'limit': limit, 'offset': offset},
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    return _unwrapEnvelope(decoded, (data) {
      final meta = _getEnvelopeMeta(decoded);
      return JourneyReflectionPage(
        items: (data as List).map((i) => JourneyReflection.fromJson(Map<String, dynamic>.from(i as Map))).toList(),
        total: (meta?['total'] as num?)?.toInt() ?? 0,
      );
    });
  }

  Future<JourneyReflection> createReflection({required String title, required String body, required String mood, bool isPrivate = false, DateTime? date}) async {
    final response = await _post(
      '/journey/reflections',
      auth: true,
      body: jsonEncode({
        'title': title,
        'body': body,
        'mood': mood,
        'is_private': isPrivate,
        if (date != null) 'date': date.toIso8601String(),
      }),
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    return _unwrapEnvelope(decoded, (data) => JourneyReflection.fromJson(Map<String, dynamic>.from(data as Map)));
  }

  Future<JourneyAdhkarProgress> setAdhkarProgress(int adhkarId, int count) async {
    final response = await _post(
      '/journey/adhkar/$adhkarId/progress',
      auth: true,
      body: jsonEncode({'count': count}),
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    return _unwrapEnvelope(decoded, (data) => JourneyAdhkarProgress.fromJson(Map<String, dynamic>.from(data as Map)));
  }

  Future<List<JourneyAdhkarProgress>> getAdhkarProgress() async {
    final response = await _get('/journey/adhkar/progress', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    return (data as List).map((i) => JourneyAdhkarProgress.fromJson(Map<String, dynamic>.from(i as Map))).toList();
  }

  Future<JourneyAdhkarProgress> getAdhkarProgressFor(int adhkarId) async {
    final response = await _get('/journey/adhkar/$adhkarId/progress', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    return _unwrapEnvelope(decoded, (data) => JourneyAdhkarProgress.fromJson(Map<String, dynamic>.from(data as Map)));
  }

  Future<JourneyAdhkarFavorite> favoriteAdhkar(int adhkarId) async {
    final response = await _post('/journey/adhkar/$adhkarId/favorite', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    return _unwrapEnvelope(decoded, (data) => JourneyAdhkarFavorite.fromJson(Map<String, dynamic>.from(data as Map)));
  }

  Future<void> unfavoriteAdhkar(int adhkarId) async {
    final response = await _delete('/journey/adhkar/$adhkarId/favorite', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final message = _getEnvelopeMessage(decoded);
    if (message != null) {
      throw BackendApiException(message, response.statusCode);
    }
  }

  Future<List<JourneyAdhkarFavorite>> getAdhkarFavorites() async {
    final response = await _get('/journey/adhkar/favorites', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    return (data as List).map((i) => JourneyAdhkarFavorite.fromJson(Map<String, dynamic>.from(i as Map))).toList();
  }

  Future<List<Map<String, dynamic>>> getTodaysGentleActs({int limit = 3}) async {
    final response = await _get('/sadaqah/acts', auth: true, query: {'limit': limit, 'verified_only': 'true'});
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    final list = data as List;
    return list.map((i) => Map<String, dynamic>.from(i as Map)).toList();
  }

  Future<Map<String, dynamic>?> getLastReadingProgress() async {
    try {
      final response = await _get('/journey/reading/last', auth: true);
      final decoded = _handleJson(response) as Map<String, dynamic>;
      final data = _unwrapEnvelope(decoded, (data) => data);
      if (data == null) return null;
      return Map<String, dynamic>.from(data as Map);
    } on BackendApiException catch (_) {
      return null;
    }
  }

  Future<void> saveReadingProgress({required int bookId, required int chapterNumber}) async {
    await _post('/journey/reading/progress', auth: true, body: jsonEncode({'book_id': bookId, 'chapter_number': chapterNumber}));
  }

  Future<List<Map<String, dynamic>>> getTodaysReflections() async {
    final response = await _get('/journey/reflections', auth: true, query: {'limit': 5});
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    final list = data as List? ?? const [];
    return list.map((i) => Map<String, dynamic>.from(i as Map)).toList();
  }

  Future<void> leaveFamilyJar({required int jarId}) async {
    final response = await _post('/family/$jarId/leave', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final message = _getEnvelopeMessage(decoded);
    if (message != null) {
      throw BackendApiException(message, response.statusCode);
    }
  }

  Future<void> removeFamilyMember({required int jarId, required int targetUserId}) async {
    final response = await _delete('/family/$jarId/members/$targetUserId', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final message = _getEnvelopeMessage(decoded);
    if (message != null) {
      throw BackendApiException(message, response.statusCode);
    }
  }

  Future<List<Map<String, dynamic>>> getFamilyGoals(int familyId) async {
    final response = await _get('/family/$familyId/goals', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    return (data as List).map((i) => Map<String, dynamic>.from(i as Map)).toList();
  }

  Future<Map<String, dynamic>> createFamilyGoal(int familyId, {required String title, String? subtitle, required int actsTarget}) async {
    final response = await _post(
      '/family/$familyId/goals',
      auth: true,
      body: jsonEncode({
        'title': title,
        if (subtitle != null && subtitle.isNotEmpty) 'subtitle': subtitle,
        'acts_target': actsTarget,
      }),
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    return _unwrapEnvelope(decoded, (data) => Map<String, dynamic>.from(data as Map));
  }

  Future<List<Map<String, dynamic>>> getFamilyReflections(int familyId, {int limit = 50, int offset = 0}) async {
    final response = await _get(
      '/family/$familyId/reflections',
      auth: true,
      query: {'limit': limit, 'offset': offset},
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    return (data as List).map((i) => Map<String, dynamic>.from(i as Map)).toList();
  }

  Future<Map<String, dynamic>> createFamilyReflection(int familyId, {required String text}) async {
    final response = await _post(
      '/family/$familyId/reflections',
      auth: true,
      body: jsonEncode({'text': text}),
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    return _unwrapEnvelope(decoded, (data) => Map<String, dynamic>.from(data as Map));
  }

  Future<Map<String, dynamic>> encourageFamilyReflection(int familyId, int reflectionId, String encouragementType) async {
    final response = await _post(
      '/family/$familyId/reflections/$reflectionId/encourage',
      auth: true,
      body: jsonEncode({'encouragement_type': encouragementType}),
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<Map<String, dynamic>>> getFamilyPrayers(int familyId, {int limit = 50, int offset = 0}) async {
    final response = await _get(
      '/family/$familyId/prayers',
      auth: true,
      query: {'limit': limit, 'offset': offset},
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    return (data as List).map((i) => Map<String, dynamic>.from(i as Map)).toList();
  }

  Future<Map<String, dynamic>> createFamilyPrayer(int familyId, {required String text, bool isPrivate = false}) async {
    final response = await _post(
      '/family/$familyId/prayers',
      auth: true,
      body: jsonEncode({'text': text, 'is_private': isPrivate}),
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    return _unwrapEnvelope(decoded, (data) => Map<String, dynamic>.from(data as Map));
  }

  Future<Map<String, dynamic>> respondToFamilyPrayer(int familyId, int prayerId, String responseType) async {
    final response = await _post(
      '/family/$familyId/prayers/$prayerId/respond',
      auth: true,
      body: jsonEncode({'response_type': responseType}),
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> getFamilySettings(int familyId) async {
    final response = await _get('/family/$familyId/settings', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> updateFamilySettings(int familyId, {Map<String, bool>? notificationPreferences}) async {
    final response = await _patch(
      '/family/$familyId/settings',
      auth: true,
      body: jsonEncode({
        if (notificationPreferences != null) 'notification_preferences': notificationPreferences,
      }),
    );
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> archiveFamilyJar(int familyId) async {
    final response = await _post('/family/$familyId/archive', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final message = _getEnvelopeMessage(decoded);
    if (message != null) {
      throw BackendApiException(message, response.statusCode);
    }
  }

  Future<void> deleteFamilyJar(int familyId) async {
    await _delete('/family/$familyId', auth: true);
  }

  Future<List<Map<String, dynamic>>> getFamilies({int limit = 50, int offset = 0}) async {
    final response = await _get('/family/', auth: true, query: {'limit': limit, 'offset': offset});
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    return (data as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> getFamilyDetail(int familyId) async {
    final response = await _get('/family/$familyId', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<BookRead>> getBooks({int limit = 50, int offset = 0}) async {
    final response = await _get('/books/', auth: true, query: {'limit': limit, 'offset': offset});
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data) as List;
    return data.map((item) => BookRead.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<BookDetail> getBook(int bookId) async {
    final response = await _get('/books/$bookId', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    return BookDetail.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<BookChapterRead>> getBookChapters(int bookId) async {
    final response = await _get('/books/$bookId/chapters', auth: true);
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final data = _unwrapEnvelope(decoded, (data) => data);
    return (data as List).map((item) => BookChapterRead.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<AdminBookPage> getAdminBooks({int limit = 50, int offset = 0}) async {
    final response = await _get('/admin/books/', auth: true, query: {'limit': limit, 'offset': offset});
    final decoded = _handleJson(response) as Map<String, dynamic>;
    final meta = _getEnvelopeMeta(decoded);
    final rows = (decoded['data'] as List? ?? [])
        .map((item) => AdminBookRecord.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    return AdminBookPage(
      total: (meta?['total'] as num?)?.toInt() ?? rows.length,
      limit: limit,
      offset: offset,
      data: rows,
    );
  }

  Future<AdminBookRecord> createAdminBook({required String title, required String author, String? description, String? coverUrl, required String category, String language = 'en', bool published = true, int sortOrder = 0}) async {
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
    final decoded = _handleJson(response) as Map<String, dynamic>;
    return AdminBookRecord.fromJson(decoded);
  }

  Future<AdminBookRecord> updateAdminBook(int bookId, {String? title, String? author, String? description, String? coverUrl, String? category, String? language, bool? published, int? sortOrder}) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (author != null) body['author'] = author;
    if (description != null) body['description'] = description;
    if (coverUrl != null) body['cover_url'] = coverUrl;
    if (category != null) body['category'] = category;
    if (language != null) body['language'] = language;
    if (published != null) body['published'] = published;
    if (sortOrder != null) body['sort_order'] = sortOrder;
    final response = await _patch('/admin/books/$bookId', auth: true, body: jsonEncode(body));
    final decoded = _handleJson(response) as Map<String, dynamic>;
    return AdminBookRecord.fromJson(decoded);
  }

  Future<void> deleteAdminBook(int bookId) async {
    await _delete('/admin/books/$bookId', auth: true);
  }

  List<LeaderboardEntry> _leaderboardFromResponse(http.Response response) {
    final decoded = _handleJson(response) as List<dynamic>;
    return decoded.map((item) => LeaderboardEntry.fromJson(item)).toList();
  }

  dynamic _handleJson(http.Response response) {
    final body = response.body.isEmpty ? '{}' : response.body;
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      decoded = <String, dynamic>{'detail': 'Invalid JSON response from server'};
    }
    if (response.statusCode >= 400) {
      String message = 'Request failed (${response.statusCode})';
      String? code;
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is Map) {
          message = detail['message']?.toString() ?? detail['detail']?.toString() ?? message;
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
  String toString() => code == null ? 'BackendApiException($statusCode): $message' : 'BackendApiException($statusCode, $code): $message';
}

class DailyAct {
  DailyAct({required this.id, required this.title, required this.category, required this.difficulty});

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
  SadaqahActPage({required this.total, required this.limit, required this.offset, required this.data});

  final int total;
  final int limit;
  final int offset;
  final List<SadaqahActItem> data;

  factory SadaqahActPage.fromJson(Map<String, dynamic> json) {
    final rows = (json['data'] as List<dynamic>? ?? [])
        .map((item) => SadaqahActItem.fromJson(Map<String, dynamic>.from(item as Map)))
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
  SadaqahActItem({required this.id, required this.title, required this.category, required this.difficulty});

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
      evidence: json['evidence'] == null ? null : SadaqahEvidence.fromJson(Map<String, dynamic>.from(json['evidence'] as Map)),
    );
  }
}

class CompletedJarPage {
  CompletedJarPage({required this.total, required this.limit, required this.offset, required this.data});

  final int total;
  final int limit;
  final int offset;
  final List<CompletedJarItem> data;

  factory CompletedJarPage.fromJson(Map<String, dynamic> json) {
    final rows = (json['data'] as List<dynamic>? ?? [])
        .map((item) => CompletedJarItem.fromJson(Map<String, dynamic>.from(item as Map)))
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
  JarStats({required this.currentStars, required this.capacity, this.completedAt});

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
  StreakInfo({required this.currentStreak, required this.longestStreak, required this.source});

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
    return RankSummary(globalData: json['global'], ramadanData: json['ramadan']);
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
        stars: (json['stars'] as num?)?.toInt() ?? (json['total'] as num?)?.toInt() ?? 0,
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
  CharityItem({required this.id, required this.name, required this.description, required this.websiteUrl, required this.category, required this.isFeatured});

  final int id;
  final String name;
  final String? description;
  final String websiteUrl;
  final String? category;
  final bool isFeatured;

  factory CharityItem.fromJson(Map<String, dynamic> json) {
    return CharityItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      websiteUrl: json['website_url']?.toString() ?? '',
      category: json['category']?.toString(),
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
  });

  final int id;
  final String name;
  final String? description;
  final String websiteUrl;
  final String? category;
  final bool isFeatured;
  final bool isVerified;
  final bool isActive;

  factory CharityDetail.fromJson(Map<String, dynamic> json) {
    return CharityDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      websiteUrl: json['website_url']?.toString() ?? '',
      category: json['category']?.toString(),
      isFeatured: json['is_featured'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class CharityPage {
  CharityPage({required this.total, required this.limit, required this.offset, required this.data});

  final int total;
  final int limit;
  final int offset;
  final List<CharityItem> data;

  factory CharityPage.fromJson(Map<String, dynamic> json) {
    final rows = (json['data'] as List<dynamic>? ?? [])
        .map((item) => CharityItem.fromJson(Map<String, dynamic>.from(item as Map)))
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
      notificationPreferences: Map<String, dynamic>.from(json['notification_preferences'] as Map? ?? const {}),
      reminderPreferences: Map<String, dynamic>.from(json['reminder_preferences'] as Map? ?? const {}),
      accessibilityPreferences: Map<String, dynamic>.from(json['accessibility_preferences'] as Map? ?? const {}),
      privacyPreferences: Map<String, dynamic>.from(json['privacy_preferences'] as Map? ?? const {}),
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
  CategoryAnalyticsEntry({required this.category, required this.count, required this.stars});

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
    this.description,
    this.category,
  });

  final int id;
  final String name;
  final String? description;
  final String websiteUrl;
  final String? category;
  final bool isVerified;
  final bool isActive;
  final bool isFeatured;

  factory AdminCharityRecord.fromJson(Map<String, dynamic> json) {
    return AdminCharityRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      websiteUrl: json['website_url']?.toString() ?? '',
      category: json['category']?.toString(),
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
    );
  }
}

class AdminCharityPage {
  AdminCharityPage({required this.total, required this.limit, required this.offset, required this.data});

  final int total;
  final int limit;
  final int offset;
  final List<AdminCharityRecord> data;

  factory AdminCharityPage.fromJson(Map<String, dynamic> json) {
    final rows = (json['data'] as List<dynamic>? ?? [])
        .map((item) => AdminCharityRecord.fromJson(Map<String, dynamic>.from(item as Map)))
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
    final rows = (json['evidence'] as List<dynamic>? ?? [])
        .map((item) => AdminEvidenceRecord.fromJson(Map<String, dynamic>.from(item as Map)))
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
  AdminEvidencePage({required this.total, required this.limit, required this.offset, required this.data});

  final int total;
  final int limit;
  final int offset;
  final List<AdminEvidenceRecord> data;

  factory AdminEvidencePage.fromJson(Map<String, dynamic> json) {
    final rows = (json['data'] as List<dynamic>? ?? [])
        .map((item) => AdminEvidenceRecord.fromJson(Map<String, dynamic>.from(item as Map)))
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

class NotificationPage {
  NotificationPage({required this.total, required this.limit, required this.offset, required this.data});

  final int total;
  final int limit;
  final int offset;
  final List<NotificationItem> data;

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    final rows = (json['data'] as List<dynamic>? ?? [])
        .map((item) => NotificationItem.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    return NotificationPage(
      total: (json['total'] as num?)?.toInt() ?? rows.length,
      limit: (json['limit'] as num?)?.toInt() ?? rows.length,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      data: rows,
    );
  }
}

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  final int id;
  final String title;
  final String message;
  final bool isRead;
  final String? createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at']?.toString(),
    );
  }
}

class JourneyReflectionPage {
  JourneyReflectionPage({required this.items, required this.total});

  final List<JourneyReflection> items;
  final int total;

  factory JourneyReflectionPage.fromJson(Map<String, dynamic> json) {
    return JourneyReflectionPage(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => JourneyReflection.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class JourneyReflection {
  JourneyReflection({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.mood,
    required this.isPrivate,
    required this.date,
    required this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int userId;
  final String title;
  final String body;
  final String mood;
  final bool isPrivate;
  final DateTime date;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory JourneyReflection.fromJson(Map<String, dynamic> json) {
    return JourneyReflection(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      mood: json['mood']?.toString() ?? '',
      isPrivate: json['is_private'] as bool? ?? false,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }
}

class JourneyAdhkarProgress {
  JourneyAdhkarProgress({
    required this.id,
    required this.adhkarId,
    required this.count,
    required this.updatedAt,
  });

  final int id;
  final int adhkarId;
  final int count;
  final DateTime updatedAt;

  factory JourneyAdhkarProgress.fromJson(Map<String, dynamic> json) {
    return JourneyAdhkarProgress(
      id: (json['id'] as num?)?.toInt() ?? 0,
      adhkarId: (json['adhkar_id'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
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
  final DateTime createdAt;

  factory JourneyAdhkarFavorite.fromJson(Map<String, dynamic> json) {
    return JourneyAdhkarFavorite(
      id: (json['id'] as num?)?.toInt() ?? 0,
      adhkarId: (json['adhkar_id'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class BookRead {
  BookRead({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    this.coverUrl,
    required this.category,
    required this.language,
    required this.published,
    required this.sortOrder,
    this.chapterCount = 0,
    this.totalReadingTime = 0,
    this.chapters,
  });

  final int id;
  final String title;
  final String author;
  final String? description;
  final String? coverUrl;
  final String category;
  final String language;
  final bool published;
  final int sortOrder;
  final int chapterCount;
  final int totalReadingTime;
  final List<BookChapterRead>? chapters;

  factory BookRead.fromJson(Map<String, dynamic> json) {
    return BookRead(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      description: json['description']?.toString(),
      coverUrl: json['cover_url']?.toString(),
      category: json['category']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
      published: json['published'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      chapterCount: (json['chapter_count'] as num?)?.toInt() ?? 0,
      totalReadingTime: (json['total_reading_time'] as num?)?.toInt() ?? 0,
    );
  }
}

class BookChapterRead {
  BookChapterRead({
    required this.id,
    required this.bookId,
    required this.chapterNumber,
    required this.title,
    required this.content,
    required this.readingTimeMinutes,
  });

  final int id;
  final int bookId;
  final int chapterNumber;
  final String title;
  final String content;
  final int readingTimeMinutes;

  factory BookChapterRead.fromJson(Map<String, dynamic> json) {
    return BookChapterRead(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bookId: (json['book_id'] as num?)?.toInt() ?? 0,
      chapterNumber: (json['chapter_number'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      readingTimeMinutes: (json['reading_time_minutes'] as num?)?.toInt() ?? 5,
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
    required this.category,
    required this.language,
    required this.published,
    required this.sortOrder,
    required this.chapters,
  });

  final int id;
  final String title;
  final String author;
  final String? description;
  final String? coverUrl;
  final String category;
  final String language;
  final bool published;
  final int sortOrder;
  final List<BookChapterRead> chapters;

  factory BookDetail.fromJson(Map<String, dynamic> json) {
    return BookDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      description: json['description']?.toString(),
      coverUrl: json['cover_url']?.toString(),
      category: json['category']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
      published: json['published'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      chapters: (json['chapters'] as List? ?? [])
          .map((item) => BookChapterRead.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

class AdminBookPage {
  AdminBookPage({required this.total, required this.limit, required this.offset, required this.data});

  final int total;
  final int limit;
  final int offset;
  final List<AdminBookRecord> data;

  factory AdminBookPage.fromJson(Map<String, dynamic> json) {
    final rows = (json['data'] as List? ?? [])
        .map((item) => AdminBookRecord.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    return AdminBookPage(
      total: (json['total'] as num?)?.toInt() ?? rows.length,
      limit: (json['limit'] as num?)?.toInt() ?? rows.length,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      data: rows,
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
    required this.category,
    required this.language,
    required this.published,
    required this.sortOrder,
  });

  final int id;
  final String title;
  final String author;
  final String? description;
  final String? coverUrl;
  final String category;
  final String language;
  final bool published;
  final int sortOrder;

  factory AdminBookRecord.fromJson(Map<String, dynamic> json) {
    return AdminBookRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      description: json['description']?.toString(),
      coverUrl: json['cover_url']?.toString(),
      category: json['category']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
      published: json['published'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}


