import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../database/db_helper.dart';
import '../models/sapi_model.dart';
import '../models/pengukuran_model.dart';
import '../utils/calculator.dart';
import '../utils/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  final ValueNotifier<int>? refreshNotifier;
  const HistoryScreen({super.key, this.refreshNotifier});

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

  final Color primaryGreen = const Color(0xFF004D34);
  final Color accentGreen = const Color(0xFF00A76E);
  final Color labelGreen = const Color(0xFF005C3A);
  final Color fieldColor = const Color(0xFFF2F2F2);
  final Color lightGreenBg = const Color(0xFFEAF8F5);

  // --- Variabel Baru untuk Mode Seleksi ---
  bool _isSelectionMode = false;
  final Set<int> _selectedSapiIds = {};

  @override
  void initState() {
    super.initState();
    _loadSapi();
    widget.refreshNotifier?.addListener(_onRefresh);
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_onRefresh);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onRefresh() {
    _loadSapi();
    setState(() {
      _selectedSapi = null;
      _selectedPengukuran = null;
      _daftarPengukuran = [];
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

  // --- Fungsi Hapus Diperbarui agar mendukung multi-select ---
  Future<void> _deleteSapi() async {
    final isMulti = _isSelectionMode && _selectedSapiIds.isNotEmpty;
    if (!isMulti && (_selectedSapi == null || _selectedSapi!.id == null)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Sapi?', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
        content: Text(
          isMulti
              ? 'Hapus ${_selectedSapiIds.length} sapi yang dipilih beserta riwayatnya?'
              : 'Semua riwayat ${_selectedSapi!.namaSapi} juga akan dihapus.',
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (isMulti) {
      for (int id in _selectedSapiIds) {
        await DBHelper.instance.deleteSapi(id);
      }
      setState(() {
        _selectedSapiIds.clear();
        _isSelectionMode = false;
      });
    } else {
      await DBHelper.instance.deleteSapi(_selectedSapi!.id!);
    }

    setState(() {
      _selectedSapi = null;
      _selectedPengukuran = null;
      _daftarPengukuran = [];
      _searchCtrl.clear();
    });

    await _loadSapi();

    if (!mounted) return;
    showStyledSnackBar(context, 'Data sapi berhasil dihapus');
  }

  Future<void> _deletePengukuran(PengukuranModel item) async {
    if (item.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Riwayat?', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
    showStyledSnackBar(context, 'Riwayat berhasil dihapus');
  }

  // --- Fungsi Export Asli ---
  Future<void> _exportPdf() async {
    if (_selectedSapi == null || _daftarPengukuran.isEmpty) {
      showStyledSnackBar(context, 'Pilih sapi dan data history dulu');
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

  // --- Wrapper Export untuk Mode Seleksi ---
  Future<void> _exportPdfAction() async {
    if (_selectedSapiIds.isEmpty) return;

    // Supaya logika asli tidak rusak, proses PDF sapi pertama yang dipilih
    final targetId = _selectedSapiIds.first;
    final sapi = _daftarSapi.firstWhere((s) => s.id == targetId);

    setState(() {
      _selectedSapi = sapi;
    });

    await _loadPengukuran(targetId);

    if (_daftarPengukuran.isEmpty) {
      if (!mounted) return;
      showStyledSnackBar(context, 'Sapi yang dipilih tidak memiliki data history');
      return;
    }

    await _exportPdf();
  }

  // --- Handlers Interaksi List Sapi ---
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedSapiIds.clear();
      } else {
        _selectedSapi = null; // Sembunyikan detail saat mode select
      }
    });
  }

  void _handleSapiLongPress(SapiModel sapi) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedSapiIds.add(sapi.id!);
        _selectedSapi = null; // Sembunyikan view detail
      });
    }
  }

  void _handleSapiTap(SapiModel sapi) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedSapiIds.contains(sapi.id)) {
          _selectedSapiIds.remove(sapi.id!);
        } else {
          _selectedSapiIds.add(sapi.id!);
        }
      });
    } else {
      setState(() {
        if (_selectedSapi?.id == sapi.id) {
          _selectedSapi = null; // Toggle collapse (tutup)
          _daftarPengukuran = [];
          _selectedPengukuran = null;
        } else {
          _selectedSapi = sapi;
          _daftarPengukuran = [];
          _selectedPengukuran = null;
        }
      });
      if (_selectedSapi != null) {
        _loadPengukuran(sapi.id!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedForDisplay = _sortedPengukuranAwalKeTerbaru();

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _toggleSelectionMode();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: primaryGreen,
          title: const Text('History', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _daftarSapi.isEmpty
              ? const Center(child: Text('Belum ada data sapi.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    children: [
                      _searchCard(),
                      const SizedBox(height: 12),
                      _headerActionRow(),
                      const SizedBox(height: 12),
                      
                      // List Sapi pengganti Dropdown
                      _buildSapiList(),

                      // Tampilan Original Detail saat 1 Sapi di tap
                      if (_selectedSapi != null && !_isSelectionMode) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: _deleteSapi,
                            icon: const Icon(Icons.delete_outline, color: Colors.white),
                            label: const Text('Hapus Sapi', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _tanggalPengukuranCard(sortedForDisplay),
                      ],

                      if (_selectedSapi != null &&
                          _daftarPengukuran.isNotEmpty && 
                          !_isSelectionMode) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A65F),
                            ),
                            onPressed: _exportPdf,
                            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                            label: const Text('Export PDF', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],

                      if (_selectedPengukuran != null && !_isSelectionMode) ...[
                        const SizedBox(height: 16),
                        _detailPengukuranCard(),
                        const SizedBox(height: 16),
                        _hasilBobotCard(),
                        const SizedBox(height: 16),
                        _hasilTargetCard(),
                        const SizedBox(height: 16),
                        _grafikPrediksiCard(),
                      ],
                    ],
                  ),
                ),
      // Tombol Export & Hapus saat Mode Seleksi
      bottomNavigationBar: _isSelectionMode ? _bottomSelectionActions() : null,
      ),
    );
  }

  // --- Kumpulan Komponen UI Baru & Diperbarui ---

  Widget _searchCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3), // Abu-abu muda
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _filterSapi,
        decoration: const InputDecoration(
          hintText: 'Cari Sapi',
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _headerActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!_isSelectionMode)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A65F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _toggleSelectionMode,
            child: const Text('Pilih', style: TextStyle(color: Colors.white)),
          )
        else
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00A65F)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _toggleSelectionMode,
            child: const Text('Batal', style: TextStyle(color: Color(0xFF00A65F))),
          ),
      ],
    );
  }

  Widget _buildSapiList() {
    final showAll = _selectedSapi == null || _isSelectionMode;
    final displayList = showAll ? _filteredSapi : [_selectedSapi!];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        final sapi = displayList[index];
        final isSelected = _selectedSapiIds.contains(sapi.id);
        final isExpanded = _selectedSapi?.id == sapi.id;

        return GestureDetector(
          onLongPress: () => _handleSapiLongPress(sapi),
          onTap: () => _handleSapiTap(sapi),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFA5F4C8), // Hijau muda soft sesuai desain
              borderRadius: BorderRadius.circular(8),
              border: isExpanded ? Border.all(color: const Color(0xFF00A65F), width: 1.5) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sapi.namaSapi,
                      style: const TextStyle(
                        color: Color(0xFF006C40), // Teks nama hijau tua
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Ketuk untuk detail", // Hint untuk user UX
                      style: TextStyle(color: Colors.grey.withOpacity(0.9), fontSize: 12),
                    ),
                  ],
                ),
                if (_isSelectionMode)
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? const Color(0xFF008955) : Colors.white,
                    size: 28,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bottomSelectionActions() {
    if (!_isSelectionMode) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
        ]
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14)
                ),
                onPressed: _selectedSapiIds.isEmpty ? null : _deleteSapi,
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text('Hapus', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A65F), // Hijau sesuai tombol desain
                  padding: const EdgeInsets.symmetric(vertical: 14)
                ),
                onPressed: _selectedSapiIds.isEmpty ? null : _exportPdfAction,
                icon: const Icon(Icons.file_download, color: Colors.white),
                label: const Text('Export PDF', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Sisa Komponen di bawah ini tetap utuh, hanya dirapikan card-nya ---

  Widget _tanggalPengukuranCard(List<PengukuranModel> sortedData) {
    if (sortedData.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(16),
        child: const Text('Belum ada riwayat pengukuran.'),
      );
    }

    return Container(
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
            'Tanggal Pengukuran',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: labelGreen),
          ),
          const SizedBox(height: 12),

            Column(
              children: sortedData.map((item) {
                final isSelected = _selectedPengukuran?.id == item.id;

                return Container(
                  decoration: BoxDecoration(
                    color: isSelected ? lightGreenBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    leading: Icon(Icons.calendar_month, color: accentGreen),
                    title: Text(
                      _formatTanggal(item.tanggal),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'BB: ${item.bobotSekarang.toStringAsFixed(1)} kg',
                      style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w500),
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
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _detailPengukuranCard() {
    final p = _selectedPengukuran!;

    return Container(
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
            'Detail Pengukuran',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: labelGreen),
          ),
          const SizedBox(height: 12),

          _infoRow('Nama Sapi', _selectedSapi?.namaSapi ?? '-'),
          _infoRow('Tanggal', _formatTanggal(p.tanggal)),
          _infoRow('Lingkar Dada', '${p.lingkarDada.toStringAsFixed(1)} cm'),
          _infoRow('ADG', '${p.adg.toStringAsFixed(1)} kg/hari'),
        ],
      ),
    );
  }

  Widget _hasilBobotCard() {
    final p = _selectedPengukuran!;

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
            child: Column(
              children: [
                Text(
                  '${p.bobotSekarang.toStringAsFixed(0)} kg',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryGreen),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estimasi Bobot',
                  style: TextStyle(color: accentGreen, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: accentGreen.withOpacity(0.3)),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${p.estimasiPakan.toStringAsFixed(1)} Kg',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryGreen),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estimasi Pakan',
                  style: TextStyle(color: accentGreen, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hasilTargetCard() {
    final p = _selectedPengukuran!;

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
                p.estimasiBulan.toStringAsFixed(0),
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
              Text('${p.targetBobot.toStringAsFixed(1)} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sisa Bobot', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              Text('${p.sisaBobot.toStringAsFixed(1)} kg', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tanggal Panen', style: TextStyle(color: Colors.white70)),
              Text(_formatTanggal(p.tanggalPanen), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _grafikPrediksiCard() {
    final p = _selectedPengukuran!;
    final data = prediksiBobot6Bulan(p.bobotSekarang);

    return Container(
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
            'Prediksi Pertumbuhan 6 Bulan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: labelGreen),
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
                        return Text('+${value.toInt()}B', style: const TextStyle(fontSize: 11));
                      },
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
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: Colors.black54))),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen)),
        ],
      ),
    );
  }
}