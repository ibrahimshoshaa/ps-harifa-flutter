import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});
  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<Map<String, dynamic>> _archives = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // جرب Firebase أول
    final raw = await FirebaseService.get('archives');
    if (raw != null && raw is Map) {
      _archives = raw.values
          .map((v) => Map<String, dynamic>.from(v))
          .toList()
          .reversed
          .toList();
    } else {
      // لو Firebase مش شغال، اقرأ من المحلي
      final prefs = await SharedPreferences.getInstance();
      final local = prefs.getString('local_archives');
      if (local != null) {
        final list = jsonDecode(local) as List;
        _archives = list
            .map((v) => Map<String, dynamic>.from(v))
            .toList()
            .reversed
            .toList();
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final grandTotal = _archives.fold(0.0, (s, a) => s + (a['total_overall'] ?? 0));
    final grandTime = _archives.fold(0.0, (s, a) => s + (a['total_time'] ?? 0));
    final grandBuffet = _archives.fold(0.0, (s, a) => s + (a['total_buffet'] ?? 0));

    return Scaffold(
      backgroundColor: const Color(0xFF0b0e14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0b0e14),
        title: const Text('الأرشيف الشامل',
            style: TextStyle(color: Color(0xFF38bdf8), fontWeight: FontWeight.bold)),
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white54),
              onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38bdf8)))
          : Column(
              children: [
                // Summary
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1c2128),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF38bdf8).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _SumTile('🎮 اللعب', grandTime),
                      Container(width: 1, height: 40, color: Colors.white12),
                      _SumTile('🥤 البوفيه', grandBuffet),
                      Container(width: 1, height: 40, color: Colors.white12),
                      _SumTile('💰 الإجمالي', grandTotal, green: true),
                    ],
                  ),
                ),

                // Reset button
                if (_archives.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _confirmYearlyArchive(context, grandTotal, grandTime, grandBuffet),
                        icon: const Icon(Icons.archive),
                        label: const Text('تصفير وحفظ في الأرشيف السنوي'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),

                // List
                Expanded(
                  child: _archives.isEmpty
                      ? const Center(
                          child: Text('لا يوجد أرشيف',
                              style: TextStyle(color: Colors.white54)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _archives.length,
                          itemBuilder: (ctx, i) =>
                              _ArchiveTile(archive: _archives[i]),
                        ),
                ),
              ],
            ),
    );
  }

  void _confirmYearlyArchive(BuildContext ctx, double total, double time, double buffet) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1c2128),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حفظ في الأرشيف السنوي؟',
            style: TextStyle(color: Color(0xFF38bdf8))),
        content: Text(
            'هيتحفظ إجمالي ${total.toStringAsFixed(1)} ج في الأرشيف السنوي وبعدين يتمسح الأرشيف الشامل',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final entry = {
                'archived_on': DateTime.now().toString(),
                'label': 'أرشيف ${DateTime.now().year}',
                'total_time': time,
                'total_buffet': buffet,
                'total_overall': total,
                'sessions_count': _archives.length,
                'sessions': _archives,
              };
              await FirebaseService.push('yearly_archives', entry);
              await FirebaseService.delete('archives');
              await _load();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('✅ تم حفظ الأرشيف السنوي'),
                  backgroundColor: Colors.green,
                ));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.purple.shade700),
            child: const Text('حفظ وتصفير'),
          ),
        ],
      ),
    );
  }
}

class _ArchiveTile extends StatelessWidget {
  final Map<String, dynamic> archive;
  const _ArchiveTile({required this.archive});

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
        title: Text('وردية: ${archive['date']?.toString().substring(0, 10) ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        trailing: Text('${(archive['total_overall'] ?? 0).toStringAsFixed(1)} ج',
            style: const TextStyle(color: Color(0xFF4ade80), fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _Row('🎮 اللعب', '${(archive['total_time'] ?? 0).toStringAsFixed(1)} ج'),
                _Row('🥤 البوفيه', '${(archive['total_buffet'] ?? 0).toStringAsFixed(1)} ج'),
              ],
            ),
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

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
