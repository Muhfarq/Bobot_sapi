import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/db_helper.dart';
import '../models/sapi_model.dart';
import '../models/pengukuran_model.dart';
import '../utils/app_theme.dart';
import 'history_detail_sheet.dart';

class HistoryTanggalScreen extends StatefulWidget {
  final SapiModel sapi;

  const HistoryTanggalScreen({
    super.key,
    required this.sapi,
  });

  @override
  State<HistoryTanggalScreen> createState() => _HistoryTanggalScreenState();
}

class _HistoryTanggalScreenState extends State<HistoryTanggalScreen> {
  List<PengukuranModel> _daftarPengukuran = [];
  bool _isLoading = true;

  final Color primaryGreen = const Color(0xFF004D34);
  final Color accentGreen = const Color(0xFF00A76E);
  final Color labelGreen = const Color(0xFF005C3A);
  final Color lightGreenBg = const Color(0xFFEAF8F5);

  @override
  void initState() {
    super.initState();
    _loadPengukuran();
  }

  Future<void> _loadPengukuran() async {
    final data = await DBHelper.instance.getPengukuranBySapi(widget.sapi.id!);

    data.sort((a, b) {
      final dateA = DateTime.tryParse(a.tanggal) ?? DateTime(2000);
      final dateB = DateTime.tryParse(b.tanggal) ?? DateTime(2000);
      return dateA.compareTo(dateB);
    });

    setState(() {
      _daftarPengukuran = data;
      _isLoading = false;
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
          'Semua riwayat ${widget.sapi.namaSapi} juga akan dihapus.',
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

    await DBHelper.instance.deleteSapi(widget.sapi.id!);

    if (!mounted) return;
    showStyledSnackBar(context, 'Data sapi berhasil dihapus');
    Navigator.pop(context);
  }

  Future<void> _deletePengukuran(PengukuranModel item) async {
    if (item.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Riwayat?',
          style: TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
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
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await DBHelper.instance.deletePengukuran(item.id!);
    await _loadPengukuran();

    if (!mounted) return;
    showStyledSnackBar(context, 'Riwayat berhasil dihapus');
  }

  void _openDetailSheet(PengukuranModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HistoryDetailSheet(
        sapi: widget.sapi,
        pengukuran: item,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.sapi.namaSapi,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _deleteSapi,
            icon: const Icon(Icons.delete_outline, color: Colors.white),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _daftarPengukuran.isEmpty
              ? const Center(child: Text('Belum ada riwayat pengukuran.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tanggal Pengukuran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: labelGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: _daftarPengukuran.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: lightGreenBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.calendar_month,
                                color: accentGreen,
                              ),
                              title: Text(
                                _formatTanggal(item.tanggal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'BB: ${item.bobotSekarang.toStringAsFixed(1)} kg',
                                style: TextStyle(
                                  color: primaryGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.keyboard_arrow_up,
                                    color: primaryGreen,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deletePengukuran(item),
                                  ),
                                ],
                              ),
                              onTap: () => _openDetailSheet(item),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
    );
  }
}