// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sapi.dart';
import '../utils/app_theme.dart';
import '../utils/storage_service.dart';
import 'history_sapi_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Sapi> _daftarSapi = [];
  final Set<String> _selected = {};
  bool _selectMode = false;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await StorageService.loadSapi();
    setState(() => _daftarSapi = list);
  }

  List<Sapi> get _filtered => _daftarSapi
      .where((s) => s.idNama.toLowerCase().contains(_query))
      .toList();

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
        if (_selected.isEmpty) _selectMode = false;
      } else {
        _selected.add(id);
      }
    });
  }

  void _enterSelectMode(String id) {
    setState(() {
      _selectMode = true;
      _selected.add(id);
    });
  }

  void _cancelSelect() {
    setState(() {
      _selectMode = false;
      _selected.clear();
    });
  }

  Future<void> _export() async {
    final selectedSapi = _daftarSapi.where((s) => _selected.contains(s.id)).toList();

    // Build CSV
    final buffer = StringBuffer();
    buffer.writeln('ID,Nama,Tanggal Masuk,Tanggal Pengukuran,Lingkar Dada (cm),Panjang Badan (cm),Estimasi Bobot (kg),Estimasi Pakan (kg),Target Bobot (kg),Estimasi Panen (bulan),Status');

    for (final sapi in selectedSapi) {
      for (final p in sapi.riwayat) {
        buffer.writeln(
          '${sapi.id},${sapi.nama},${DateFormat('dd/MM/yyyy').format(sapi.tanggalMasuk)},'
          '${DateFormat('dd/MM/yyyy').format(p.tanggal)},${p.lingkarDada},${p.panjangBadan},'
          '${p.estimasiBobot.toStringAsFixed(1)},${p.estimasiPakan.toStringAsFixed(1)},'
          '${p.targetBobot},${p.bulanOptimis},${p.statusPanen}',
        );
      }
    }

    // Show preview dialog
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${selectedSapi.length} sapi dipilih untuk diekspor.'),
            const SizedBox(height: 8),
            Text(
              '${selectedSapi.fold(0, (sum, s) => sum + s.riwayat.length)} total pengukuran',
              style: const TextStyle(color: AppColors.teksAbu),
            ),
            const SizedBox(height: 12),
            const Text(
              'Fitur export ke file CSV memerlukan plugin tambahan di perangkat nyata.',
              style: TextStyle(fontSize: 12, color: AppColors.abu),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.hijau,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _cancelSelect();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data berhasil diekspor!'),
                  backgroundColor: AppColors.hijau,
                ),
              );
            },
            child: const Text('Export CSV'),
          ),
        ],
      ),
    );
  }

  void _tapPilih() {
    if (_selectMode) {
      _cancelSelect();
    } else {
      setState(() => _selectMode = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Logo')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari Sapi',
                prefixIcon: const Icon(Icons.search, color: AppColors.abu),
                filled: true,
                fillColor: AppColors.abuMuda,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Tombol pilih / batal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: _selectMode
                  ? OutlinedButton(
                      onPressed: _cancelSelect,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.hijau),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Batal',
                          style: TextStyle(color: AppColors.hijau)),
                    )
                  : ElevatedButton(
                      onPressed: _tapPilih,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Pilih'),
                    ),
            ),
          ),
          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          _query.isEmpty
                              ? 'Belum ada data sapi'
                              : 'Tidak ditemukan',
                          style: const TextStyle(color: AppColors.teksAbu),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final sapi = filtered[i];
                      final isSelected = _selected.contains(sapi.id);
                      return GestureDetector(
                        onLongPress: () => _enterSelectMode(sapi.id),
                        onTap: () {
                          if (_selectMode) {
                            _toggleSelect(sapi.id);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    HistorySapiScreen(sapiId: sapi.id),
                              ),
                            ).then((_) => _load());
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.hijauMuda
                                : AppColors.hijauCard,
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? Border.all(color: AppColors.hijau, width: 1.5)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sapi.idNama,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppColors.gelap,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd/MM/yyyy')
                                          .format(sapi.tanggalMasuk),
                                      style: const TextStyle(
                                        color: AppColors.hijauText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectMode)
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    key: ValueKey(isSelected),
                                    color: isSelected
                                        ? AppColors.hijau
                                        : AppColors.abu,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Export button
          if (_selectMode && _selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: ElevatedButton(
                onPressed: _export,
                child: Text('Export (${_selected.length} dipilih)'),
              ),
            ),
        ],
      ),
    );
  }
}
