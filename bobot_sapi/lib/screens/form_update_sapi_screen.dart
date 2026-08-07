import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../database/db_helper.dart';
import '../models/sapi_model.dart';
import '../models/pengukuran_model.dart';
import '../utils/calculator.dart';
import '../utils/app_theme.dart';

class FormUpdateSapiScreen extends StatefulWidget {
  final SapiModel sapi;
  const FormUpdateSapiScreen({super.key, required this.sapi});

  @override
  State<FormUpdateSapiScreen> createState() => _FormUpdateSapiScreenState();
}

class _FormUpdateSapiScreenState extends State<FormUpdateSapiScreen> {
  final _lingkarDadaController = TextEditingController();
  final _panjangBadanController = TextEditingController();
  final _goalHariController = TextEditingController();

  DateTime _tanggal = DateTime.now();

  double? _bobotSekarang;
  double? _estimasiPakan;
  double? _targetBobot;
  double? _sisaBobot;
  double? _estimasiBulan;
  int? _goalHari;
  DateTime? _tanggalPanen;

  bool _sudahHitungBobot = false;
  bool _sudahHitungTarget = false;

  // History Terakhir
  PengukuranModel? _lastPengukuran;
  bool _isLoadingHistory = true;

  final Color primaryGreen = const Color(0xFF004D34);
  final Color accentGreen = const Color(0xFF00A76E);
  final Color fieldColor = const Color(0xFFF2F2F2);
  final Color labelGreen = const Color(0xFF005C3A);

  @override
  void initState() {
    super.initState();
    _loadHistoryTerakhir();
  }

  @override
  void dispose() {
    _lingkarDadaController.dispose();
    _panjangBadanController.dispose();
    _goalHariController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryTerakhir() async {
    final list = await DBHelper.instance.getPengukuranBySapi(widget.sapi.id!);
    if (list.isNotEmpty) {
      list.sort((a, b) {
        final dateA = DateTime.tryParse(a.tanggal) ?? DateTime(2000);
        final dateB = DateTime.tryParse(b.tanggal) ?? DateTime(2000);
        return dateB.compareTo(dateA); // Urutkan dari yang paling baru
      });

      final last = list.first;

      setState(() {
        _lastPengukuran = last;
        _isLoadingHistory = false;
      });

      // Hitung sisa hari otomatis jika ada data panen sebelumnya
      _hitungSisaHariOtomatis(last);
    } else {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  void _hitungSisaHariOtomatis(PengukuranModel last) {
    try {
      final tglPanenAwal = DateTime.parse(last.tanggalPanen);
      
      // Hitung selisih antara Tanggal Panen Awal dengan Tanggal Pengukuran Baru (_tanggal)
      final sisaHari = tglPanenAwal.difference(_tanggal).inDays;

      if (sisaHari > 0) {
        _goalHariController.text = sisaHari.toString();
      } else {
        _goalHariController.text = '0';
      }
    } catch (_) {
      // Jika format tanggal bermasalah, kosongkan controller
    }
  }

  String _formatTanggal(String tanggal) {
    try {
      final date = DateTime.parse(tanggal);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return tanggal;
    }
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

      // Recalculate sisa hari jika tanggal pengukuran diubah oleh user
      if (_lastPengukuran != null) {
        _hitungSisaHariOtomatis(_lastPengukuran!);
      }
    }
  }

  void _hitungBobot() {
    final ld = double.tryParse(_lingkarDadaController.text) ?? 0;

    if (ld <= 0) {
      showStyledSnackBar(context, 'Lingkar dada wajib diisi');
      return;
    }

    final bobot = hitungBobotSapi(ld);
    final pakan = hitungEstimasiPakan(bobot);

    setState(() {
      _bobotSekarang = bobot;
      _estimasiPakan = pakan;
      _sudahHitungBobot = true;
      _sudahHitungTarget = false;
    });
  }

  void _hitungTarget() {
    if (_bobotSekarang == null) return;

    final hari = int.tryParse(_goalHariController.text) ?? 0;

    if (hari <= 0) {
      showStyledSnackBar(context, 'Isi goal hari panen terlebih dahulu');
      return;
    }

    final targetDariHari = hitungBobotPanenHari(_bobotSekarang!, hari);
    final tglPanen = hitungTanggalPanenHari(hari, tanggalUkur: _tanggal);

    setState(() {
      _goalHari = hari;
      _targetBobot = targetDariHari;
      _sisaBobot = targetDariHari - _bobotSekarang!;
      _estimasiBulan = hari / 30.0;
      _tanggalPanen = tglPanen;
      _sudahHitungTarget = true;
    });
  }

  Future<void> _simpanUpdate() async {
    if (!_sudahHitungBobot || !_sudahHitungTarget) {
      showStyledSnackBar(context, 'Hitung bobot dan goal panen dulu');
      return;
    }

    final ld = double.tryParse(_lingkarDadaController.text) ?? 0;
    final pb = double.tryParse(_panjangBadanController.text) ?? 0;

    final pengukuran = PengukuranModel(
      sapiId: widget.sapi.id!,
      tanggal: DateFormat('yyyy-MM-dd').format(_tanggal),
      lingkarDada: ld,
      panjangBadan: pb,
      bobotSekarang: _bobotSekarang!,
      estimasiPakan: _estimasiPakan!,
      goalHari: _goalHari ?? 0,
      targetBobot: _targetBobot!,
      sisaBobot: _sisaBobot!,
      adg: adgRealistis,
      estimasiBulan: _estimasiBulan!,
      tanggalPanen: DateFormat('yyyy-MM-dd').format(_tanggalPanen!),
    );

    await DBHelper.instance.insertPengukuran(pengukuran);

    if (!mounted) return;
    showStyledSnackBar(context, 'Update pengukuran berhasil disimpan');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Update ${widget.sapi.namaSapi}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card History Terakhir
            _buildHistoryTerakhirCard(),
            const SizedBox(height: 24),

            _buildLabel('Tanggal Pengukuran Baru'),
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
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Input Lingkar Dada & Panjang Sapi
            Row(
              children: [
                Expanded(
                  child: Column(
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Panjang Sapi (cm)'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _panjangBadanController,
                        hintText: '0',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tombol Hitung
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

            // Hasil Hitung & Goal Panen
            if (_sudahHitungBobot) ...[
              const SizedBox(height: 20),
              _hasilBobotCard(),
              const SizedBox(height: 16),
              _goalPanenCard(),
            ],

            // Target, Grafik & Simpan
            if (_sudahHitungTarget) ...[
              const SizedBox(height: 16),
              _hasilTargetCard(),
              const SizedBox(height: 16),
              _grafikPrediksiCard(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _simpanUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Simpan Update',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTerakhirCard() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_lastPengukuran == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          children: const [
            Icon(Icons.info_outline, color: Colors.amber),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sapi ini belum memiliki catatan pengukuran sebelumnya.',
                style: TextStyle(color: Colors.black87, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final p = _lastPengukuran!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: primaryGreen, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Pengukuran Terakhir',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatTanggal(p.tanggal),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _historySubItem(
                  'Lingkar Dada',
                  '${p.lingkarDada.toStringAsFixed(0)} cm',
                ),
              ),
              Expanded(
                child: _historySubItem(
                  'Panjang Sapi',
                  '${p.panjangBadan.toStringAsFixed(0)} cm',
                ),
              ),
              Expanded(
                child: _historySubItem(
                  'Target Bobot',
                  '${p.targetBobot.toStringAsFixed(0)} kg',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _historySubItem(
                  'Bobot Terakhir',
                  '${p.bobotSekarang.toStringAsFixed(0)} kg',
                ),
              ),
              Expanded(
                flex: 2,
                child: _historySubItem(
                  'Target Panen (${p.goalHari} Hr)',
                  _formatTanggal(p.tanggalPanen),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _historySubItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: labelGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
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

  Widget _hasilBobotCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F5),
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

  Widget _goalPanenCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Goal Panen (Hari)'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _goalHariController,
            hintText: 'Contoh: 120',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _hitungTarget,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Hitung Target Panen',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
          const Text('Estimasi Panen', style: TextStyle(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_targetBobot!.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Kg\ndalam $_goalHari Hari',
                  style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.2),
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
              const Text('Bobot Awal', style: TextStyle(color: Colors.white70)),
              Text(
                '${_bobotSekarang!.toStringAsFixed(1)} kg',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tanggal Panen', style: TextStyle(color: Colors.white70)),
              Text(
                DateFormat('dd/MM/yyyy').format(_tanggalPanen!),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _grafikPrediksiCard() {
    final List<double> rawData = prediksiBobot6Bulan(_bobotSekarang ?? 0);
    final List<FlSpot> spots = List.generate(
      rawData.length,
      (i) => FlSpot((i + 1).toDouble(), rawData[i]),
    );

    final double minY = (_bobotSekarang ?? 0) - 20;
    final double maxY = (rawData.isNotEmpty ? rawData.last : 100) + 40;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prediksi Pertumbuhan 6 Bulan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryGreen),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: 6,
                minY: minY < 0 ? 0 : minY,
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('+${value.toInt()}B', style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 100,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(fontSize: 11)),
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
        ],
      ),
    );
  }

  Widget _infoItem({required String title, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryGreen),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(color: accentGreen, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}