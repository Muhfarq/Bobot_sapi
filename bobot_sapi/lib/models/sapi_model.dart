class SapiModel {
  final int? id;
  final String namaSapi;
  final String tanggalMasuk;

  SapiModel({
    this.id,
    required this.namaSapi,
    required this.tanggalMasuk,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_sapi': namaSapi,
      'tanggal_masuk': tanggalMasuk,
    };
  }

  factory SapiModel.fromMap(Map<String, dynamic> map) {
    return SapiModel(
      id: map['id'],
      namaSapi: map['nama_sapi'],
      tanggalMasuk: map['tanggal_masuk'],
    );
  }
}