import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../database/db_helper.dart';
import '../models/sapi_model.dart';
import '../models/pengukuran_model.dart';
import '../utils/app_theme.dart';
import 'history_detail_sheet.dart';

class HistoryTanggalScreen extends StatefulWidget {
  final SapiModel sapi;

  const HistoryTanggalScreen({
    super.key,
    required this.sapi,
  });

  @override
  State<HistoryTanggalScreen> createState() => _HistoryTanggalScreenState();
}

class _HistoryTanggalScreenState extends State<HistoryTanggalScreen> {
  List<PengukuranModel> _daftarPengukuran = [];
  bool _isLoading = true;

  final Color primaryGreen = const Color(0xFF004D34);
  final Color accentGreen = const Color(0xFF00A76E);
  final Color labelGreen = const Color(0xFF005C3A);
  final Color lightGreenBg = const Color(0xFFEAF8F5);

  @override
  void initState() {
    super.initState();
    _loadPengukuran();
  }

  Future<void> _loadPengukuran() async {
    final data = await DBHelper.instance.getPengukuranBySapi(widget.sapi.id!);

    data.sort((a, b) {
      final dateA = DateTime.tryParse(a.tanggal) ?? DateTime(2000);
      final dateB = DateTime.tryParse(b.tanggal) ?? DateTime(2000);
      return dateA.compareTo(dateB);
    });

    setState(() {
      _daftarPengukuran = data;
      _isLoading = false;
    });
  }

  String _formatTanggal(String tanggal) {
    try {
      final date = DateTime.parse(tanggal);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return tanggal;
    }
  }

  Future<void> _deleteSapi() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Sapi?',
          style: TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Semua riwayat ${widget.sapi.namaSapi} juga akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: accentGreen)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await DBHelper.instance.deleteSapi(widget.sapi.id!);

    if (!mounted) return;
    showStyledSnackBar(context, 'Data sapi berhasil dihapus');
    Navigator.pop(context);
  }

  Future<void> _deletePengukuran(PengukuranModel item) async {
    if (item.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Riwayat?',
          style: TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Hapus riwayat tanggal ${_formatTanggal(item.tanggal)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: accentGreen)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await DBHelper.instance.deletePengukuran(item.id!);
    await _loadPengukuran();

    if (!mounted) return;
    showStyledSnackBar(context, 'Riwayat berhasil dihapus');
  }

  List<PengukuranModel> get _sortedPengukuran {
    final sorted = List<PengukuranModel>.from(_daftarPengukuran);
    sorted.sort((a, b) => DateTime.parse(a.tanggal).compareTo(DateTime.parse(b.tanggal)));
    return sorted;
  }

  double get _minBobot {
    return _sortedPengukuran.map((e) => e.bobotSekarang).reduce((a, b) => a < b ? a : b);
  }

  double get _maxBobot {
    return _sortedPengukuran.map((e) => e.bobotSekarang).reduce((a, b) => a > b ? a : b);
  }

  List<int> _labelIndices(int total) {
    if (total <= 5) return List.generate(total, (i) => i);
    final step = (total / 5).ceil();
    final indices = <int>{0};
    for (int i = 1; i < 5; i++) {
      indices.add((step * i).clamp(0, total - 1));
    }
    final result = indices.toList()..sort();
    return result;
  }

  void _openDetailSheet(PengukuranModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HistoryDetailSheet(
        sapi: widget.sapi,
        pengukuran: item,
      ),
    );
  }

  Widget _grafikPertumbuhanCard() {
    final sorted = _sortedPengukuran;
    if (sorted.length < 2) return const SizedBox();
    final labels = _labelIndices(sorted.length);
    final spots = List.generate(
      sorted.length,
      (index) => FlSpot(index.toDouble(), sorted[index].bobotSekarang),
    );
    final range = _maxBobot - _minBobot;
    final yInterval = range <= 100 ? 20.0 : (range <= 200 ? 50.0 : 100.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grafik Pertumbuhan Sapi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: labelGreen,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 260,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (sorted.length - 1).toDouble(),
                minY: _minBobot - 20,
                maxY: _maxBobot + 40,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= sorted.length) return const SizedBox();
                        if (!labels.contains(i)) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('dd/MM').format(
                              DateTime.parse(sorted[i].tanggal),
                            ),
                            style: const TextStyle(fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: yInterval,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 11),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    barWidth: 4,
                    color: accentGreen,
                    dotData: const FlDotData(show: true),
                    spots: spots,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(sorted.length, (index) {
              final item = sorted[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      _formatTanggal(item.tanggal),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'BB: ${item.bobotSekarang.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.sapi.namaSapi,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _deleteSapi,
            icon: const Icon(Icons.delete_outline, color: Colors.white),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _daftarPengukuran.isEmpty
              ? const Center(child: Text('Belum ada riwayat pengukuran.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tanggal Pengukuran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: labelGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: _daftarPengukuran.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: lightGreenBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.calendar_month,
                                color: accentGreen,
                              ),
                              title: Text(
                                _formatTanggal(item.tanggal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'BB: ${item.bobotSekarang.toStringAsFixed(1)} kg',
                                style: TextStyle(
                                  color: primaryGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.keyboard_arrow_up,
                                    color: primaryGreen,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deletePengukuran(item),
                                  ),
                                ],
                              ),
                              onTap: () => _openDetailSheet(item),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      _grafikPertumbuhanCard(),
                    ],
                  ),
                ),
    );
  }
}