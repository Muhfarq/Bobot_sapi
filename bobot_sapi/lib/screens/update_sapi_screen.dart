import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../database/db_helper.dart';
import '../models/sapi_model.dart';
import '../models/pengukuran_model.dart';
import '../utils/calculator.dart';
import '../utils/app_theme.dart';

class UpdateSapiScreen extends StatefulWidget {
  final ValueNotifier<int>? refreshNotifier;
  const UpdateSapiScreen({super.key, this.refreshNotifier});

  @override
  State<UpdateSapiScreen> createState() => _UpdateSapiScreenState();
}

class _UpdateSapiScreenState extends State<UpdateSapiScreen> {
  final _searchController = TextEditingController();
  final _lingkarDadaController = TextEditingController();
  final _targetBobotController = TextEditingController();

  List<SapiModel> _daftarSapi = [];
  List<SapiModel> _filteredSapi = [];
  SapiModel? _selectedSapi;

  DateTime _tanggal = DateTime.now();

  double? _bobotSekarang;
  double? _estimasiPakan;
  double? _targetBobot;
  double? _sisaBobot;
  double? _estimasiBulan;
  DateTime? _tanggalPanen;

  bool _sudahHitungBobot = false;
  bool _sudahHitungTarget = false;
  bool _isLoading = true;

  // Palet warna sesuai gambar UI
  final Color primaryGreen = const Color(0xFF004D34); // Hijau tua Appbar/Header
  final Color accentGreen = const Color(0xFF00A76E);  // Hijau terang Tombol/Icon
  final Color labelGreen = const Color(0xFF005C3A);   // Hijau teks label
  final Color fieldColor = const Color(0xFFF2F2F2);   // Abu-abu input field
  final Color lightGreenBg = const Color(0xFFEAF8F5); // Background hijau muda hasil

  @override
  void initState() {
    super.initState();
    _loadSapi();
    widget.refreshNotifier?.addListener(_onRefresh);
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_onRefresh);
    _searchController.dispose();
    _lingkarDadaController.dispose();
    _targetBobotController.dispose();
    super.dispose();
  }

  void _onRefresh() {
    _loadSapi();
    setState(() {
      _selectedSapi = null;
      _filteredSapi = _daftarSapi;
    });
  }

  Future<void> _loadSapi() async {
    final data = await DBHelper.instance.getAllSapi();

    setState(() {
      _daftarSapi = data;
      _filteredSapi = data;
      _isLoading = false;
    });
  }

  // void _filterSapi(String keyword) {
  //   setState(() {
  //     _filteredSapi = _daftarSapi.where((sapi) {
  //       return sapi.namaSapi.toLowerCase().contains(keyword.toLowerCase());
  //     }).toList();

  //     if (_selectedSapi != null &&
  //         !_filteredSapi.any((sapi) => sapi.id == _selectedSapi!.id)) {
  //       _selectedSapi = null;
  //       _resetHasil();
  //     }
  //   });
  // }

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

  void _resetHasil() {
    setState(() {
      _bobotSekarang = null;
      _estimasiPakan = null;
      _targetBobot = null;
      _sisaBobot = null;
      _estimasiBulan = null;
      _tanggalPanen = null;
      _sudahHitungBobot = false;
      _sudahHitungTarget = false;
    });
  }

  void _hitungBobot() {
    if (_selectedSapi == null) {
      showStyledSnackBar(context, 'Pilih sapi terlebih dahulu');
      return;
    }

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

  Future<void> _simpanUpdate() async {
    if (_selectedSapi == null) {
      showStyledSnackBar(context, 'Pilih sapi terlebih dahulu');
      return;
    }

    if (!_sudahHitungBobot || !_sudahHitungTarget) {
      showStyledSnackBar(context, 'Hitung bobot dan target dulu');
      return;
    }

    final ld = double.tryParse(_lingkarDadaController.text) ?? 0;

    final pengukuran = PengukuranModel(
      sapiId: _selectedSapi!.id!,
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

    showStyledSnackBar(context, 'Update pengukuran berhasil disimpan');

    setState(() {
      _lingkarDadaController.clear();
      _targetBobotController.clear();
      _tanggal = DateTime.now();
    });

    _resetHasil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Update Sapi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryGreen,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : _daftarSapi.isEmpty
              ? const Center(
                  child: Text('Belum ada data sapi. Input sapi dulu.'),
                )
              : SingleChildScrollView(
                  // PADDING BAWAH DIUBAH MENJADI 160 AGAR BISA DI-SCROLL MELEWATI NAVBAR
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
                  child: Column(
                    children: [
                      _formUpdateCard(),
                      
                      const SizedBox(height: 24),
                      // Tombol Hitung Bobot
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _hitungBobot,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Hitung', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _simpanUpdate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.save),
                            label: const Text('Simpan Update', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: labelGreen),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _formUpdateCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
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
                'Update Data Sapi',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: labelGreen),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search Field (Opsional ditampilkan, tapi penting untuk filter)
          // _buildLabel('Cari Sapi'),
          // const SizedBox(height: 8),
          // TextField(
          //   controller: _searchController,
          //   onChanged: _filterSapi,
          //   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          //   decoration: InputDecoration(
          //     hintText: 'Ketik nama sapi...',
          //     hintStyle: const TextStyle(color: Colors.black38),
          //     prefixIcon: Icon(Icons.search, color: accentGreen),
          //     filled: true,
          //     fillColor: fieldColor,
          //     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          //   ),
          // ),
          // const SizedBox(height: 16),

          _buildLabel('Pilih Sapi'),
          const SizedBox(height: 8),
          DropdownButtonFormField<SapiModel>(
            value: _selectedSapi,
            decoration: InputDecoration(
              filled: true,
              fillColor: fieldColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(16),
            icon: Icon(Icons.keyboard_arrow_down, color: accentGreen),
            hint: Text('Pilih dari daftar', style: TextStyle(color: accentGreen)),
            style: TextStyle(color: labelGreen, fontWeight: FontWeight.w500),
            items: _filteredSapi.map((sapi) {
              return DropdownMenuItem<SapiModel>(
                value: sapi,
                child: Text(sapi.namaSapi, style: TextStyle(fontWeight: FontWeight.w500, color: labelGreen)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSapi = value;
                _lingkarDadaController.clear();
                _targetBobotController.clear();
                _tanggal = DateTime.now();
              });
              _resetHasil();
            },
          ),
          const SizedBox(height: 16),

          _buildLabel('Tanggal'),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pilihTanggal,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(color: fieldColor, borderRadius: BorderRadius.circular(12)),
              child: Text(
                DateFormat('dd/MM/yyyy').format(_tanggal),
                style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Lingkar Dada (cm)'),
              const SizedBox(height: 8),
              _buildTextField(controller: _lingkarDadaController, hintText: '0', keyboardType: TextInputType.number),
            ],
          ),
        ],
      ),
    );
  }

  // --- Box Hasil Bobot Warna Hijau Muda ---
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
          _buildLabel('Target Bobot Panen (Kg)'),
          const SizedBox(height: 8),
          _buildTextField(controller: _targetBobotController, hintText: '500', keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _hitungTarget,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Hitung Target Panen', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Box Estimasi Panen Warna Hijau Tua ---
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
          Text('Prediksi Pertumbuhan 6 Bulan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryGreen)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
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