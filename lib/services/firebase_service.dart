import 'dart:convert';
import 'package:http/http.dart' as http;

class FirebaseService {
  static const String _baseUrl =
      'https://ps-harifa-default-rtdb.firebaseio.com';
  static const String _secret =
      'loFnECpWdlhEHnzGdPW1VoWKbZPepbgrqDVjTnEY';

  static String _url(String path) => '$_baseUrl/$path.json?auth=$_secret';

  static Future<dynamic> get(String path) async {
    try {
      final r = await http
          .get(Uri.parse(_url(path)))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      print('Firebase GET error: $e');
    }
    return null;
  }

  static Future<bool> set(String path, dynamic data) async {
    try {
      final r = await http
          .put(Uri.parse(_url(path)), body: jsonEncode(data))
          .timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (e) {
      print('Firebase SET error: $e');
      return false;
    }
  }

  static Future<String?> push(String path, dynamic data) async {
    try {
      final r = await http
          .post(Uri.parse(_url(path)), body: jsonEncode(data))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        return jsonDecode(r.body)['name'];
      }
    } catch (e) {
      print('Firebase PUSH error: $e');
    }
    return null;
  }

  static Future<bool> delete(String path) async {
    try {
      final r = await http
          .delete(Uri.parse(_url(path)))
          .timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (e) {
      print('Firebase DELETE error: $e');
      return false;
    }
  }
}
