import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0b0e14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0b0e14),
        title: const Text('الإعدادات',
            style: TextStyle(color: Color(0xFF38bdf8), fontWeight: FontWeight.bold)),
        leading: const BackButton(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingCard(
            icon: Icons.videogame_asset,
            title: 'عدد الأجهزة',
            subtitle: '${context.read<AppState>().numDevices} أجهزة',
            color: const Color(0xFF38bdf8),
            onTap: () => _showDevicesDialog(context),
          ),
          const SizedBox(height: 12),
          _SettingCard(
            icon: Icons.attach_money,
            title: 'أسعار اللعب',
            subtitle:
                'عادي: ${context.read<AppState>().prices['normal']} ج/س | مالتي: ${context.read<AppState>().prices['multi']} ج/س',
            color: const Color(0xFF4ade80),
            onTap: () => _showPricesDialog(context),
          ),
          const SizedBox(height: 12),
          _SettingCard(
            icon: Icons.label,
            title: 'أسماء الأجهزة',
            subtitle: 'تعديل أسماء الأجهزة',
            color: const Color(0xFFfbbf24),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const _DeviceNamesScreen())),
          ),
          const SizedBox(height: 12),
          _SettingCard(
            icon: Icons.lock,
            title: 'كلمة السر',
            subtitle: 'تغيير باسورد الأدمن',
            color: Colors.orange,
            onTap: () => _showPasswordDialog(context),
          ),
        ],
      ),
    );
  }

  void _showDevicesDialog(BuildContext context) {
    final state = context.read<AppState>();
    final ctrl = TextEditingController(text: '${state.numDevices}');
    showDialog(
      context: context,
      builder: (_) => _Dialog(
        title: 'عدد الأجهزة',
        icon: Icons.videogame_asset,
        color: const Color(0xFF38bdf8),
        child: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: _inputDeco('عدد الأجهزة'),
        ),
        onSave: () {
          final n = int.tryParse(ctrl.text);
          if (n != null && n > 0) state.updateNumDevices(n);
        },
      ),
    );
  }

  void _showPricesDialog(BuildContext context) {
    final state = context.read<AppState>();
    final normalCtrl = TextEditingController(text: '${state.prices['normal']}');
    final multiCtrl = TextEditingController(text: '${state.prices['multi']}');
    showDialog(
      context: context,
      builder: (_) => _Dialog(
        title: 'أسعار اللعب',
        icon: Icons.attach_money,
        color: const Color(0xFF4ade80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: normalCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDeco('سعر عادي (ج/س)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: multiCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDeco('سعر مالتي (ج/س)'),
            ),
          ],
        ),
        onSave: () {
          final n = int.tryParse(normalCtrl.text);
          final m = int.tryParse(multiCtrl.text);
          if (n != null && m != null) state.updatePrices(n, m);
        },
      ),
    );
  }

  void _showPasswordDialog(BuildContext context) {
    final state = context.read<AppState>();
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    String? error;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => _Dialog(
          title: 'تغيير كلمة السر',
          icon: Icons.lock,
          color: Colors.orange,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldCtrl,
                obscureText: true,
                decoration: _inputDeco('الباسورد القديم'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: _inputDeco('الباسورد الجديد'),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          onSave: () {
            if (AppState.hashPassword(oldCtrl.text) != state.adminPasswordHash) {
              setState(() => error = '❌ الباسورد القديم غلط!');
              return false;
            }
            if (newCtrl.text.length < 4) {
              setState(() => error = '❌ الباسورد قصير جداً');
              return false;
            }
            state.changePassword(newCtrl.text);
            return true;
          },
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _SettingCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1c2128),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceNamesScreen extends StatelessWidget {
  const _DeviceNamesScreen();

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final controllers = state.devices
        .map((d) => TextEditingController(text: d.displayName))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0b0e14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0b0e14),
        title: const Text('أسماء الأجهزة',
            style: TextStyle(color: Color(0xFFfbbf24), fontWeight: FontWeight.bold)),
        leading: const BackButton(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.devices.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: controllers[i],
                  decoration: _inputDeco('جهاز ${i + 1}').copyWith(
                    prefixIcon: const Icon(Icons.videogame_asset,
                        color: Color(0xFFfbbf24)),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () {
                  for (int i = 0; i < state.devices.length; i++) {
                    if (controllers[i].text.isNotEmpty) {
                      state.updateDeviceName(
                          state.devices[i], controllers[i].text);
                    }
                  }
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.save),
                label: const Text('حفظ الأسماء'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFfbbf24),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  final dynamic Function()? onSave;
  const _Dialog(
      {required this.title,
      required this.icon,
      required this.color,
      required this.child,
      this.onSave});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1c2128),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
      content: child,
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
        FilledButton(
          onPressed: () {
            final result = onSave?.call();
            if (result != false) Navigator.pop(context);
          },
          style: FilledButton.styleFrom(backgroundColor: color),
          child: const Text('حفظ', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }
}

InputDecoration _inputDeco(String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF0b0e14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF38bdf8), width: 2),
      ),
    );
