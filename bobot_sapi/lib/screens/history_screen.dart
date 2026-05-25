import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../database/db_helper.dart';
import '../models/sapi_model.dart';
import '../models/pengukuran_model.dart';
import '../utils/calculator.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<SapiModel> _daftarSapi = [];
  List<SapiModel> _filteredSapi = [];
  List<PengukuranModel> _daftarPengukuran = [];

  SapiModel? _selectedSapi;
  PengukuranModel? _selectedPengukuran;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSapi();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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

  Future<void> _loadPengukuran(int sapiId) async {
    final data = await DBHelper.instance.getPengukuranBySapi(sapiId);

    setState(() {
      _daftarPengukuran = data;
      _selectedPengukuran = null;
    });
  }

  void _filterSapi(String keyword) {
    setState(() {
      _filteredSapi = _daftarSapi.where((sapi) {
        return sapi.namaSapi.toLowerCase().contains(keyword.toLowerCase());
      }).toList();

      if (_selectedSapi != null &&
          !_filteredSapi.any((s) => s.id == _selectedSapi!.id)) {
        _selectedSapi = null;
        _selectedPengukuran = null;
        _daftarPengukuran = [];
      }
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

  List<PengukuranModel> _sortedPengukuranAwalKeTerbaru() {
    final sorted = [..._daftarPengukuran];

    sorted.sort((a, b) {
      final dateA = DateTime.tryParse(a.tanggal) ?? DateTime(2000);
      final dateB = DateTime.tryParse(b.tanggal) ?? DateTime(2000);
      return dateA.compareTo(dateB);
    });

    return sorted;
  }

  Future<void> _deleteSapi() async {
    if (_selectedSapi == null || _selectedSapi!.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Sapi?'),
        content: Text(
          'Semua riwayat ${_selectedSapi!.namaSapi} juga akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await DBHelper.instance.deleteSapi(_selectedSapi!.id!);

    setState(() {
      _selectedSapi = null;
      _selectedPengukuran = null;
      _daftarPengukuran = [];
      _searchCtrl.clear();
    });

    await _loadSapi();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data sapi berhasil dihapus')),
    );
  }

  Future<void> _deletePengukuran(PengukuranModel item) async {
    if (item.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Riwayat?'),
        content: Text(
          'Hapus riwayat tanggal ${_formatTanggal(item.tanggal)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await DBHelper.instance.deletePengukuran(item.id!);

    if (_selectedSapi?.id != null) {
      await _loadPengukuran(_selectedSapi!.id!);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Riwayat berhasil dihapus')),
    );
  }

  Future<void> _exportPdf() async {
    if (_selectedSapi == null || _daftarPengukuran.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih sapi dan data history dulu')),
      );
      return;
    }

    final sortedPengukuran = _sortedPengukuranAwalKeTerbaru();
    final first = sortedPengukuran.first;
    final last = sortedPengukuran.last;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Laporan Riwayat Pengukuran Sapi',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Nama Sapi: ${_selectedSapi!.namaSapi}'),
          pw.Text(
            'Tanggal Export: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
          ),
          pw.Text('Total Pengukuran: ${sortedPengukuran.length}'),
          pw.SizedBox(height: 16),

          pw.Text(
            'Ringkasan Bobot',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Bobot Awal: ${first.bobotSekarang.toStringAsFixed(1)} kg'),
          pw.Text('Bobot Terbaru: ${last.bobotSekarang.toStringAsFixed(1)} kg'),
          pw.Text('Target Bobot: ${last.targetBobot.toStringAsFixed(1)} kg'),

          pw.SizedBox(height: 20),
          pw.Text(
            'Tabel Riwayat Pengukuran',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          pw.Table.fromTextArray(
            headers: [
              'No',
              'Tanggal',
              'LD',
              'BB',
              'Pakan',
              'Target',
              'Estimasi',
              'Panen',
            ],
            data: List.generate(sortedPengukuran.length, (index) {
              final p = sortedPengukuran[index];

              return [
                '${index + 1}',
                _formatTanggal(p.tanggal),
                '${p.lingkarDada.toStringAsFixed(1)} cm',
                '${p.bobotSekarang.toStringAsFixed(1)} kg',
                '${p.estimasiPakan.toStringAsFixed(1)} kg/hari',
                '${p.targetBobot.toStringAsFixed(1)} kg',
                '${p.estimasiBulan.toStringAsFixed(1)} bln',
                _formatTanggal(p.tanggalPanen),
              ];
            }),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedForDisplay = _sortedPengukuranAwalKeTerbaru();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History Sapi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _daftarSapi.isEmpty
              ? const Center(child: Text('Belum ada data sapi.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _searchCard(),
                      const SizedBox(height: 12),
                      _pilihSapiCard(),

                      if (_selectedSapi != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: OutlinedButton.icon(
                            onPressed: _deleteSapi,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Hapus Sapi'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _tanggalPengukuranCard(sortedForDisplay),
                      ],

                      if (_selectedSapi != null &&
                          _daftarPengukuran.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _exportPdf,
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Export PDF'),
                          ),
                        ),
                      ],

                      if (_selectedPengukuran != null) ...[
                        const SizedBox(height: 16),
                        _detailPengukuranCard(),
                        const SizedBox(height: 16),
                        _grafikPrediksiCard(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _searchCard() {
    return TextField(
      controller: _searchCtrl,
      onChanged: _filterSapi,
      decoration: const InputDecoration(
        labelText: 'Cari sapi',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _pilihSapiCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<SapiModel>(
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
              _daftarPengukuran = [];
              _selectedPengukuran = null;
            });

            if (value?.id != null) {
              _loadPengukuran(value!.id!);
            }
          },
        ),
      ),
    );
  }

  Widget _tanggalPengukuranCard(List<PengukuranModel> sortedData) {
    if (sortedData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Belum ada riwayat pengukuran.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tanggal Pengukuran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Column(
              children: sortedData.map((item) {
                final isSelected = _selectedPengukuran?.id == item.id;

                return ListTile(
                  selected: isSelected,
                  selectedTileColor: Colors.green.withOpacity(0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  leading: const Icon(Icons.calendar_month),
                  title: Text(_formatTanggal(item.tanggal)),
                  subtitle: Text(
                    'BB: ${item.bobotSekarang.toStringAsFixed(1)} kg',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deletePengukuran(item),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedPengukuran = item;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailPengukuranCard() {
    final p = _selectedPengukuran!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Pengukuran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _infoRow('Nama Sapi', _selectedSapi?.namaSapi ?? '-'),
            _infoRow('Tanggal', _formatTanggal(p.tanggal)),
            _infoRow('Lingkar Dada', '${p.lingkarDada.toStringAsFixed(1)} cm'),
            _infoRow('Estimasi BB', '${p.bobotSekarang.toStringAsFixed(1)} kg'),
            _infoRow('Estimasi Pakan', '${p.estimasiPakan.toStringAsFixed(1)} kg/hari'),
            _infoRow('Target Bobot', '${p.targetBobot.toStringAsFixed(1)} kg'),
            _infoRow('Sisa Bobot', '${p.sisaBobot.toStringAsFixed(1)} kg'),
            _infoRow('ADG', '${p.adg.toStringAsFixed(1)} kg/hari'),
            _infoRow('Estimasi Waktu', '${p.estimasiBulan.toStringAsFixed(1)} bulan'),
            _infoRow('Tanggal Panen', _formatTanggal(p.tanggalPanen)),
          ],
        ),
      ),
    );
  }

  Widget _grafikPrediksiCard() {
    final p = _selectedPengukuran!;
    final data = prediksiBobot6Bulan(p.bobotSekarang);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grafik Prediksi 6 Bulan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: 6,
                  minY: p.bobotSekarang - 20,
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
                          if (value < 1 || value > 6) return const SizedBox();
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

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}