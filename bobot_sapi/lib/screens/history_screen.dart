import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../database/db_helper.dart';
import '../models/sapi_model.dart';
import '../utils/app_theme.dart';
import 'history_tanggal_screen.dart';

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

  bool _isLoading = true;
  bool _isSelectionMode = false;

  final Set<int> _selectedSapiIds = {};

  final Color primaryGreen = const Color(0xFF004D34);
  final Color accentGreen = const Color(0xFF00A76E);

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
    if (_selectedSapiIds.isEmpty) return;

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
          'Hapus ${_selectedSapiIds.length} sapi yang dipilih beserta seluruh riwayatnya?',
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

    for (final id in _selectedSapiIds) {
      await DBHelper.instance.deleteSapi(id);
    }

    setState(() {
      _selectedSapiIds.clear();
      _isSelectionMode = false;
      _searchCtrl.clear();
    });

    await _loadSapi();

    if (!mounted) return;
    showStyledSnackBar(context, 'Data sapi berhasil dihapus');
  }

  Future<void> _exportPdfAction() async {
    if (_selectedSapiIds.isEmpty) return;

    final pdf = pw.Document();
    int exportedCount = 0;

    for (final targetId in _selectedSapiIds) {
      final sapi = _daftarSapi.firstWhere((s) => s.id == targetId);
      final daftarPengukuran =
          await DBHelper.instance.getPengukuranBySapi(targetId);

      if (daftarPengukuran.isEmpty) {
        continue;
      }

      final sorted = [...daftarPengukuran];

      sorted.sort((a, b) {
        final dateA = DateTime.tryParse(a.tanggal) ?? DateTime(2000);
        final dateB = DateTime.tryParse(b.tanggal) ?? DateTime(2000);
        return dateA.compareTo(dateB);
      });

      final first = sorted.first;
      final last = sorted.last;

      exportedCount++;

      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Text(
              'Laporan Riwayat Pengukuran Sapi',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text('Nama Sapi: ${sapi.namaSapi}'),
            pw.Text(
              'Tanggal Export: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
            ),
            pw.Text('Total Pengukuran: ${sorted.length}'),
            pw.SizedBox(height: 16),
            pw.Text(
              'Ringkasan Bobot',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Bobot Awal: ${first.bobotSekarang.toStringAsFixed(1)} kg',
            ),
            pw.Text(
              'Bobot Terbaru: ${last.bobotSekarang.toStringAsFixed(1)} kg',
            ),
            pw.Text(
              'Target Bobot: ${last.targetBobot.toStringAsFixed(1)} kg',
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: [
                'No',
                'Tanggal',
                'LD',
                'BB',
                'Pakan',
                'Target',
                'Goal',
                'Panen',
              ],
              data: List.generate(sorted.length, (index) {
                final p = sorted[index];

                return [
                  '${index + 1}',
                  _formatTanggal(p.tanggal),
                  '${p.lingkarDada.toStringAsFixed(1)} cm',
                  '${p.bobotSekarang.toStringAsFixed(1)} kg',
                  '${p.estimasiPakan.toStringAsFixed(1)} kg/hari',
                  '${p.targetBobot.toStringAsFixed(1)} kg',
                  '${p.goalHari} Hari',
                  _formatTanggal(p.tanggalPanen),
                ];
              }),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      );
    }

    if (exportedCount == 0) {
      if (!mounted) return;
      showStyledSnackBar(
        context,
        'Sapi yang dipilih tidak memiliki history',
      );
      return;
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;

      if (!_isSelectionMode) {
        _selectedSapiIds.clear();
      }
    });
  }

  void _handleSapiTap(SapiModel sapi) async {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedSapiIds.contains(sapi.id)) {
          _selectedSapiIds.remove(sapi.id!);
        } else {
          _selectedSapiIds.add(sapi.id!);
        }
      });
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HistoryTanggalScreen(sapi: sapi),
        ),
      );

      await _loadSapi();
    }
  }

  void _handleSapiLongPress(SapiModel sapi) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedSapiIds.add(sapi.id!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          title: const Text(
            'History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryGreen))
            : _daftarSapi.isEmpty
                ? const Center(child: Text('Belum ada data sapi.'))
                : SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      _isSelectionMode ? 160 : 100,
                    ),
                    child: Column(
                      children: [
                        _searchCard(),
                        const SizedBox(height: 12),
                        _headerActionRow(),
                        const SizedBox(height: 12),
                        _buildSapiList(),
                      ],
                    ),
                  ),
        bottomSheet: _isSelectionMode ? _bottomSelectionActions() : null,
      ),
    );
  }

  Widget _searchCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _toggleSelectionMode,
            child: const Text(
              'Pilih',
              style: TextStyle(color: Colors.white),
            ),
          )
        else
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00A65F)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _toggleSelectionMode,
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF00A65F)),
            ),
          ),
      ],
    );
  }

  Widget _buildSapiList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredSapi.length,
      itemBuilder: (context, index) {
        final sapi = _filteredSapi[index];
        final isSelected = _selectedSapiIds.contains(sapi.id);

        return GestureDetector(
          onLongPress: () => _handleSapiLongPress(sapi),
          onTap: () => _handleSapiTap(sapi),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFA5F4C8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sapi.namaSapi,
                  style: const TextStyle(
                    color: Color(0xFF006C40),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isSelectionMode)
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? const Color(0xFF008955) : Colors.white,
                    size: 28,
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF006C40),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bottomSelectionActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _selectedSapiIds.isEmpty ? null : _deleteSapi,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text(
                'Hapus',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A65F),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _selectedSapiIds.isEmpty ? null : _exportPdfAction,
              icon: const Icon(Icons.file_download, color: Colors.white),
              label: const Text(
                'Export PDF',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}