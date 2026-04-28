import 'dart:convert';
import 'package:http/http.dart' as http;

class SupabaseService {
  static const String _url = 'https://afajbspvzpjmdputdhow.supabase.co';
  static const String _key =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFmYWpic3B2enBqbWRwdXRkaG93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczODc1MjIsImV4cCI6MjA5Mjk2MzUyMn0.FupMVDjogd50RL8hg3F3Dnn9rpsiUtIlcekAvVg4ZUU';

  static Map<String, String> get _headers => {
        'apikey': _key,
        'Authorization': 'Bearer $_key',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  // ── Settings ──────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getSettings() async {
    try {
      final r = await http
          .get(Uri.parse('$_url/rest/v1/app_settings?id=eq.1'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final list = jsonDecode(r.body) as List;
        if (list.isNotEmpty) return Map<String, dynamic>.from(list.first);
      }
    } catch (e) {
      print('Supabase getSettings error: $e');
    }
    return null;
  }

  static Future<bool> saveSettings(Map<String, dynamic> data) async {
    try {
      final r = await http
          .patch(
            Uri.parse('$_url/rest/v1/app_settings?id=eq.1'),
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));
      return r.statusCode == 200 || r.statusCode == 204;
    } catch (e) {
      print('Supabase saveSettings error: $e');
      return false;
    }
  }

  // ── Devices State ─────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getDevices() async {
    try {
      final r = await http
          .get(Uri.parse('$_url/rest/v1/devices_state?order=id'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        return List<Map<String, dynamic>>.from(
            (jsonDecode(r.body) as List).map((e) => Map<String, dynamic>.from(e)));
      }
    } catch (e) {
      print('Supabase getDevices error: $e');
    }
    return [];
  }

  static Future<bool> upsertDevice(Map<String, dynamic> deviceJson) async {
    try {
      final headers = Map<String, String>.from(_headers);
      headers['Prefer'] = 'resolution=merge-duplicates';
      final r = await http
          .post(
            Uri.parse('$_url/rest/v1/devices_state'),
            headers: headers,
            body: jsonEncode(deviceJson),
          )
          .timeout(const Duration(seconds: 10));
      return r.statusCode == 200 || r.statusCode == 201;
    } catch (e) {
      print('Supabase upsertDevice error: $e');
      return false;
    }
  }

  static Future<bool> upsertAllDevices(List<Map<String, dynamic>> devices) async {
    try {
      final headers = Map<String, String>.from(_headers);
      headers['Prefer'] = 'resolution=merge-duplicates';
      final r = await http
          .post(
            Uri.parse('$_url/rest/v1/devices_state'),
            headers: headers,
            body: jsonEncode(devices),
          )
          .timeout(const Duration(seconds: 10));
      return r.statusCode == 200 || r.statusCode == 201;
    } catch (e) {
      print('Supabase upsertAllDevices error: $e');
      return false;
    }
  }

  // ── History ───────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final r = await http
          .get(Uri.parse('$_url/rest/v1/history?order=created_at.asc'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        return List<Map<String, dynamic>>.from(
            (jsonDecode(r.body) as List).map((e) => Map<String, dynamic>.from(e)));
      }
    } catch (e) {
      print('Supabase getHistory error: $e');
    }
    return [];
  }

  static Future<bool> insertHistory(Map<String, dynamic> record) async {
    try {
      final r = await http
          .post(
            Uri.parse('$_url/rest/v1/history'),
            headers: _headers,
            body: jsonEncode(record),
          )
          .timeout(const Duration(seconds: 10));
      return r.statusCode == 200 || r.statusCode == 201;
    } catch (e) {
      print('Supabase insertHistory error: $e');
      return false;
    }
  }

  static Future<bool> clearHistory() async {
    try {
      final r = await http
          .delete(Uri.parse('$_url/rest/v1/history?id=gt.0'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return r.statusCode == 200 || r.statusCode == 204;
    } catch (e) {
      print('Supabase clearHistory error: $e');
      return false;
    }
  }

  // ── Archives ──────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getArchives() async {
    try {
      final r = await http
          .get(Uri.parse('$_url/rest/v1/archives?order=created_at.desc'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        return List<Map<String, dynamic>>.from(
            (jsonDecode(r.body) as List).map((e) => Map<String, dynamic>.from(e)));
      }
    } catch (e) {
      print('Supabase getArchives error: $e');
    }
    return [];
  }

  static Future<bool> insertArchive(Map<String, dynamic> archive) async {
    try {
      final r = await http
          .post(
            Uri.parse('$_url/rest/v1/archives'),
            headers: _headers,
            body: jsonEncode(archive),
          )
          .timeout(const Duration(seconds: 10));
      return r.statusCode == 200 || r.statusCode == 201;
    } catch (e) {
      print('Supabase insertArchive error: $e');
      return false;
    }
  }

  static Future<bool> clearArchives() async {
    try {
      final r = await http
          .delete(Uri.parse('$_url/rest/v1/archives?id=gt.0'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return r.statusCode == 200 || r.statusCode == 204;
    } catch (e) {
      print('Supabase clearArchives error: $e');
      return false;
    }
  }

  // ── Yearly Archives ───────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getYearlyArchives() async {
    try {
      final r = await http
          .get(Uri.parse('$_url/rest/v1/yearly_archives?order=archived_on.desc'),
              headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        return List<Map<String, dynamic>>.from(
            (jsonDecode(r.body) as List).map((e) => Map<String, dynamic>.from(e)));
      }
    } catch (e) {
      print('Supabase getYearlyArchives error: $e');
    }
    return [];
  }

  static Future<bool> insertYearlyArchive(Map<String, dynamic> entry) async {
    try {
      final r = await http
          .post(
            Uri.parse('$_url/rest/v1/yearly_archives'),
            headers: _headers,
            body: jsonEncode(entry),
          )
          .timeout(const Duration(seconds: 10));
      return r.statusCode == 200 || r.statusCode == 201;
    } catch (e) {
      print('Supabase insertYearlyArchive error: $e');
      return false;
    }
  }
}
