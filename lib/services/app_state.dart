import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../models/device.dart';
import 'supabase_service.dart';

class AppState extends ChangeNotifier {
  List<PSDevice> devices = [];
  List<Map<String, dynamic>> history = [];
  Map<String, int> prices = {'normal': 25, 'multi': 35};
  Map<String, int> menu = {
    'شاي': 10,
    'قهوة': 15,
    'بيبسي': 20,
    'إندومي': 25,
  };
  String adminPasswordHash = '';
  int numDevices = 6;
  bool isAdmin = false;
  Timer? _clockTimer;
  Timer? _syncTimer;
  int _syncCounter = 0;

  static String hashPassword(String p) =>
      sha256.convert(utf8.encode(p)).toString();

  static const String _defaultHash = '056cc3e4b91ffa46435bb981d0d98c329222ca41cf12825a533797330a9cc56e';
  static const String _defaultCashierHash = '03c4a40b273cfa091c7f8adfb5bd144872daabe94678c01526bd8abcc0c685ec';

  AppState() {
    adminPasswordHash = _defaultHash;
    _initDevices();
    loadData();
    _startClock();
  }

  void _initDevices() {
    devices = List.generate(numDevices, (i) => PSDevice(id: i + 1));
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      for (var d in devices) {
        if (d.isActive) d.updateTimer();
      }
      _syncCounter++;
      if (_syncCounter >= 300) {
        _syncCounter = 0;
        _syncToSupabase();
      }
      notifyListeners();
    });
  }

  Future<void> loadData() async {
    // محلي أول
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getString('app_data');
    if (local != null) {
      _applyData(jsonDecode(local));
      notifyListeners();
    }
    // Supabase في الخلفية
    _syncFromSupabase();
  }

  void _applyData(Map<String, dynamic> data) {
    // Supabase بترجع jsonb كـ Map/List مباشرة
    final rawHistory = data['history'];
    if (rawHistory is List) {
      history = rawHistory.map((h) => Map<String, dynamic>.from(h)).toList();
    }

    final rawPrices = data['prices'];
    if (rawPrices is Map) {
      prices = rawPrices.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }

    final rawMenu = data['menu'];
    if (rawMenu is Map) {
      menu = rawMenu.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }

    numDevices = data['num_devices'] ?? numDevices;
    adminPasswordHash = data['admin_password_hash'] ?? adminPasswordHash;

    final rawDevs = data['devices_state'];
    final devStates = rawDevs is List ? rawDevs : [];
    devices = [];
    for (int i = 0; i < numDevices; i++) {
      if (i < devStates.length && devStates[i] != null) {
        devices.add(PSDevice.fromJson(Map<String, dynamic>.from(devStates[i]), i + 1));
      } else {
        devices.add(PSDevice(id: i + 1));
      }
    }
    for (var d in devices) d.updateTimer();
  }

  Map<String, dynamic> _buildDataDict() => {
        'history': history,
        'prices': prices,
        'menu': menu,
        'num_devices': numDevices,
        'admin_password_hash': adminPasswordHash,
        'devices_state': devices.map((d) => d.toJson()).toList(),
        'id': 'main',
      };

  Future<void> saveData() async {
    final data = _buildDataDict();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_data', jsonEncode(data));
  }

  Future<void> _syncToSupabase() async {
    await SupabaseService.setAppData(_buildDataDict());
  }

  Future<void> _syncFromSupabase() async {
    final data = await SupabaseService.getAppData();
    if (data != null) {
      _applyData(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_data', jsonEncode(data));
      notifyListeners();
    }
  }

  // --- Device Actions ---

  void startDevice(PSDevice d, String mode) {
    d.mode = mode;
    d.status = 'شغال';
    d.startTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    d.addedSeconds = 0;
    d.isPaused = false;
    d.orders = {};
    saveData();
    notifyListeners();
  }

  void togglePause(PSDevice d) {
    if (d.isPaused) {
      final pausedDuration =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000) - d.pauseStartTime!;
      d.startTime = d.startTime! + pausedDuration;
      d.isPaused = false;
      d.pauseStartTime = null;
    } else {
      d.isPaused = true;
      d.pauseStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }
    saveData();
    notifyListeners();
  }

  Map<String, dynamic> stopDevice(PSDevice d) {
    final timePrice = d.calculateTimePrice(prices);
    final buffetPrice = d.getBuffetPrice(menu);
    final elapsed = d.elapsedSeconds;
    final h = elapsed ~/ 3600;
    final m = (elapsed % 3600) ~/ 60;
    final duration = '${h}س ${m}د';

    final record = {
      'id': d.id,
      'name': d.displayName,
      'duration': duration,
      'elapsed_seconds': elapsed,
      'play_mode': d.mode,
      'time_cost': timePrice,
      'buffet_cost': buffetPrice,
      'total': timePrice + buffetPrice,
      'orders': d.orders,
      'date': DateTime.now().toString(),
    };

    history.add(record);
    d.status = 'متاح';
    d.startTime = null;
    d.addedSeconds = 0;
    d.isPaused = false;
    d.pauseStartTime = null;
    d.orders = {};
    d.timerText = '00:00:00';
    saveData();
    notifyListeners();
    return record;
  }

  void addOrder(PSDevice d, String item, int qty) {
    d.orders[item] = (d.orders[item] ?? 0) + qty;
    if (d.orders[item]! <= 0) d.orders.remove(item);
    saveData();
    notifyListeners();
  }

  Future<void> archiveAndClear() async {
    if (history.isEmpty) return;
    final totalTime = history.fold(0.0, (s, h) => s + ((h['time_cost'] as num?) ?? 0));
    final totalBuffet = history.fold(0.0, (s, h) => s + ((h['buffet_cost'] as num?) ?? 0));
    final archive = {
      'date': DateTime.now().toString(),
      'total_time': totalTime,
      'total_buffet': totalBuffet,
      'total_overall': totalTime + totalBuffet,
      'records': history,
    };

    // حفظ محلي في SharedPreferences أولاً
    final prefs = await SharedPreferences.getInstance();
    final localArchives = jsonDecode(prefs.getString('local_archives') ?? '[]') as List;
    localArchives.add(archive);
    await prefs.setString('local_archives', jsonEncode(localArchives));

    // مسح الـ history فوراً
    history.clear();
    await saveData();
    notifyListeners();

    // رفع على Supabase في الخلفية
    SupabaseService.pushArchive(archive);
  }

  bool get isLoggedIn => isAdmin || userRole == "cashier";

  // إضافة وقت للجهاز
  void addTime(PSDevice d, int minutes) {
    d.addedSeconds += minutes * 60;
    saveData();
    notifyListeners();
  }

  // إلغاء الجهاز بدون حساب
  void cancelDevice(PSDevice d) {
    d.status = 'متاح';
    d.startTime = null;
    d.addedSeconds = 0;
    d.isPaused = false;
    d.pauseStartTime = null;
    d.orders = {};
    d.timerText = '00:00:00';
    saveData();
    notifyListeners();
  }

  // إدارة قائمة البوفيه
  void addMenuItem(String name, int price) {
    menu[name] = price;
    saveData();
    notifyListeners();
  }

  void updateMenuItem(String oldName, String newName, int price) {
    menu.remove(oldName);
    menu[newName] = price;
    saveData();
    notifyListeners();
  }

  void removeMenuItem(String name) {
    menu.remove(name);
    saveData();
    notifyListeners();
  }

  // باسورد الكاشير
  String cashierPasswordHash = '03c4a40b273cfa091c7f8adfb5bd144872daabe94678c01526bd8abcc0c685ec';

  void changeCashierPassword(String newPass) {
    cashierPasswordHash = hashPassword(newPass);
    saveData();
  }

  // نوع المستخدم: admin أو cashier
  String userRole = '';

  bool login(String password) {
    final hash = hashPassword(password);
    if (hash == adminPasswordHash) {
      isAdmin = true;
      userRole = 'admin';
      notifyListeners();
      return true;
    } else if (hash == cashierPasswordHash) {
      isAdmin = false;
      userRole = 'cashier';
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    isAdmin = false;
    userRole = '';
    notifyListeners();
  }

  void changePassword(String newPass) {
    adminPasswordHash = hashPassword(newPass);
    saveData();
  }

  void updatePrices(int normal, int multi) {
    prices = {'normal': normal, 'multi': multi};
    saveData();
    notifyListeners();
  }

  void updateDeviceName(PSDevice d, String name) {
    d.displayName = name;
    saveData();
    notifyListeners();
  }

  void updateNumDevices(int count) {
    numDevices = count;
    if (count > devices.length) {
      for (int i = devices.length + 1; i <= count; i++) {
        devices.add(PSDevice(id: i));
      }
    } else {
      devices = devices.sublist(0, count);
    }
    saveData();
    notifyListeners();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _syncTimer?.cancel();
    _syncToSupabase();
    super.dispose();
  }
}
