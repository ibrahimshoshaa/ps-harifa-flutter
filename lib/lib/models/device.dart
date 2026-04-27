class PSDevice {
  int id;
  String displayName;
  String mode; // 'normal' or 'multi'
  String status; // 'متاح' or 'شغال'
  int? startTime; // unix timestamp seconds
  int addedSeconds;
  bool isPaused;
  int? pauseStartTime;
  Map<String, int> orders;
  String timerText;

  PSDevice({required this.id})
      : displayName = 'PS $id',
        mode = 'normal',
        status = 'متاح',
        startTime = null,
        addedSeconds = 0,
        isPaused = false,
        pauseStartTime = null,
        orders = {},
        timerText = '00:00:00';

  bool get isRunning => startTime != null && !isPaused;
  bool get isActive => startTime != null;

  int get elapsedSeconds {
    if (startTime == null) return 0;
    if (isPaused && pauseStartTime != null) {
      return (pauseStartTime! - startTime!) + addedSeconds;
    }
    return (DateTime.now().millisecondsSinceEpoch ~/ 1000 - startTime!) +
        addedSeconds;
  }

  double calculateTimePrice(Map<String, int> prices) {
    if (startTime == null) return 0;
    final rate = prices[mode] ?? 25;
    return (elapsedSeconds / 3600) * rate;
  }

  double getBuffetPrice(Map<String, int> menu) {
    double total = 0;
    orders.forEach((item, qty) {
      total += qty * (menu[item] ?? 0);
    });
    return total;
  }

  void updateTimer() {
    final s = elapsedSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    timerText =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'mode': mode,
        'status': status,
        'start_time': startTime,
        'added_seconds': addedSeconds,
        'is_paused': isPaused,
        'pause_start_time': pauseStartTime,
        'orders': orders,
      };

  factory PSDevice.fromJson(Map<String, dynamic> j, int id) {
    final d = PSDevice(id: id);
    d.displayName = j['display_name'] ?? 'PS $id';
    d.mode = j['mode'] ?? 'normal';
    d.status = j['status'] ?? 'متاح';
    d.startTime = j['start_time'];
    d.addedSeconds = j['added_seconds'] ?? 0;
    d.isPaused = j['is_paused'] ?? false;
    d.pauseStartTime = j['pause_start_time'];
    d.orders = Map<String, int>.from(j['orders'] ?? {});
    return d;
  }
}
