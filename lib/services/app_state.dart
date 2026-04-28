import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../models/device.dart';
import 'firebase_service.dart';

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
  String cashierPasswordHash = '';
  int numDevices = 6;
  bool isAdmin = false;
  bool isCashier = false;
  Timer? _clockTimer;
  Timer? _syncTimer;
  int _syncCounter = 0;
  bool _archiving = false; // ← منع sync أثناء الأرشفة

  bool get isLoggedIn => isAdmin || isCashier;

  static String hashPassword(String p) =>
      sha256.convert(utf8.encode(p)).toString();

  static const String _defaultAdminHash =
      '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92';
  static const String _defaultCashierHash =
      'ef797c8118f02dfb649607dd5d3f8c7623048c9c063d532cc95c5ed7a898a64f';

  AppState() {
    adminPasswordHash = _defaultAdminHash;
    cashierPasswordHash = _defaultCashierHash;
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
        if (!_archiving) _syncToFirebase();
      }
      notifyListeners();
    });
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getString('app_data');
    if (local != null) {
      _applyData(jsonDecode(local));
      notifyListeners();
    }
    _syncFromFirebase();
  }

  void _applyData(Map<String, dynamic> data) {
    history = List<Map<String, dynamic>>.from(data['history'] ?? []);
    prices = Map<String, int>.from(data['prices'] ?? prices);
    menu = Map<String, int>.from(data['menu'] ?? menu);
    numDevices = data['num_devices'] ?? 6;
    adminPasswordHash = data['admin_password_hash'] ?? adminPasswordHash;
    cashierPasswordHash = data['cashier_password_hash'] ?? cashierPasswordHash;
    final devStates = data['devices_state'] as List? ?? [];
    devices = [];
    for (int i = 0; i < numDevices; i++) {
      if (i < devStates.length) {
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
        'cashier_password_hash': cashierPasswordHash,
        'devices_state': devices.map((d) => d.toJson()).toList(),
      };

  Future<void> saveData() async {
    final data = _buildDataDict();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_data', jsonEncode(data));
  }

  Future<void> _syncToFirebase() async {
    await FirebaseService.set('app_data', _buildDataDict());
  }

  Future<void> _syncFromFirebase() async {
    if (_archiving) return; // ← مش نرجع بيانات قديمة أثناء الأرشفة
    final data = await FirebaseService.get('app_data');
    if (data != null) {
      _applyData(Map<String, dynamic>.from(data));
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

  void addTime(PSDevice d, int minutes) {
    if (d.startTime != null) {
      d.startTime = d.startTime! - minutes * 60;
    }
    saveData();
    notifyListeners();
  }

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

  Future<bool> archiveAndClear() async {
    if (history.isEmpty) return false;
    _archiving = true; // ← وقف الـ sync

    try {
      final totalTime = history.fold(0.0, (s, h) => s + (h['time_cost'] ?? 0));
      final totalBuffet = history.fold(0.0, (s, h) => s + (h['buffet_cost'] ?? 0));
      final archive = {
        'date': DateTime.now().toString(),
        'total_time': totalTime,
        'total_buffet': totalBuffet,
        'total_overall': totalTime + totalBuffet,
        'records': history,
      };

      // 1) ارفع الأرشيف لـ Firebase
      final result = await FirebaseService.push('archives', archive);
      if (result == null) return false;

      // 2) امسح الـ history محلياً
      history.clear();

      // 3) احفظ محلياً
      await saveData();

      // 4) ارفع البيانات الجديدة (بدون history) لـ Firebase
      await _syncToFirebase();

      notifyListeners();
      return true;
    } finally {
      _archiving = false; // ← فك الـ sync
    }
  }

  // --- Menu Management ---

  void addMenuItem(String name, int price) {
    menu[name] = price;
    saveData();
    notifyListeners();
  }

  void removeMenuItem(String name) {
    menu.remove(name);
    saveData();
    notifyListeners();
  }

  void updateMenuItem(String oldName, String newName, int price) {
    menu.remove(oldName);
    menu[newName] = price;
    saveData();
    notifyListeners();
  }

  // --- Auth ---

  String? login(String password) {
    final hash = hashPassword(password);
    if (hash == adminPasswordHash) {
      isAdmin = true;
      isCashier = false;
      notifyListeners();
      return 'admin';
    }
    if (hash == cashierPasswordHash) {
      isCashier = true;
      isAdmin = false;
      notifyListeners();
      return 'cashier';
    }
    return null;
  }

  void logout() {
    isAdmin = false;
    isCashier = false;
    notifyListeners();
  }

  void changePassword(String newPass) {
    adminPasswordHash = hashPassword(newPass);
    saveData();
  }

  void changeCashierPassword(String newPass) {
    cashierPasswordHash = hashPassword(newPass);
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
    _syncToFirebase();
    super.dispose();
  }
}
