import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../services/app_state.dart';

class DeviceDetailScreen extends StatelessWidget {
  final PSDevice device;
  const DeviceDetailScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final timePrice = device.calculateTimePrice(state.prices);
    final buffetPrice = device.getBuffetPrice(state.menu);

    return Scaffold(
      backgroundColor: const Color(0xFF0b0e14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0b0e14),
        title: Text(device.displayName,
            style: const TextStyle(color: Color(0xFF38bdf8), fontWeight: FontWeight.bold)),
        leading: const BackButton(color: Colors.white),
        actions: [
          if (device.isActive)
            IconButton(
              icon: Icon(
                device.isPaused ? Icons.play_circle_fill : Icons.pause_circle_filled,
                color: device.isPaused ? Colors.amber : const Color(0xFF38bdf8),
                size: 30,
              ),
              onPressed: () => state.togglePause(device),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Timer Card
            _TimerCard(device: device, timePrice: timePrice, buffetPrice: buffetPrice),
            const SizedBox(height: 16),

            // Mode selector (only when not running)
            if (!device.isActive) _ModeSelector(device: device),

            // Start button
            if (!device.isActive) ...[
              const SizedBox(height: 16),
              _StartButtons(device: device),
            ],

            // Buffet section
            if (device.isActive) ...[
              const SizedBox(height: 16),
              _BuffetSection(device: device),
            ],

            // Stop button
            if (device.isActive) ...[
              const SizedBox(height: 16),
              _StopButton(device: device),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  final PSDevice device;
  final double timePrice;
  final double buffetPrice;
  const _TimerCard(
      {required this.device,
      required this.timePrice,
      required this.buffetPrice});

  @override
  Widget build(BuildContext context) {
    final isPaused = device.isPaused;
    final isActive = device.isActive;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1c2128),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPaused
              ? Colors.amber
              : isActive
                  ? const Color(0xFF38bdf8)
                  : Colors.white12,
          width: 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: (isPaused ? Colors.amber : const Color(0xFF38bdf8))
                      .withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Column(
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: (isPaused
                      ? Colors.amber
                      : isActive
                          ? const Color(0xFF38bdf8)
                          : Colors.white24)
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPaused ? '⏸ موقوف' : isActive ? '🎮 شغال' : '✅ متاح',
              style: TextStyle(
                color: isPaused
                    ? Colors.amber
                    : isActive
                        ? const Color(0xFF38bdf8)
                        : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Big Timer
          Text(
            device.timerText,
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: isPaused ? Colors.amber : Colors.white,
              shadows: isActive
                  ? [
                      Shadow(
                        color: (isPaused ? Colors.amber : const Color(0xFF38bdf8))
                            .withOpacity(0.5),
                        blurRadius: 12,
                      )
                    ]
                  : [],
            ),
          ),
          const SizedBox(height: 16),

          // Price breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PriceTile('🎮 لعب', timePrice),
              Container(width: 1, height: 40, color: Colors.white12),
              _PriceTile('🥤 بوفيه', buffetPrice),
              Container(width: 1, height: 40, color: Colors.white12),
              _PriceTile('💰 الإجمالي', timePrice + buffetPrice,
                  highlight: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceTile extends StatelessWidget {
  final String label;
  final double value;
  final bool highlight;
  const _PriceTile(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)} ج',
          style: TextStyle(
            fontSize: highlight ? 18 : 14,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            color: highlight ? const Color(0xFF4ade80) : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final PSDevice device;
  const _ModeSelector({required this.device});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Row(
      children: [
        _ModeBtn(
          label: 'عادي',
          icon: Icons.person,
          selected: device.mode == 'normal',
          price: state.prices['normal'] ?? 25,
          onTap: () {
            device.mode = 'normal';
            state.notifyListeners();
          },
        ),
        const SizedBox(width: 12),
        _ModeBtn(
          label: 'مالتي',
          icon: Icons.people,
          selected: device.mode == 'multi',
          price: state.prices['multi'] ?? 35,
          onTap: () {
            device.mode = 'multi';
            state.notifyListeners();
          },
        ),
      ],
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final int price;
  final VoidCallback onTap;
  const _ModeBtn(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.price,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF38bdf8).withOpacity(0.15)
                : const Color(0xFF1c2128),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? const Color(0xFF38bdf8) : Colors.white12,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? const Color(0xFF38bdf8) : Colors.white54),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? const Color(0xFF38bdf8) : Colors.white)),
              Text('$price ج/س',
                  style: const TextStyle(fontSize: 12, color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartButtons extends StatelessWidget {
  final PSDevice device;
  const _StartButtons({required this.device});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: () {
          state.startDevice(device, device.mode);
          Navigator.pop(context);
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('بدء اللعب', style: TextStyle(fontSize: 18)),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _BuffetSection extends StatelessWidget {
  final PSDevice device;
  const _BuffetSection({required this.device});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1c2128),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🥤 البوفيه',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...state.menu.entries.map((e) => _BuffetItem(
                name: e.key,
                price: e.value,
                qty: device.orders[e.key] ?? 0,
                onAdd: () => state.addOrder(device, e.key, 1),
                onRemove: () => state.addOrder(device, e.key, -1),
              )),
        ],
      ),
    );
  }
}

class _BuffetItem extends StatelessWidget {
  final String name;
  final int price;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _BuffetItem(
      {required this.name,
      required this.price,
      required this.qty,
      required this.onAdd,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('$price ج',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.red),
                onPressed: qty > 0 ? onRemove : null,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Text(
                  '$qty',
                  key: ValueKey(qty),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: Color(0xFF4ade80)),
                onPressed: onAdd,
              ),
            ],
          ),
          SizedBox(
            width: 60,
            child: Text(
              '${qty * price} ج',
              textAlign: TextAlign.end,
              style: const TextStyle(
                  color: Color(0xFF4ade80), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  final PSDevice device;
  const _StopButton({required this.device});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final timePrice = device.calculateTimePrice(state.prices);
    final buffetPrice = device.getBuffetPrice(state.menu);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF1c2128),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('إنهاء ${device.displayName}',
                  style: const TextStyle(color: Color(0xFF38bdf8))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Row('🎮 اللعب', '${timePrice.toStringAsFixed(1)} ج'),
                  _Row('🥤 البوفيه', '${buffetPrice.toStringAsFixed(1)} ج'),
                  const Divider(color: Colors.white24),
                  _Row('💰 الإجمالي',
                      '${(timePrice + buffetPrice).toStringAsFixed(1)} ج',
                      bold: true),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء',
                        style: TextStyle(color: Colors.white54))),
                FilledButton(
                  onPressed: () {
                    state.stopDevice(device);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700),
                  child: const Text('تأكيد'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.receipt_long),
        label: const Text('إنهاء وحساب', style: TextStyle(fontSize: 18)),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _Row(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: bold ? 18 : 14,
                  color: bold ? const Color(0xFF4ade80) : Colors.white)),
        ],
      ),
    );
  }
}
