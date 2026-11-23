import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../database/db_helper.dart';
import '../models/sapi_model.dart';
import '../models/pengukuran_model.dart';
import '../utils/calculator.dart';
import '../utils/app_theme.dart';
import '../utils/daftar_poel.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/app_text_field.dart';

class InputSapiScreen extends StatefulWidget {
  const InputSapiScreen({super.key});

  @override
  State<InputSapiScreen> createState() => _InputSapiScreenState();
}

class _InputSapiScreenState extends State<InputSapiScreen> {
  final _namaController = TextEditingController();
  final _lingkarDadaController = TextEditingController();
  final _panjangBadanController = TextEditingController();
  final _tinggiGumbaController = TextEditingController();
  final _goalHariController = TextEditingController();
  String? _poel;

  DateTime _tanggal = DateTime.now();

  double? _bobotSekarang;
  double? _estimasiPakan;
  int? _goalHari;
  double? _bobotPanen;
  DateTime? _tanggalPanen;

  bool _sudahHitung = false;

  final Color primaryGreen = const Color(0xFF004D34);
  final Color accentGreen = const Color(0xFF00A76E);
  final Color labelGreen = const Color(0xFF005C3A);
  final Color fieldColor = const Color(0xFFF2F2F2);

  @override
  void dispose() {
    _namaController.dispose();
    _lingkarDadaController.dispose();
    _panjangBadanController.dispose();
    _tinggiGumbaController.dispose();
    _goalHariController.dispose();
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

  void _hitung() {
    final nama = _namaController.text.trim();
    final ld = double.tryParse(_lingkarDadaController.text) ?? 0;
    final pb = double.tryParse(_panjangBadanController.text) ?? 0;
    final tb = double.tryParse(_tinggiGumbaController.text) ?? 0;
    final hari = int.tryParse(_goalHariController.text) ?? 0;

    if (nama.isEmpty) {
      showStyledSnackBar(context, 'Nama sapi wajib diisi');
      return;
    }

    if (ld <= 0 || pb <= 0 || tb <= 0) {
      showStyledSnackBar(context, 'Lingkar dada, panjang badan, dan tinggi gumba wajib diisi dengan benar');
      return;
    }

    if (hari <= 0) {
      showStyledSnackBar(context, 'Goal panen (hari) wajib diisi');
      return;
    }

    final bobotAwal = hitungBobotSapi(ld, pb, tb);
    final pakan = hitungEstimasiPakan(bobotAwal);
    final bobotAkhir = hitungBobotPanenHari(bobotAwal, hari);
    final tglPanen = hitungTanggalPanenHari(hari, tanggalUkur: _tanggal);

    setState(() {
      _bobotSekarang = bobotAwal;
      _estimasiPakan = pakan;
      _goalHari = hari;
      _bobotPanen = bobotAkhir;
      _tanggalPanen = tglPanen;
      _sudahHitung = true;
    });
  }

  Future<void> _simpan() async {
    if (!_sudahHitung) {
      showStyledSnackBar(context, 'Hitung estimasi terlebih dahulu');
      return;
    }

    final nama = _namaController.text.trim();
    final ld = double.tryParse(_lingkarDadaController.text) ?? 0;
    final pb = double.tryParse(_panjangBadanController.text) ?? 0;
    final tb = double.tryParse(_tinggiGumbaController.text) ?? 0;

    final sapi = SapiModel(
      namaSapi: nama,
      tanggalMasuk: DateFormat('yyyy-MM-dd').format(_tanggal),
    );

    final sapiId = await DBHelper.instance.insertSapi(sapi);

    final pengukuran = PengukuranModel(
      sapiId: sapiId,
      tanggal: DateFormat('yyyy-MM-dd').format(_tanggal),
      lingkarDada: ld,
      panjangBadan: pb,
      tinggiGumba: tb,
      poel: _poel ?? '',
      bobotSekarang: _bobotSekarang!,
      estimasiPakan: _estimasiPakan!,
      goalHari: _goalHari!,
      targetBobot: _bobotPanen!,
      sisaBobot: _bobotPanen! - _bobotSekarang!,
      adg: adgRealistis,
      estimasiBulan: _goalHari! / 30.0,
      tanggalPanen: DateFormat('yyyy-MM-dd').format(_tanggalPanen!),
    );

    await DBHelper.instance.insertPengukuran(pengukuran);

    if (!mounted) return;

    showStyledSnackBar(context, 'Data berhasil disimpan');

    setState(() {
      _namaController.clear();
      _lingkarDadaController.clear();
      _panjangBadanController.clear();
      _tinggiGumbaController.clear();
      _poel = null;
      _goalHariController.clear();

      _bobotSekarang = null;
      _estimasiPakan = null;
      _goalHari = null;
      _bobotPanen = null;
      _tanggalPanen = null;

      _sudahHitung = false;
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
        child: Column(
          children: [
            _inputCard(),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _hitung,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Hitung',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            if (_sudahHitung) ...[
              const SizedBox(height: 20),
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
            color: Colors.black.withValues(alpha: 0.03),
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
          _buildTextField(controller: _namaController, hintText: 'ID, Nama Sapi, Nomor Kandang'),
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

          // Form Lingkar Dada dan Panjang Sapi berdampingan
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
          const SizedBox(height: 18),

          // Form Tinggi Gumba dan Poel berdampingan (opsional)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Tinggi Gumba (cm)'),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _tinggiGumbaController,
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
                    _buildLabel('Poel'),
                    const SizedBox(height: 8),
                    AppDropdown<String>(
                      value: _poel,
                      hintText: 'Pilih Poel',
                      items: daftarPoel
                          .map(
                            (poel) => DropdownMenuItem<String>(
                              value: poel,
                              child: Text(poel, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _poel = value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _buildLabel('Goal Panen (Hari)'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _goalHariController,
            hintText: 'Contoh: 120',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: labelGreen),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return AppTextField(
      controller: controller,
      hintText: hintText,
      keyboardType: keyboardType,
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
          const Text('Bobot Awal', style: TextStyle(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _bobotSekarang!.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, height: 1.0),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'Kg',
                  style: TextStyle(color: Colors.white, fontSize: 16, height: 1.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimasi Panen', style: TextStyle(color: Colors.white70)),
              Text(
                '${_bobotPanen!.toStringAsFixed(0)} kg dalam $_goalHari hari',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
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
    final data = prediksiBobotHari(_bobotSekarang!, _goalHari!);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prediksi Pertumbuhan $_goalHari Hari', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryGreen)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0, maxX: 5,
                  minY: _bobotSekarang! - 20, maxY: data.last + 40,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final hari = ((_goalHari! / 5) * spot.x).toInt();
                          return LineTooltipItem(
                            'Hari ke-$hari\n${spot.y.toStringAsFixed(0)} kg',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, interval: 1,
                        getTitlesWidget: (value, meta) {
                          final hari = ((_goalHari! / 5) * value).toInt();
                          return Text('$hari H', style: const TextStyle(fontSize: 11));
                        },
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
                      spots: List.generate(data.length, (index) => FlSpot(index.toDouble(), data[index])),
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
}