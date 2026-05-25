import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../database/db_helper.dart';
import '../models/sapi_model.dart';
import '../models/pengukuran_model.dart';
import '../utils/calculator.dart';
import '../utils/app_theme.dart';

class InputSapiScreen extends StatefulWidget {
  const InputSapiScreen({super.key});

  @override
  State<InputSapiScreen> createState() => _InputSapiScreenState();
}

class _InputSapiScreenState extends State<InputSapiScreen> {
  final _namaController = TextEditingController();
  final _lingkarDadaController = TextEditingController();
  final _targetBobotController = TextEditingController(text: '750');

  DateTime _tanggal = DateTime.now();

  double? _bobotSekarang;
  double? _estimasiPakan;
  double? _targetBobot;
  double? _sisaBobot;
  double? _estimasiBulan;
  DateTime? _tanggalPanen;

  bool _sudahHitungBobot = false;
  bool _sudahHitungTarget = false;

  // Palet warna sesuai gambar UI
  final Color primaryGreen = const Color(0xFF004D34); // Hijau tua Appbar/Header
  final Color accentGreen = const Color(0xFF00A76E);  // Hijau terang Tombol/Icon
  final Color labelGreen = const Color(0xFF005C3A);   // Hijau teks label
  final Color fieldColor = const Color(0xFFF2F2F2);   // Abu-abu input field
  final Color lightGreenBg = const Color(0xFFEAF8F5); // Background hijau muda hasil

  @override
  void dispose() {
    _namaController.dispose();
    _lingkarDadaController.dispose();
    _targetBobotController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _tanggal = picked;
      });
    }
  }

  void _hitungBobot() {
    final nama = _namaController.text.trim();
    final ld = double.tryParse(_lingkarDadaController.text) ?? 0;

    if (nama.isEmpty) {
      showStyledSnackBar(context, 'Nama sapi wajib diisi');
      return;
    }

    if (ld <= 0) {
      showStyledSnackBar(context, 'Lingkar dada wajib diisi');
      return;
    }

    // Menggunakan ld untuk rumus kalkulator bawaanmu
    final bobot = hitungBobotSapi(ld); 
    final pakan = hitungEstimasiPakan(bobot);

    setState(() {
      _bobotSekarang = bobot;
      _estimasiPakan = pakan;

      _sudahHitungBobot = true;
      _sudahHitungTarget = false;

      _targetBobot = null;
      _sisaBobot = null;
      _estimasiBulan = null;
      _tanggalPanen = null;
    });
  }

  void _hitungTarget() {
    if (_bobotSekarang == null) return;

    final target = double.tryParse(_targetBobotController.text) ?? 0;

    if (target <= 0) {
      showStyledSnackBar(context, 'Target bobot wajib diisi');
      return;
    }

    final sisa = hitungSisaBobot(_bobotSekarang!, target);
    final bulan = hitungWaktuPanenBulan(_bobotSekarang!, target);
    final tanggalPanen = hitungTanggalPanen(bulan);

    setState(() {
      _targetBobot = target;
      _sisaBobot = sisa;
      _estimasiBulan = bulan;
      _tanggalPanen = tanggalPanen;
      _sudahHitungTarget = true;
    });
  }

  Future<void> _simpan() async {
    if (!_sudahHitungBobot || !_sudahHitungTarget) {
      showStyledSnackBar(context, 'Hitung bobot dan target dulu');
      return;
    }

    final nama = _namaController.text.trim();
    final ld = double.tryParse(_lingkarDadaController.text) ?? 0;

    final sapi = SapiModel(
      namaSapi: nama,
      tanggalMasuk: DateFormat('yyyy-MM-dd').format(_tanggal),
    );

    final sapiId = await DBHelper.instance.insertSapi(sapi);

    final pengukuran = PengukuranModel(
      sapiId: sapiId,
      tanggal: DateFormat('yyyy-MM-dd').format(_tanggal),
      lingkarDada: ld,
      bobotSekarang: _bobotSekarang!,
      estimasiPakan: _estimasiPakan!,
      targetBobot: _targetBobot!,
      sisaBobot: _sisaBobot!,
      adg: adgRealistis,
      estimasiBulan: _estimasiBulan!,
      tanggalPanen: DateFormat('yyyy-MM-dd').format(_tanggalPanen!),
    );

    await DBHelper.instance.insertPengukuran(pengukuran);

    if (!mounted) return;

    showStyledSnackBar(context, 'Data berhasil disimpan');

    setState(() {
      _namaController.clear();
      _lingkarDadaController.clear();
      _targetBobotController.text = '750';

      _bobotSekarang = null;
      _estimasiPakan = null;
      _targetBobot = null;
      _sisaBobot = null;
      _estimasiBulan = null;
      _tanggalPanen = null;

      _sudahHitungBobot = false;
      _sudahHitungTarget = false;
      _tanggal = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Input Sapi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryGreen,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        // PADDING BAWAH DIUBAH MENJADI 160 AGAR BISA DI-SCROLL MELEWATI NAVBAR
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
        child: Column(
          children: [
            _inputCard(),
            const SizedBox(height: 24),
            
            // Tombol Hitung ditaruh di luar Card sesuai gambar UI
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _hitungBobot,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Hitung',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            if (_sudahHitungBobot) ...[
              const SizedBox(height: 20),
              _hasilBobotCard(),
              const SizedBox(height: 16),
              _targetCard(),
            ],

            if (_sudahHitungTarget) ...[
              const SizedBox(height: 16),
              _hasilTargetCard(),
              const SizedBox(height: 16),
              _grafikPrediksiCard(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _simpan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan Data Sapi', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _inputCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add, color: accentGreen, size: 28),
              const SizedBox(width: 8),
              Text(
                'Input Data Sapi',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: labelGreen),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildLabel('ID/Nama Sapi'),
          const SizedBox(height: 8),
          _buildTextField(controller: _namaController, hintText: 'A001Bima'),
          const SizedBox(height: 18),

          _buildLabel('Tanggal'),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pilihTanggal,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: fieldColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                DateFormat('dd/MM/yyyy').format(_tanggal),
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Lingkar Dada (cm)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _lingkarDadaController,
                hintText: '0',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: labelGreen,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.black38),
        filled: true,
        fillColor: fieldColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // --- Hasil Bobot dengan style seperti halaman Update ---
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
            child: _infoItem(
              title: 'Estimasi Bobot',
              value: '${_bobotSekarang!.toStringAsFixed(0)} kg',
            ),
          ),
          Container(width: 1, height: 40, color: accentGreen.withOpacity(0.3)),
          Expanded(
            child: _infoItem(
              title: 'Estimasi Pakan',
              value: '${_estimasiPakan!.toStringAsFixed(1)} Kg',
            ),
          ),
        ],
      ),
    );
  }

  Widget _targetCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Target Bobot Panen (kg)'),
            const SizedBox(height: 8),
            _buildTextField(controller: _targetBobotController, hintText: '750', keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _hitungTarget,
                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Hitung Target Panen', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
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
          const Text('Estimasi Panen', style: TextStyle(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_estimasiBulan!.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, height: 1.0),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'Bulan\nRealistis',
                  style: TextStyle(color: Colors.white, fontSize: 16, height: 1.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Target Bobot', style: TextStyle(color: Colors.white70)),
              Text('${_targetBobot!.toStringAsFixed(1)} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sisa Bobot', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              Text('${_sisaBobot!.toStringAsFixed(1)} kg', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tanggal Panen', style: TextStyle(color: Colors.white70)),
              Text(DateFormat('dd/MM/yyyy').format(_tanggalPanen!), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _grafikPrediksiCard() {
    final data = prediksiBobot6Bulan(_bobotSekarang!);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prediksi Pertumbuhan 6 Bulan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryGreen)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 1, maxX: 6,
                  minY: _bobotSekarang! - 20, maxY: data.last + 40,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, interval: 1,
                        getTitlesWidget: (value, meta) => Text('+${value.toInt()}B', style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, interval: 100, reservedSize: 35, getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(fontSize: 11))),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true, barWidth: 4, color: accentGreen,
                      dotData: const FlDotData(show: true),
                      spots: List.generate(data.length, (index) => FlSpot((index + 1).toDouble(), data[index])),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem({required String title, required String value}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryGreen)),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(color: accentGreen, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

}