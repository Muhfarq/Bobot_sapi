import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/db_helper.dart';
import '../models/sapi_model.dart';
import '../utils/app_theme.dart';
import '../utils/calculator.dart';
import '../utils/data_rumput.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/app_text_field.dart';
import '../widgets/sapi_picker_field.dart';
import '../widgets/status_banner.dart';

class HitungPakanScreen extends StatefulWidget {
  const HitungPakanScreen({super.key, this.refreshNotifier});

  final ValueNotifier<int>? refreshNotifier;

  @override
  State<HitungPakanScreen> createState() => _HitungPakanScreenState();
}

class _HitungPakanScreenState extends State<HitungPakanScreen> {
  final _bobotController = TextEditingController();
  final _beratRumputController = TextEditingController();
  final _beratKonsentratController = TextEditingController();

  final Color primaryGreen = const Color(0xFF004D34);
  final Color accentGreen = const Color(0xFF00A76E);
  final Color labelGreen = const Color(0xFF005C3A);

  RumputItem? _rumput;
  SapiModel? _sapi;
  String? _infoBobot;
  double _estimasi = 0;

  double? _totalBK;
  bool _cukup = true;
  double _kurangBK = 0;
  double _beratRumput = 0;
  double _beratKonsentrat = 0;
  double _bkHijauan = 0;
  double _bkKonsentrat = 0;

  @override
  void initState() {
    super.initState();
    widget.refreshNotifier?.addListener(_onRefresh);
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_onRefresh);
    _bobotController.dispose();
    _beratRumputController.dispose();
    _beratKonsentratController.dispose();
    super.dispose();
  }

  String _formatTanggal(String value) {
    final date = DateTime.tryParse(value);
    return date == null ? value : DateFormat('dd/MM/yyyy').format(date);
  }

  void _onRefresh() {
    final sapi = _sapi;
    if (sapi == null || sapi.id == null) return;
    unawaited(_onSapiChanged(sapi, showEmptyWarning: false));
  }

  Future<void> _onSapiChanged(
    SapiModel? sapi, {
    bool showEmptyWarning = true,
  }) async {
    if (sapi == null) {
      setState(() {
        _sapi = null;
        _infoBobot = null;
      });
      return;
    }

    final pengukuran = await DBHelper.instance.getPengukuranTerakhir(sapi.id!);
    if (!mounted) return;

    setState(() {
      _sapi = sapi;
      if (pengukuran != null) {
        _bobotController.text = pengukuran.bobotSekarang.toStringAsFixed(1);
        _infoBobot = 'Diukur ${_formatTanggal(pengukuran.tanggal)}';
        _estimasi = hitungEstimasiPakan(pengukuran.bobotSekarang);
      } else {
        _infoBobot = null;
      }
    });

    if (pengukuran == null && showEmptyWarning && mounted) {
      showStyledSnackBar(context, 'Sapi ini belum punya data pengukuran');
    }
  }

  void _onBobotChanged(String value) {
    final bobot = double.tryParse(value) ?? 0;
    setState(() {
      if (_sapi != null) _infoBobot = 'Diubah manual';
      _estimasi = bobot > 0 ? hitungEstimasiPakan(bobot) : 0;
    });
  }

  void _hitung() {
    final bobot = double.tryParse(_bobotController.text) ?? 0;
    if (bobot <= 0) {
      showStyledSnackBar(context, 'Bobot terakhir wajib diisi lebih dari 0');
      return;
    }

    final beratRumput = double.tryParse(_beratRumputController.text) ?? 0;
    final beratKonsentrat =
        double.tryParse(_beratKonsentratController.text) ?? 0;

    if (beratRumput > 0 && _rumput == null) {
      showStyledSnackBar(context, 'Pilih jenis rumput terlebih dahulu');
      return;
    }

    if (beratRumput <= 0 && beratKonsentrat <= 0) {
      showStyledSnackBar(
        context,
        'Isi berat hijauan atau konsentrat terlebih dahulu',
      );
      return;
    }

    final estimasi = hitungEstimasiPakan(bobot);
    final bkHijauan = hitungBKHijauan(beratRumput, _rumput?.bk ?? 0);
    final bkKonsentrat = hitungBKKonsentrat(beratKonsentrat);
    final totalBK = bkHijauan + bkKonsentrat;

    FocusScope.of(context).unfocus();
    setState(() {
      _estimasi = estimasi;
      _totalBK = totalBK;
      _cukup = totalBK >= estimasi;
      _kurangBK = estimasi - totalBK;
      _beratRumput = beratRumput;
      _beratKonsentrat = beratKonsentrat;
      _bkHijauan = bkHijauan;
      _bkKonsentrat = bkKonsentrat;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Hitung Pakan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryGreen,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _formCard(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _hitung,
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
            if (_totalBK != null) ...[
              const SizedBox(height: 20),
              _hasilCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _formCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
                'Hitung Rekomendasi Pakan',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: labelGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Estimasi bahan kering per hari (langsung mengikuti bobot terakhir)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimasi Pakan',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _estimasi == 0 ? '0' : _estimasi.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        'kg',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'bahan kering per hari',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildLabel('Pilih Sapi'),
          const SizedBox(height: 8),
          SapiPickerField(
            value: _sapi,
            onChanged: (sapi) => _onSapiChanged(sapi),
          ),
          const SizedBox(height: 18),

          _buildLabel('Bobot Terakhir'),
          const SizedBox(height: 8),
          AppTextField(
            controller: _bobotController,
            hintText: '0',
            keyboardType: TextInputType.number,
            suffixText: 'Kg',
            onChanged: _onBobotChanged,
          ),
          if (_infoBobot != null) ...[
            const SizedBox(height: 6),
            Text(
              _infoBobot!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 18),

          // Pakan hijauan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pakan Hijau (Hijauan)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: labelGreen,
                  ),
                ),
                const SizedBox(height: 14),
                _buildLabel('Pilih Rumput', fontSize: 14),
                const SizedBox(height: 8),
                AppDropdown<RumputItem>(
                  value: _rumput,
                  hintText: 'Pilih Jenis Rumput',
                  items: daftarRumput
                      .map(
                        (rumput) => DropdownMenuItem<RumputItem>(
                          value: rumput,
                          child: Text(
                            rumput.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _rumput = value);
                  },
                ),
                const SizedBox(height: 14),
                _buildLabel('Berat Rumput Yang Digunakan (Kg)', fontSize: 14),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _beratRumputController,
                  hintText: '0',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Pakan konsentrat
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pakan Konsentrat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: labelGreen,
                  ),
                ),
                const SizedBox(height: 14),
                _buildLabel('Berat Konsentrat Yang Digunakan (Kg)', fontSize: 14),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _beratKonsentratController,
                  hintText: '0',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {double fontSize = 15}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: labelGreen,
      ),
    );
  }

  Widget _hasilCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sapi != null) ...[
            Text(
              'Untuk: ${_sapi!.namaSapi}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
          ],
          StatusBanner(
            success: _cukup,
            title: _cukup ? 'Mantap !' : 'Perlu Diperhatikan Lagi',
            message: _cukup
                ? 'Jumlah pakan yang anda berikan sudah pas dan sesuai untuk memenuhi kebutuhan perkembangan sapi'
                : 'Jumlah pakan yang anda berikan masih kurang untuk memenuhi kebutuhan perkembangan sapi',
          ),
          if (!_cukup) ...[
            const SizedBox(height: 8),
            Text(
              'Kurang ${_kurangBK.toStringAsFixed(1)} kg BK',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Total Pakan',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _totalBK!.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'kg',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Hijauan ${_beratRumput.toStringAsFixed(1)} kg segar '
            '(≈ ${_bkHijauan.toStringAsFixed(1)} kg BK) + Konsentrat '
            '${_beratKonsentrat.toStringAsFixed(1)} kg '
            '(≈ ${_bkKonsentrat.toStringAsFixed(1)} kg BK)',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
