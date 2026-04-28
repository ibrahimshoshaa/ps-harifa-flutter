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
  int numDevices = 6;
  bool isAdmin = false;
  Timer? _clockTimer;
  Timer? _syncTimer;
  int _syncCounter = 0;

  static String hashPassword(String p) =>
      sha256.convert(utf8.encode(p)).toString();

  static const String _defaultHash =
      '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92';

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
        _syncToFirebase();
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
    // Firebase في الخلفية
    _syncFromFirebase();
  }

  void _applyData(Map<String, dynamic> data) {
    history = List<Map<String, dynamic>>.from(data['history'] ?? []);
    prices = Map<String, int>.from(data['prices'] ?? prices);
    menu = Map<String, int>.from(data['menu'] ?? menu);
    numDevices = data['num_devices'] ?? 6;
    adminPasswordHash = data['admin_password_hash'] ?? adminPasswordHash;
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

    // رفع على Firebase في الخلفية
    FirebaseService.push('archives', archive);
  }

  bool login(String password) {
    if (hashPassword(password) == adminPasswordHash) {
      isAdmin = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    isAdmin = false;
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
    _syncToFirebase();
    super.dispose();
  }
}
