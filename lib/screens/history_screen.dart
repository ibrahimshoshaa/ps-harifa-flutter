import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import 'archive_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final history = state.history.reversed.toList();
    final totalTime = state.history.fold(0.0, (s, h) => s + (h['time_cost'] ?? 0));
    final totalBuffet = state.history.fold(0.0, (s, h) => s + (h['buffet_cost'] ?? 0));

    return Scaffold(
      backgroundColor: const Color(0xFF0b0e14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0b0e14),
        title: const Text('سجلات اليوم',
            style: TextStyle(color: Color(0xFF38bdf8), fontWeight: FontWeight.bold)),
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu, color: Colors.white54),
            tooltip: 'الأرشيف الشامل',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ArchiveScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary card
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1c2128),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF38bdf8).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SumTile('🎮 اللعب', totalTime),
                Container(width: 1, height: 40, color: Colors.white12),
                _SumTile('🥤 البوفيه', totalBuffet),
                Container(width: 1, height: 40, color: Colors.white12),
                _SumTile('💰 الإجمالي', totalTime + totalBuffet, green: true),
              ],
            ),
          ),

          // History list
          Expanded(
            child: history.isEmpty
                ? const Center(
                    child: Text('لا يوجد سجلات اليوم',
                        style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: history.length,
                    itemBuilder: (ctx, i) => _HistoryTile(record: history[i]),
                  ),
          ),

          // Archive button
          if (state.history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => _confirmArchive(context, state),
                  icon: const Icon(Icons.archive),
                  label: const Text('أرشفة وتصفير اليوم'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
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

  void _confirmArchive(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1c2128),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('أرشفة اليوم؟',
            style: TextStyle(color: Color(0xFF38bdf8))),
        content: const Text(
            'هيتحفظ في الأرشيف الشامل وبعدين هيتمسح من السجلات',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await state.archiveAndClear();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('✅ تم الأرشفة بنجاح'),
                  backgroundColor: Colors.green,
                ));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.purple.shade700),
            child: const Text('أرشفة'),
          ),
        ],
      ),
    );
  }
}

class _SumTile extends StatelessWidget {
  final String label;
  final double value;
  final bool green;
  const _SumTile(this.label, this.value, {this.green = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        const SizedBox(height: 4),
        Text('${value.toStringAsFixed(1)} ج',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: green ? const Color(0xFF4ade80) : Colors.white)),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> record;
  const _HistoryTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1c2128),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(record['name'] ?? 'جهاز',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${record['duration']} | ${record['play_mode'] == 'multi' ? 'مالتي' : 'عادي'}',
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Text('${(record['total'] ?? 0).toStringAsFixed(1)} ج',
            style: const TextStyle(
                color: Color(0xFF4ade80), fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _DetailRow('🎮 اللعب', '${(record['time_cost'] ?? 0).toStringAsFixed(1)} ج'),
                _DetailRow('🥤 البوفيه', '${(record['buffet_cost'] ?? 0).toStringAsFixed(1)} ج'),
                if ((record['orders'] as Map?)?.isNotEmpty == true) ...[
                  const Divider(color: Colors.white12),
                  ...(record['orders'] as Map).entries.map((e) =>
                      _DetailRow('  • ${e.key}', 'x${e.value}')),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}
