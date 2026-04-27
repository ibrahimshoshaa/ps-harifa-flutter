import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../services/app_state.dart';

class DeviceCard extends StatelessWidget {
  final PSDevice device;
  final VoidCallback onTap;

  const DeviceCard({super.key, required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final timePrice = device.calculateTimePrice(state.prices);
    final buffetPrice = device.getBuffetPrice(state.menu);
    final total = timePrice + buffetPrice;

    Color borderColor;
    if (device.isPaused) {
      borderColor = Colors.amber;
    } else if (device.isActive) {
      borderColor = const Color(0xFF38bdf8);
    } else {
      borderColor = Colors.white.withOpacity(0.1);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: const Color(0xFF1c2128),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: device.isActive ? 1.5 : 1),
          boxShadow: device.isActive
              ? [
                  BoxShadow(
                    color: (device.isPaused ? Colors.amber : const Color(0xFF38bdf8))
                        .withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    device.displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: device.mode == 'multi',
                    activeColor: const Color(0xFF38bdf8),
                    onChanged: (v) {
                      device.mode = v ? 'multi' : 'normal';
                      state.saveData();
                    },
                  ),
                ),
              ],
            ),

            // Timer
            _PulsingTimer(device: device),

            // Prices
            Column(
              children: [
                Text(
                  'لعب: ${timePrice.toStringAsFixed(1)} | بوفيه: ${buffetPrice.toStringAsFixed(1)}',
                  style: TextStyle(
                      fontSize: 10, color: Colors.white.withOpacity(0.6)),
                ),
                const SizedBox(height: 2),
                Text(
                  '${total.toStringAsFixed(1)} ج.م',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4ade80),
                  ),
                ),
              ],
            ),

            // Buttons
            if (device.status == 'متاح')
              _StartButton(device: device)
            else
              _ActiveButtons(device: device),
          ],
        ),
      ),
    );
  }
}

class _PulsingTimer extends StatefulWidget {
  final PSDevice device;
  const _PulsingTimer({required this.device});

  @override
  State<_PulsingTimer> createState() => _PulsingTimerState();
}

class _PulsingTimerState extends State<_PulsingTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.device.isActive;
    final isPaused = widget.device.isPaused;

    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, child) => Transform.scale(
        scale: isActive && !isPaused ? _anim.value : 1.0,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          widget.device.timerText,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: isPaused ? Colors.amber : Colors.white,
            shadows: isActive
                ? [
                    Shadow(
                      color: (isPaused ? Colors.amber : const Color(0xFF38bdf8))
                          .withOpacity(0.5),
                      blurRadius: 8,
                    )
                  ]
                : [],
          ),
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final PSDevice device;
  const _StartButton({required this.device});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => context.read<AppState>().startDevice(device, 'normal'),
        icon: const Icon(Icons.play_arrow, size: 18),
        label: const Text('بدء اللعب', style: TextStyle(fontSize: 13)),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class _ActiveButtons extends StatelessWidget {
  final PSDevice device;
  const _ActiveButtons({required this.device});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Row(
      children: [
        // Pause/Resume
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: IconButton(
            key: ValueKey(device.isPaused),
            icon: Icon(
              device.isPaused ? Icons.play_circle_fill : Icons.pause_circle_filled,
              color: device.isPaused ? Colors.amber : const Color(0xFF38bdf8),
              size: 30,
            ),
            onPressed: () => state.togglePause(device),
            tooltip: device.isPaused ? 'استكمال' : 'إيقاف مؤقت',
          ),
        ),
        // Stop
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _showStopDialog(context, state),
            icon: const Icon(Icons.receipt, size: 16),
            label: const Text('إنهاء', style: TextStyle(fontSize: 13)),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  void _showStopDialog(BuildContext context, AppState state) {
    final timePrice = device.calculateTimePrice(state.prices);
    final buffetPrice = device.getBuffetPrice(state.menu);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1c2128),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('إنهاء ${device.displayName}',
            style: const TextStyle(color: Color(0xFF38bdf8))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InfoRow('🎮 اللعب', '${timePrice.toStringAsFixed(1)} ج'),
            _InfoRow('🥤 البوفيه', '${buffetPrice.toStringAsFixed(1)} ج'),
            const Divider(color: Colors.white24),
            _InfoRow('💰 الإجمالي',
                '${(timePrice + buffetPrice).toStringAsFixed(1)} ج',
                highlight: true),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          FilledButton(
            onPressed: () {
              state.stopDevice(device);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('تأكيد الإنهاء'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _InfoRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value,
              style: TextStyle(
                  fontSize: highlight ? 18 : 14,
                  fontWeight:
                      highlight ? FontWeight.bold : FontWeight.normal,
                  color: highlight ? const Color(0xFF4ade80) : Colors.white)),
        ],
      ),
    );
  }
}
