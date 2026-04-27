import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isAdmin = state.isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFF0b0e14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0b0e14),
        title: const Text('الإعدادات',
            style: TextStyle(
                color: Color(0xFF38bdf8), fontWeight: FontWeight.bold)),
        leading: const BackButton(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── متاح للكل ──────────────────────────────────────
          _SectionHeader('🎮 الأجهزة'),
          const SizedBox(height: 8),
          _SettingCard(
            icon: Icons.label,
            title: 'أسماء الأجهزة',
            subtitle: 'تعديل أسماء الأجهزة',
            color: const Color(0xFFfbbf24),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const _DeviceNamesScreen())),
          ),

          // ── أدمن فقط ──────────────────────────────────────
          if (isAdmin) ...[
            const SizedBox(height: 8),
            _SettingCard(
              icon: Icons.videogame_asset,
              title: 'عدد الأجهزة',
              subtitle: '${state.numDevices} أجهزة',
              color: const Color(0xFF38bdf8),
              onTap: () => _showDevicesDialog(context),
            ),
          ],

          const SizedBox(height: 20),
          _SectionHeader('💰 الأسعار'),
          const SizedBox(height: 8),

          if (isAdmin) ...[
            _SettingCard(
              icon: Icons.attach_money,
              title: 'أسعار اللعب',
              subtitle:
                  'عادي: ${state.prices['normal']} ج/س | مالتي: ${state.prices['multi']} ج/س',
              color: const Color(0xFF4ade80),
              onTap: () => _showPricesDialog(context),
            ),
          ] else
            _LockedCard('أسعار اللعب'),

          const SizedBox(height: 20),
          _SectionHeader('🥤 البوفيه'),
          const SizedBox(height: 8),

          if (isAdmin)
            _SettingCard(
              icon: Icons.fastfood,
              title: 'إدارة منتجات البوفيه',
              subtitle: '${state.menu.length} منتجات',
              color: Colors.orange,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const _MenuManagementScreen())),
            )
          else
            _LockedCard('إدارة منتجات البوفيه'),

          const SizedBox(height: 20),
          _SectionHeader('🔐 كلمات السر'),
          const SizedBox(height: 8),

          if (isAdmin) ...[
            _SettingCard(
              icon: Icons.lock,
              title: 'كلمة سر الأدمن',
              subtitle: 'تغيير باسورد الأدمن',
              color: Colors.redAccent,
              onTap: () => _showPasswordDialog(context, isAdmin: true),
            ),
            const SizedBox(height: 8),
            _SettingCard(
              icon: Icons.lock_person,
              title: 'كلمة سر الكاشير',
              subtitle: 'تغيير باسورد الكاشير',
              color: const Color(0xFF38bdf8),
              onTap: () => _showPasswordDialog(context, isAdmin: false),
            ),
          ] else
            _LockedCard('تغيير كلمات السر'),
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
    final normalCtrl =
        TextEditingController(text: '${state.prices['normal']}');
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

  void _showPasswordDialog(BuildContext context, {required bool isAdmin}) {
    final state = context.read<AppState>();
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    String? error;
    final label = isAdmin ? 'الأدمن' : 'الكاشير';
    final color = isAdmin ? Colors.redAccent : const Color(0xFF38bdf8);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => _Dialog(
          title: 'كلمة سر $label',
          icon: Icons.lock,
          color: color,
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
            final currentHash = isAdmin
                ? state.adminPasswordHash
                : state.cashierPasswordHash;
            if (AppState.hashPassword(oldCtrl.text) != currentHash) {
              setState(() => error = '❌ الباسورد القديم غلط!');
              return false;
            }
            if (newCtrl.text.length < 4) {
              setState(() => error = '❌ الباسورد قصير جداً');
              return false;
            }
            if (isAdmin) {
              state.changePassword(newCtrl.text);
            } else {
              state.changeCashierPassword(newCtrl.text);
            }
            return true;
          },
        ),
      ),
    );
  }
}

// ─── Menu Management Screen ────────────────────────────────────────────────────

class _MenuManagementScreen extends StatelessWidget {
  const _MenuManagementScreen();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0b0e14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0b0e14),
        title: const Text('إدارة البوفيه',
            style: TextStyle(
                color: Colors.orange, fontWeight: FontWeight.bold)),
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.orange, size: 28),
            onPressed: () => _showAddItemDialog(context, state),
            tooltip: 'إضافة منتج',
          ),
        ],
      ),
      body: state.menu.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fastfood, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text('البوفيه فاضي!',
                      style: TextStyle(color: Colors.white54, fontSize: 18)),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _showAddItemDialog(context, state),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة أول منتج'),
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.menu.length,
              itemBuilder: (ctx, i) {
                final entry = state.menu.entries.toList()[i];
                return _MenuItemTile(
                  name: entry.key,
                  price: entry.value,
                  onEdit: () =>
                      _showEditItemDialog(context, state, entry.key, entry.value),
                  onDelete: () => _confirmDelete(context, state, entry.key),
                );
              },
            ),
    );
  }

  void _showAddItemDialog(BuildContext context, AppState state) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => _Dialog(
        title: 'إضافة منتج',
        icon: Icons.add_circle,
        color: Colors.orange,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: _inputDeco('اسم المنتج'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDeco('السعر (ج)'),
            ),
          ],
        ),
        onSave: () {
          final name = nameCtrl.text.trim();
          final price = int.tryParse(priceCtrl.text);
          if (name.isEmpty || price == null || price <= 0) return false;
          state.addMenuItem(name, price);
          return true;
        },
      ),
    );
  }

  void _showEditItemDialog(
      BuildContext context, AppState state, String oldName, int oldPrice) {
    final nameCtrl = TextEditingController(text: oldName);
    final priceCtrl = TextEditingController(text: '$oldPrice');
    showDialog(
      context: context,
      builder: (_) => _Dialog(
        title: 'تعديل منتج',
        icon: Icons.edit,
        color: const Color(0xFF38bdf8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: _inputDeco('اسم المنتج'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDeco('السعر (ج)'),
            ),
          ],
        ),
        onSave: () {
          final name = nameCtrl.text.trim();
          final price = int.tryParse(priceCtrl.text);
          if (name.isEmpty || price == null || price <= 0) return false;
          state.updateMenuItem(oldName, name, price);
          return true;
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState state, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1c2128),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف منتج',
            style: TextStyle(color: Colors.red)),
        content: Text('هيتم حذف "$name" من البوفيه',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء',
                  style: TextStyle(color: Colors.white54))),
          FilledButton(
            onPressed: () {
              state.removeMenuItem(name);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  final String name;
  final int price;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _MenuItemTile(
      {required this.name,
      required this.price,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1c2128),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.fastfood, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Text('$price ج',
                    style: const TextStyle(
                        color: Color(0xFF4ade80), fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF38bdf8), size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ─── Device Names Screen ───────────────────────────────────────────────────────

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
            style: TextStyle(
                color: Color(0xFFfbbf24), fontWeight: FontWeight.bold)),
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

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 4),
      child: Text(title,
          style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1)),
    );
  }
}

class _LockedCard extends StatelessWidget {
  final String title;
  const _LockedCard(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1c2128).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock, color: Colors.white24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const Text('للأدمن فقط',
                    style: TextStyle(color: Colors.white24, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, color: Colors.white24),
        ],
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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
      content: child,
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء',
                style: TextStyle(color: Colors.white54))),
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
        borderSide:
            const BorderSide(color: Color(0xFF38bdf8), width: 2),
      ),
    );
