import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_api.dart';

/// Basic ContentService scaffold.
/// Attempts to fetch journey content from the backend and returns a parsed
/// map. If the backend endpoint is not available or fails, returns null.
class ContentService {
  ContentService._();
  static final instance = ContentService._();

  /// Fetches "rhythm of the day" content. Returns null on failure.
  Future<Map<String, dynamic>?> fetchRhythmOfTheDay() async {
    try {
      final base = BackendApi.instance.baseUrl;
      final uri = Uri.parse('$base/journey/rhythm-of-day');
      final token = await BackendApi.instance.getToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
      final resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      // Backend may use envelope; try to unwrap if needed
      if (decoded.containsKey('data')) return decoded['data'] as Map<String, dynamic>;
      return decoded;
    } catch (_) {
      return null;
    }
  }
}
