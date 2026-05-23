// lib/screens/history_sapi_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/sapi.dart';
import '../utils/app_theme.dart';
import '../utils/storage_service.dart';

class HistorySapiScreen extends StatefulWidget {
  final String sapiId;
  const HistorySapiScreen({super.key, required this.sapiId});

  @override
  State<HistorySapiScreen> createState() => _HistorySapiScreenState();
}

class _HistorySapiScreenState extends State<HistorySapiScreen> {
  Sapi? _sapi;
  int? _selectedIndex; // index pengukuran yang diklik di grafik

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await StorageService.loadSapi();
    final sapi = list.firstWhere((s) => s.id == widget.sapiId);
    setState(() {
      _sapi = sapi;
      _selectedIndex = sapi.riwayat.isNotEmpty ? sapi.riwayat.length - 1 : null;
    });
  }

  Future<void> _hapusPengukuran(String pengukuranId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengukuran'),
        content: const Text('Yakin ingin menghapus data pengukuran ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService.hapusPengukuran(widget.sapiId, pengukuranId);
      _load();
    }
  }

  PengukuranSapi? get _pengukuranDipilih {
    if (_sapi == null || _selectedIndex == null) return null;
    if (_selectedIndex! >= _sapi!.riwayat.length) return null;
    return _sapi!.riwayat[_selectedIndex!];
  }

  @override
  Widget build(BuildContext context) {
    if (_sapi == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final sapi = _sapi!;
    final riwayat = sapi.riwayat;

    return Scaffold(
      appBar: AppBar(title: const Text('Logo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header nama sapi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.putih,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.add, color: AppColors.hijau),
                      const SizedBox(width: 8),
                      Text(
                        sapi.idNama,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gelap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Riwayat Pengukuran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gelap,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (riwayat.isEmpty)
                    const Text(
                      'Belum ada riwayat pengukuran',
                      style: TextStyle(color: AppColors.teksAbu),
                    )
                  else
                    ...riwayat.asMap().entries.map((entry) {
                      final i = entry.key;
                      final p = entry.value;
                      final isSelected = _selectedIndex == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.hijauCard
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.hijauText
                                  : Colors.grey.shade200,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('dd MMMM yyyy', 'id_ID')
                                          .format(p.tanggal),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.gelap,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Pesimis: ${p.bulanPesimis} Bulan | Optimis: ${p.bulanOptimis} Bulan',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.teksAbu,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${p.estimasiBobot.toStringAsFixed(1)} kg',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.gelap,
                                    ),
                                  ),
                                  Text(
                                    'Target: ${p.targetBobot.toInt()}kg',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.hijauText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.merah, size: 20),
                                onPressed: () => _hapusPengukuran(p.id),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Grafik Pertumbuhan
            if (riwayat.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.putih,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.trending_up,
                            color: AppColors.hijauText, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Grafik Pertumbuhan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gelap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap titik grafik untuk lihat detail',
                      style: TextStyle(fontSize: 12, color: AppColors.teksAbu),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _buildChart(riwayat),
                    ),
                  ],
                ),
              ),

            // Estimasi bobot & pakan dari pengukuran yang dipilih
            if (_pengukuranDipilih != null) ...[
              const SizedBox(height: 16),
              _buildEstimasiCard(_pengukuranDipilih!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<PengukuranSapi> riwayat) {
    final spots = riwayat.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.estimasiBobot);
    }).toList();

    final maxY = riwayat.map((p) => p.estimasiBobot).reduce((a, b) => a > b ? a : b);
    final minY = riwayat.map((p) => p.estimasiBobot).reduce((a, b) => a < b ? a : b);
    final yPad = (maxY - minY) * 0.2 + 20;

    return LineChart(
      LineChartData(
        minY: (minY - yPad).clamp(0, double.infinity),
        maxY: maxY + yPad,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: AppColors.teksAbu),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= riwayat.length) return const SizedBox();
                final p = riwayat[idx];
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('dd/MM').format(p.tanggal),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.teksAbu),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchCallback: (event, response) {
            if (response?.lineBarSpots != null &&
                response!.lineBarSpots!.isNotEmpty) {
              final idx = response.lineBarSpots!.first.spotIndex;
              setState(() => _selectedIndex = idx);
            }
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.hijau,
            getTooltipItems: (spots) => spots.map((s) {
              return LineTooltipItem(
                '${s.y.toStringAsFixed(1)} kg',
                const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.hijau,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, _, idx) {
                final isSelected = idx == _selectedIndex;
                return FlDotCirclePainter(
                  radius: isSelected ? 7 : 5,
                  color: isSelected ? AppColors.hijau : AppColors.hijauText,
                  strokeWidth: isSelected ? 2 : 0,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.hijau.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimasiCard(PengukuranSapi p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.hijauCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.hijauMuda),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p.estimasiBobot.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gelap,
                      ),
                    ),
                    const Text(
                      'Estimasi Bobot',
                      style: TextStyle(
                          color: AppColors.hijauText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.hijauMuda),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${p.estimasiPakan.toStringAsFixed(1)} Kg',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gelap,
                        ),
                      ),
                      const Text(
                        'Estimasi Pakan',
                        style: TextStyle(
                            color: AppColors.hijauText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Estimasi Panen',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.gelap),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.hijau,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: '${p.bulanOptimis}',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const TextSpan(
                    text: 'Bulan',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ]),
              ),
              Text(
                p.statusPanen,
                style: const TextStyle(color: AppColors.hijauMuda),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
