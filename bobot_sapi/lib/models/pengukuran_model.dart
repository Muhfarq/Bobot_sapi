class PengukuranModel {
  final int? id;
  final int sapiId;
  final String tanggal;
  final double lingkarDada;
  final double bobotSekarang;
  final double estimasiPakan;
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
    required this.bobotSekarang,
    required this.estimasiPakan,
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
      'bobot_sekarang': bobotSekarang,
      'estimasi_pakan': estimasiPakan,
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
      lingkarDada: map['lingkar_dada'],
      bobotSekarang: map['bobot_sekarang'],
      estimasiPakan: map['estimasi_pakan'],
      targetBobot: map['target_bobot'],
      sisaBobot: map['sisa_bobot'],
      adg: map['adg'],
      estimasiBulan: map['estimasi_bulan'],
      tanggalPanen: map['tanggal_panen'],
    );
  }
}