//test

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/sapi.dart';
import '../utils/app_theme.dart';
import '../utils/storage_service.dart';

class UpdateBobotScreen extends StatefulWidget {
  const UpdateBobotScreen({super.key});

  @override
  State<UpdateBobotScreen> createState() => _UpdateBobotScreenState();
}

class _UpdateBobotScreenState extends State<UpdateBobotScreen> {
  List<Sapi> _daftarSapi = [];
  Sapi? _sapiDipilih;
  final _lingkarDadaCtrl = TextEditingController();
  final _panjangBadanCtrl = TextEditingController();
  final _targetBobotCtrl = TextEditingController(text: '500');
  DateTime _tanggal = DateTime.now();
  PengukuranSapi? _hasilHitung;

  @override
  void initState() {
    super.initState();
    _loadSapi();
  }

  @override
  void dispose() {
    _lingkarDadaCtrl.dispose();
    _panjangBadanCtrl.dispose();
    _targetBobotCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSapi() async {
    final list = await StorageService.loadSapi();
    setState(() => _daftarSapi = list);
  }

  void _pilihSapi(Sapi sapi) {
    setState(() {
      _sapiDipilih = sapi;
      _targetBobotCtrl.text = sapi.targetBobot.toString();
      _hasilHitung = null;
      _lingkarDadaCtrl.clear();
      _panjangBadanCtrl.clear();
    });
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

    setState(() {
      _hasilHitung = PengukuranSapi(
        id: const Uuid().v4(),
        tanggal: _tanggal,
        lingkarDada: ld,
        panjangBadan: pb,
        targetBobot: target,
      );
    });
  }

  Future<void> _simpan() async {
    if (_sapiDipilih == null || _hasilHitung == null) return;

    _sapiDipilih!.riwayat.add(_hasilHitung!);
    _sapiDipilih!.targetBobot = _hasilHitung!.targetBobot;
    await StorageService.updateSapi(_sapiDipilih!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Update berhasil disimpan!'),
        backgroundColor: AppColors.hijau,
      ),
    );

    setState(() {
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

  void _showPilihSapiDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Pilih Sapi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: _daftarSapi.isEmpty
                  ? const Center(child: Text('Belum ada data sapi'))
                  : ListView.builder(
                      controller: controller,
                      itemCount: _daftarSapi.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (_, i) {
                        final s = _daftarSapi[i];
                        return GestureDetector(
                          onTap: () {
                            _pilihSapi(s);
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.hijauCard,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.idNama,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.gelap,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(s.tanggalMasuk),
                                  style: const TextStyle(
                                    color: AppColors.hijauText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
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
            if (_hasilHitung != null) ...[
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
                'Update Data Sapi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gelap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _label('Pilih Sapi'),
          GestureDetector(
            onTap: _showPilihSapiDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.abuMuda,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _sapiDipilih?.idNama ?? 'Tap untuk pilih sapi...',
                      style: TextStyle(
                        fontSize: 15,
                        color: _sapiDipilih != null
                            ? AppColors.gelap
                            : AppColors.abu,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppColors.abu),
                ],
              ),
            ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.hijauCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hijauMuda),
      ),
      child: Column(
        children: [
          Row(
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
                      ),
                    ),
                    const Text(
                      'Estimasi Bobot',
                      style: TextStyle(color: AppColors.hijauText, fontSize: 12),
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
                        ),
                      ),
                      const Text(
                        'Estimasi Pakan',
                        style: TextStyle(color: AppColors.hijauText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.hijau,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: '${h.bulanOptimis}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.putih,
                      ),
                    ),
                    const TextSpan(
                      text: ' Bulan',
                      style: TextStyle(fontSize: 18, color: AppColors.putih),
                    ),
                  ]),
                ),
                Text(h.statusPanen,
                    style: const TextStyle(color: AppColors.hijauMuda)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.gelap)),
      );
}
