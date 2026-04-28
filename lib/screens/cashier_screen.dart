import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/device_card.dart';
import '../models/device.dart';
import 'device_detail_screen.dart';

class CashierScreen extends StatelessWidget {
  const CashierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0b0e14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0b0e14),
        elevation: 0,
        title: const Text(
          '⚡ الحريفة PlayStation',
          style: TextStyle(
            color: Color(0xFF38bdf8),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: () => context.read<AppState>().logout(),
            tooltip: 'خروج',
          ),
        ],
      ),
      body: Column(
        children: [
          // كاشير badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: Colors.orange.withOpacity(0.1),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, color: Colors.orange, size: 16),
                SizedBox(width: 6),
                Text('وضع الكاشير',
                    style: TextStyle(color: Colors.orange, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                itemCount: state.devices.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (ctx, i) {
                  final d = state.devices[i];
                  return DeviceCard(
                    device: d,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DeviceDetailScreen(device: d)),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
