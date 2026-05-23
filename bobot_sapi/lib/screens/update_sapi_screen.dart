import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../database/db_helper.dart';
import '../models/sapi_model.dart';
import '../models/pengukuran_model.dart';
import '../utils/calculator.dart';

class UpdateSapiScreen extends StatefulWidget {
  const UpdateSapiScreen({super.key});

  @override
  State<UpdateSapiScreen> createState() => _UpdateSapiScreenState();
}

class _UpdateSapiScreenState extends State<UpdateSapiScreen> {
  final _searchController = TextEditingController();
  final _lingkarDadaController = TextEditingController();
  final _targetBobotController = TextEditingController(text: '750');

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

  @override
  void initState() {
    super.initState();
    _loadSapi();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _lingkarDadaController.dispose();
    _targetBobotController.dispose();
    super.dispose();
  }

  Future<void> _loadSapi() async {
    final data = await DBHelper.instance.getAllSapi();

    setState(() {
      _daftarSapi = data;
      _filteredSapi = data;
      _isLoading = false;
    });
  }

  void _filterSapi(String keyword) {
    setState(() {
      _filteredSapi = _daftarSapi.where((sapi) {
        return sapi.namaSapi.toLowerCase().contains(keyword.toLowerCase());
      }).toList();

      if (_selectedSapi != null &&
          !_filteredSapi.any((sapi) => sapi.id == _selectedSapi!.id)) {
        _selectedSapi = null;
        _resetHasil();
      }
    });
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih sapi terlebih dahulu')),
      );
      return;
    }

    final ld = double.tryParse(_lingkarDadaController.text) ?? 0;

    if (ld <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lingkar dada wajib diisi')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target bobot wajib diisi')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih sapi terlebih dahulu')),
      );
      return;
    }

    if (!_sudahHitungBobot || !_sudahHitungTarget) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hitung bobot dan target dulu')),
      );
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Update pengukuran berhasil disimpan')),
    );

    setState(() {
      _lingkarDadaController.clear();
      _targetBobotController.text = '750';
      _tanggal = DateTime.now();
    });

    _resetHasil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Sapi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _daftarSapi.isEmpty
              ? const Center(
                  child: Text('Belum ada data sapi. Input sapi dulu.'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _formUpdateCard(),
                      if (_sudahHitungBobot) ...[
                        const SizedBox(height: 16),
                        _hasilBobotCard(),
                        const SizedBox(height: 16),
                        _targetCard(),
                      ],
                      if (_sudahHitungTarget) ...[
                        const SizedBox(height: 16),
                        _hasilTargetCard(),
                        const SizedBox(height: 16),
                        _grafikPrediksiCard(),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _simpanUpdate,
                            icon: const Icon(Icons.save),
                            label: const Text('Simpan Update'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _formUpdateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Pengukuran Sapi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _searchController,
              onChanged: _filterSapi,
              decoration: const InputDecoration(
                labelText: 'Cari sapi',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<SapiModel>(
              value: _selectedSapi,
              decoration: const InputDecoration(
                labelText: 'Pilih Sapi',
                border: OutlineInputBorder(),
              ),
              items: _filteredSapi.map((sapi) {
                return DropdownMenuItem<SapiModel>(
                  value: sapi,
                  child: Text(sapi.namaSapi),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSapi = value;
                  _lingkarDadaController.clear();
                  _targetBobotController.text = '750';
                  _tanggal = DateTime.now();
                });
                _resetHasil();
              },
            ),

            const SizedBox(height: 12),

            InkWell(
              onTap: _pilihTanggal,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Pengukuran',
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_tanggal)),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _lingkarDadaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Lingkar Dada Baru (cm)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _hitungBobot,
                child: const Text('Hitung Bobot Baru'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hasilBobotCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _infoItem(
                title: 'Estimasi BB Baru',
                value: '${_bobotSekarang!.toStringAsFixed(1)} kg',
              ),
            ),
            Expanded(
              child: _infoItem(
                title: 'Estimasi Pakan',
                value: '${_estimasiPakan!.toStringAsFixed(1)} kg/hari',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _targetCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _targetBobotController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Bobot Panen (kg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _hitungTarget,
                child: const Text('Hitung Target Panen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hasilTargetCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow('Target Bobot', '${_targetBobot!.toStringAsFixed(1)} kg'),
            _infoRow('Sisa Bobot', '${_sisaBobot!.toStringAsFixed(1)} kg'),
            _infoRow(
              'Estimasi Waktu',
              '${_estimasiBulan!.toStringAsFixed(1)} bulan',
            ),
            _infoRow(
              'Tanggal Panen',
              DateFormat('dd/MM/yyyy').format(_tanggalPanen!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grafikPrediksiCard() {
    final data = prediksiBobot6Bulan(_bobotSekarang!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prediksi Pertumbuhan 6 Bulan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: 6,
                  minY: _bobotSekarang! - 20,
                  maxY: data.last + 40,
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: true,
                  ),
                  borderData: FlBorderData(show: true),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Bulan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value < 1 || value > 6) {
                            return const SizedBox();
                          }
                          return Text('+${value.toInt()}');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      axisNameWidget: Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Text(
                          'BB (kg)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 50,
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      barWidth: 4,
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
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem({
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(title),
      ],
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}