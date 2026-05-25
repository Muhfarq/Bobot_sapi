import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/sapi_model.dart';
import '../models/pengukuran_model.dart';
import '../utils/calculator.dart';

class HistoryDetailSheet extends StatelessWidget {
  final SapiModel sapi;
  final PengukuranModel pengukuran;
  const HistoryDetailSheet({
    super.key,
    required this.sapi,
    required this.pengukuran,
  });

  final Color primaryGreen = const Color(0xFF004D34);
  final Color accentGreen = const Color(0xFF00A76E);
  final Color labelGreen = const Color(0xFF005C3A);
  final Color lightGreenBg = const Color(0xFFEAF8F5);

  String _formatTanggal(String tanggal) {
    try {
      final date = DateTime.parse(tanggal);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return tanggal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = prediksiBobot6Bulan(pengukuran.bobotSekarang);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Detail History',
                  style: TextStyle(
                    color: primaryGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _detailPengukuranCard(),
                const SizedBox(height: 16),
                _hasilBobotCard(),
                const SizedBox(height: 16),
                _hasilTargetCard(),
                const SizedBox(height: 16),
                _grafikPrediksiCard(data),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailPengukuranCard() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Detail Pengukuran'),
          const SizedBox(height: 12),
          _infoRow('Nama Sapi', sapi.namaSapi),
          _infoRow('Tanggal', _formatTanggal(pengukuran.tanggal)),
          _infoRow(
            'Lingkar Dada',
            '${pengukuran.lingkarDada.toStringAsFixed(1)} cm',
          ),
          _infoRow(
            'ADG',
            '${pengukuran.adg.toStringAsFixed(1)} kg/hari',
          ),
        ],
      ),
    );
  }

  Widget _hasilBobotCard() {
    return Container(
      decoration: BoxDecoration(
        color: lightGreenBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentGreen.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _centerInfo(
              '${pengukuran.bobotSekarang.toStringAsFixed(0)} kg',
              'Estimasi Bobot',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: accentGreen.withOpacity(0.3),
          ),
          Expanded(
            child: _centerInfo(
              '${pengukuran.estimasiPakan.toStringAsFixed(1)} Kg',
              'Estimasi Pakan',
            ),
          ),
        ],
      ),
    );
  }

  Widget _hasilTargetCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimasi Panen',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pengukuran.estimasiBulan.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'Bulan\nRealistis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 8),
          _whiteRow(
            'Target Bobot',
            '${pengukuran.targetBobot.toStringAsFixed(1)} kg',
          ),
          const SizedBox(height: 4),
          _whiteRow(
            'Sisa Bobot',
            '${pengukuran.sisaBobot.toStringAsFixed(1)} kg',
            small: true,
          ),
          const SizedBox(height: 4),
          _whiteRow(
            'Tanggal Panen',
            _formatTanggal(pengukuran.tanggalPanen),
          ),
        ],
      ),
    );
  }

  Widget _grafikPrediksiCard(List<double> data) {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Prediksi Pertumbuhan 6 Bulan'),
          const SizedBox(height: 20),
          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: 6,
                minY: pengukuran.bobotSekarang - 20,
                maxY: data.last + 40,
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
                        if (value < 1 || value > 6) return const SizedBox();
                        return Text(
                          '+${value.toInt()}B',
                          style: const TextStyle(fontSize: 11),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 100,
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
                    spots: List.generate(
                      data.length,
                      (index) => FlSpot(
                        (index + 1).toDouble(),
                        data[index],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(data.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '+${index + 1} Bulan',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Text(
                      '${data[index].toStringAsFixed(1)} kg',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
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

  Widget _whiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _title(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: labelGreen,
      ),
    );
  }

  Widget _centerInfo(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: accentGreen,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _whiteRow(String title, String value, {bool small = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: small ? Colors.white54 : Colors.white70,
            fontSize: small ? 12 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: small ? Colors.white70 : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: small ? 12 : 14,
          ),
        ),
      ],
    );
  }
}