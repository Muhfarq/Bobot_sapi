// lib/models/sapi.dart

class Sapi {
  final String id;
  String nama;
  final DateTime tanggalMasuk;
  double targetBobot;
  List<PengukuranSapi> riwayat;

  Sapi({
    required this.id,
    required this.nama,
    required this.tanggalMasuk,
    this.targetBobot = 500,
    List<PengukuranSapi>? riwayat,
  }) : riwayat = riwayat ?? [];

  String get idNama => '$id$nama';

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'tanggalMasuk': tanggalMasuk.toIso8601String(),
        'targetBobot': targetBobot,
        'riwayat': riwayat.map((r) => r.toJson()).toList(),
      };

  factory Sapi.fromJson(Map<String, dynamic> json) => Sapi(
        id: json['id'],
        nama: json['nama'],
        tanggalMasuk: DateTime.parse(json['tanggalMasuk']),
        targetBobot: (json['targetBobot'] as num).toDouble(),
        riwayat: (json['riwayat'] as List)
            .map((r) => PengukuranSapi.fromJson(r))
            .toList(),
      );

  PengukuranSapi? get pengukuranTerakhir =>
      riwayat.isNotEmpty ? riwayat.last : null;
}

class PengukuranSapi {
  final String id;
  final DateTime tanggal;
  final double lingkarDada;
  final double panjangBadan;
  final double targetBobot;

  PengukuranSapi({
    required this.id,
    required this.tanggal,
    required this.lingkarDada,
    required this.panjangBadan,
    required this.targetBobot,
  });

  // Rumus Schoorl: BB = ((LD + 22)^2) / 100
  double get estimasiBobot {
    if (lingkarDada == 0) return 0;
    return ((lingkarDada + 22) * (lingkarDada + 22)) / 100;
  }

  // Estimasi pakan harian: 2-3% dari bobot badan
  double get estimasiPakan => estimasiBobot * 0.03;

  // Estimasi bulan menuju target (ADG sapi ~0.5 kg/hari = 15 kg/bulan)
  int get estimasiBulanPanen {
    final selisih = targetBobot - estimasiBobot;
    if (selisih <= 0) return 0;
    return (selisih / 15).ceil();
  }

  String get statusPanen {
    final bulan = estimasiBulanPanen;
    if (bulan <= 4) return 'Sangat Optimis';
    if (bulan <= 6) return 'Optimis';
    if (bulan <= 8) return 'Pesimis';
    return 'Sangat Pesimis';
  }

  int get bulanOptimis => estimasiBulanPanen;
  int get bulanPesimis => (estimasiBulanPanen * 1.3).ceil();

  Map<String, dynamic> toJson() => {
        'id': id,
        'tanggal': tanggal.toIso8601String(),
        'lingkarDada': lingkarDada,
        'panjangBadan': panjangBadan,
        'targetBobot': targetBobot,
      };

  factory PengukuranSapi.fromJson(Map<String, dynamic> json) => PengukuranSapi(
        id: json['id'],
        tanggal: DateTime.parse(json['tanggal']),
        lingkarDada: (json['lingkarDada'] as num).toDouble(),
        panjangBadan: (json['panjangBadan'] as num).toDouble(),
        targetBobot: (json['targetBobot'] as num).toDouble(),
      );
}
