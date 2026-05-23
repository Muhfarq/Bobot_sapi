// lib/screens/input_sapi_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/sapi.dart';
import '../utils/app_theme.dart';
import '../utils/storage_service.dart';

class InputSapiScreen extends StatefulWidget {
  const InputSapiScreen({super.key});

  @override
  State<InputSapiScreen> createState() => _InputSapiScreenState();
}

class _InputSapiScreenState extends State<InputSapiScreen> {
  final _idNamaCtrl = TextEditingController(text: 'A001Bima');
  final _lingkarDadaCtrl = TextEditingController();
  final _panjangBadanCtrl = TextEditingController();
  final _targetBobotCtrl = TextEditingController(text: '500');
  DateTime _tanggal = DateTime.now();
  bool _sudahHitung = false;
  PengukuranSapi? _hasilHitung;

  @override
  void dispose() {
    _idNamaCtrl.dispose();
    _lingkarDadaCtrl.dispose();
    _panjangBadanCtrl.dispose();
    _targetBobotCtrl.dispose();
    super.dispose();
  }

  void _hitung() {
    final ld = double.tryParse(_lingkarDadaCtrl.text) ?? 0;
    final pb = double.tryParse(_panjangBadanCtrl.text) ?? 0;
    final target = double.tryParse(_targetBobotCtrl.text) ?? 500;

    if (ld == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan Lingkar Dada terlebih dahulu')),
      );
      return;
    }

    final hasil = PengukuranSapi(
      id: const Uuid().v4(),
      tanggal: _tanggal,
      lingkarDada: ld,
      panjangBadan: pb,
      targetBobot: target,
    );

    setState(() {
      _hasilHitung = hasil;
      _sudahHitung = true;
    });
  }

  Future<void> _simpan() async {
    if (_hasilHitung == null) return;
    final idNama = _idNamaCtrl.text.trim();
    if (idNama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan ID/Nama Sapi')),
      );
      return;
    }

    final daftar = await StorageService.loadSapi();
    final existing = daftar.where((s) => s.idNama == idNama).toList();

    if (existing.isNotEmpty) {
      existing.first.riwayat.add(_hasilHitung!);
      await StorageService.updateSapi(existing.first);
    } else {
      // parse id & nama: misal "A001" + "Bima"
      final idMatch = RegExp(r'^([A-Z]\d+)(.+)$').firstMatch(idNama);
      final id = idMatch?.group(1) ?? idNama;
      final nama = idMatch?.group(2) ?? idNama;

      final sapi = Sapi(
        id: id,
        nama: nama,
        tanggalMasuk: _tanggal,
        targetBobot: _hasilHitung!.targetBobot,
      );
      sapi.riwayat.add(_hasilHitung!);
      await StorageService.tambahSapi(sapi);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data berhasil disimpan!'),
        backgroundColor: AppColors.hijau,
      ),
    );

    setState(() {
      _sudahHitung = false;
      _hasilHitung = null;
      _lingkarDadaCtrl.clear();
      _panjangBadanCtrl.clear();
    });
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.hijau),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Sapi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFormCard(),
            if (_sudahHitung && _hasilHitung != null) ...[
              const SizedBox(height: 16),
              _buildHasilCard(),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _simpan,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Simpan'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.putih,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.add, color: AppColors.hijau, size: 22),
              SizedBox(width: 8),
              Text(
                'Input Data Sapi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gelap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _label('ID/Nama Sapi'),
          TextField(
            controller: _idNamaCtrl,
            decoration: const InputDecoration(hintText: 'A001Bima'),
          ),
          const SizedBox(height: 14),
          _label('Tanggal'),
          GestureDetector(
            onTap: _pilihTanggal,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.abuMuda,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                DateFormat('dd/MM/yyyy').format(_tanggal),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Lingkar Dada (cm)'),
                    TextField(
                      controller: _lingkarDadaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '0'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Panjang Badan (cm)'),
                    TextField(
                      controller: _panjangBadanCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '0'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _label('Target Bobot Panen (Kg)'),
          TextField(
            controller: _targetBobotCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '500'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _hitung,
            child: const Text('Hitung'),
          ),
        ],
      ),
    );
  }

  Widget _buildHasilCard() {
    final h = _hasilHitung!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.putih,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estimasi bobot & pakan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.hijauCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.hijauMuda),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${h.estimasiBobot.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gelap,
                        ),
                      ),
                      const Text(
                        'Estimasi Bobot',
                        style: TextStyle(
                          color: AppColors.hijauText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.hijauMuda),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${h.estimasiPakan.toStringAsFixed(1)} Kg',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gelap,
                          ),
                        ),
                        const Text(
                          'Estimasi Pakan',
                          style: TextStyle(
                            color: AppColors.hijauText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Estimasi Panen',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.gelap,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.hijau,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${h.bulanOptimis}',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppColors.putih,
                        ),
                      ),
                      const TextSpan(
                        text: 'Bulan',
                        style: TextStyle(
                          fontSize: 20,
                          color: AppColors.putih,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  h.statusPanen,
                  style: const TextStyle(
                    color: AppColors.hijauMuda,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pesimis: ${h.bulanPesimis} Bulan',
                  style: TextStyle(
                    color: AppColors.putih.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.gelap,
          ),
        ),
      );
}
