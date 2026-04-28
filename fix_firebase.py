content = """import 'supabase_service.dart';
export 'supabase_service.dart';

class FirebaseService {
  static Future<dynamic> get(String path) async {
    if (path == 'archives') return await SupabaseService.getArchives();
    return await SupabaseService.getAppData();
  }
  static Future<bool> set(String path, dynamic data) =>
      SupabaseService.setAppData(Map<String, dynamic>.from(data));
  static Future<String?> push(String path, dynamic data) async {
    final ok = path == 'yearly_archives'
        ? await SupabaseService.pushYearlyArchive(Map<String, dynamic>.from(data))
        : await SupabaseService.pushArchive(Map<String, dynamic>.from(data));
    return ok ? 'ok' : null;
  }
  static Future<bool> delete(String path) => SupabaseService.deleteArchives();
}
"""
with open('lib/services/firebase_service.dart', 'w') as f:
    f.write(content)
print('Firebase shim created OK')
