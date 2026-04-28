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

  static Future<Map<String, dynamic>?> getAppData() async {
    try {
      final r = await http.get(
        Uri.parse('$_url/rest/v1/app_data?id=eq.main'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final list = jsonDecode(r.body) as List;
        if (list.isNotEmpty) return Map<String, dynamic>.from(list.first);
      }
    } catch (e) {
      print('Supabase getAppData error: $e');
    }
    return null;
  }

  static Future<bool> setAppData(Map<String, dynamic> data) async {
    try {
      data['id'] = 'main';
      data['updated_at'] = DateTime.now().toIso8601String();
      final r = await http.patch(
        Uri.parse('$_url/rest/v1/app_data?id=eq.main'),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      return r.statusCode == 200 || r.statusCode == 204;
    } catch (e) {
      print('Supabase setAppData error: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getArchives() async {
    try {
      final r = await http.get(
        Uri.parse('$_url/rest/v1/archives?order=created_at.desc'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final list = jsonDecode(r.body) as List;
        return list.map((v) => Map<String, dynamic>.from(v)).toList();
      }
    } catch (e) {
      print('Supabase getArchives error: $e');
    }
    return [];
  }

  static Future<bool> pushArchive(Map<String, dynamic> data) async {
    try {
      final r = await http.post(
        Uri.parse('$_url/rest/v1/archives'),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      return r.statusCode == 201;
    } catch (e) {
      print('Supabase pushArchive error: $e');
      return false;
    }
  }

  static Future<bool> deleteArchives() async {
    try {
      final r = await http.delete(
        Uri.parse('$_url/rest/v1/archives?id=neq.00000000-0000-0000-0000-000000000000'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      return r.statusCode == 200 || r.statusCode == 204;
    } catch (e) {
      print('Supabase deleteArchives error: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getYearlyArchives() async {
    try {
      final r = await http.get(
        Uri.parse('$_url/rest/v1/yearly_archives?order=created_at.desc'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final list = jsonDecode(r.body) as List;
        return list.map((v) => Map<String, dynamic>.from(v)).toList();
      }
    } catch (e) {
      print('Supabase getYearlyArchives error: $e');
    }
    return [];
  }

  static Future<bool> pushYearlyArchive(Map<String, dynamic> data) async {
    try {
      final r = await http.post(
        Uri.parse('$_url/rest/v1/yearly_archives'),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      return r.statusCode == 201;
    } catch (e) {
      print('Supabase pushYearlyArchive error: $e');
      return false;
    }
  }
}
