class PengukuranModel {
  final int? id;
  final int sapiId;
  final String tanggal;
  final double lingkarDada;
  final double panjangBadan;
  final double bobotSekarang;
  final double estimasiPakan;
  final int goalHari;
  final double targetBobot;
  final double sisaBobot;
  final double adg;
  final double estimasiBulan;
  final String tanggalPanen;

  PengukuranModel({
    this.id,
    required this.sapiId,
    required this.tanggal,
    required this.lingkarDada,
    required this.panjangBadan,
    required this.bobotSekarang,
    required this.estimasiPakan,
    required this.goalHari,
    required this.targetBobot,
    required this.sisaBobot,
    required this.adg,
    required this.estimasiBulan,
    required this.tanggalPanen,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sapi_id': sapiId,
      'tanggal': tanggal,
      'lingkar_dada': lingkarDada,
      'panjang_badan': panjangBadan,
      'bobot_sekarang': bobotSekarang,
      'estimasi_pakan': estimasiPakan,
      'goal_hari': goalHari,
      'target_bobot': targetBobot,
      'sisa_bobot': sisaBobot,
      'adg': adg,
      'estimasi_bulan': estimasiBulan,
      'tanggal_panen': tanggalPanen,
    };
  }

  factory PengukuranModel.fromMap(Map<String, dynamic> map) {
    return PengukuranModel(
      id: map['id'],
      sapiId: map['sapi_id'],
      tanggal: map['tanggal'],
      lingkarDada: (map['lingkar_dada'] as num).toDouble(),
      panjangBadan: (map['panjang_badan'] as num? ?? 0.0).toDouble(),
      bobotSekarang: (map['bobot_sekarang'] as num).toDouble(),
      estimasiPakan: (map['estimasi_pakan'] as num).toDouble(),
      goalHari: map['goal_hari'] ?? 0,
      targetBobot: (map['target_bobot'] as num).toDouble(),
      sisaBobot: (map['sisa_bobot'] as num).toDouble(),
      adg: (map['adg'] as num).toDouble(),
      estimasiBulan: (map['estimasi_bulan'] as num).toDouble(),
      tanggalPanen: map['tanggal_panen'],
    );
  }
}