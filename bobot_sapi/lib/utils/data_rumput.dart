class RumputItem {
  final String nama;
  final String umur;
  final double bk; // Bahan kering (%)
  final double? pk; // Protein kasar (% BK)
  final double? sk; // Serat kasar (% BK)

  const RumputItem({
    required this.nama,
    required this.umur,
    required this.bk,
    this.pk,
    this.sk,
  });

  String get label => '$nama ($umur)';
}

const List<RumputItem> daftarRumput = [
  RumputItem(
    nama: 'Rumput gajah',
    umur: '15–28 hari, segar',
    bk: 16,
    pk: 11.3,
  ),
  RumputItem(
    nama: 'Rumput gajah',
    umur: '43–56 hari, segar',
    bk: 18,
    pk: 8.9,
    sk: 32.2,
  ),
  RumputItem(
    nama: 'Rumput gajah',
    umur: '57–70 hari, segar',
    bk: 21,
    pk: 8.1,
    sk: 32.9,
  ),
  RumputItem(
    nama: 'Rumput benggala',
    umur: '15–28 hari, segar',
    bk: 20,
    pk: 13.0,
    sk: 30.5,
  ),
  RumputItem(
    nama: 'Rumput benggala',
    umur: '43–56 hari, segar',
    bk: 21,
    pk: 10.0,
    sk: 38.1,
  ),
  RumputItem(
    nama: 'Rumput benggala',
    umur: 'Tua, segar',
    bk: 26,
    pk: 5.0,
    sk: 40.0,
  ),
  RumputItem(
    nama: 'Rumput setaria',
    umur: '57–70 hari, segar',
    bk: 25,
    pk: 3.2,
    sk: 30.8,
  ),
  RumputItem(
    nama: 'Rumput setaria',
    umur: 'Tua, segar',
    bk: 21,
    pk: 5.2,
    sk: 39.5,
  ),
  RumputItem(
    nama: 'Rumput signal',
    umur: '15–28 hari, segar',
    bk: 17,
    pk: 10.3,
    sk: 34.5,
  ),
  RumputItem(
    nama: 'Rumput signal',
    umur: '43–56 hari, segar',
    bk: 19,
    pk: 7.0,
    sk: 35.1,
  ),
  RumputItem(
    nama: 'Rumput signal',
    umur: '57–70 hari, segar',
    bk: 21,
    pk: 4.7,
    sk: 37.9,
  ),
  RumputItem(
    nama: 'Rumput signal',
    umur: 'Tua, segar',
    bk: 24,
    pk: 2.9,
    sk: 37.9,
  ),
  RumputItem(
    nama: 'Rumput para',
    umur: '15–28 hari, segar',
    bk: 20,
    pk: 12.6,
    sk: 30.7,
  ),
  RumputItem(
    nama: 'Rumput para',
    umur: '43–56 hari, segar',
    bk: 21,
    pk: 10.5,
    sk: 29.5,
  ),
  RumputItem(
    nama: 'Rumput grinting',
    umur: '15–28 hari, segar',
    bk: 30,
    pk: 12.6,
    sk: 30.9,
  ),
  RumputItem(
    nama: 'Rumput grinting',
    umur: '43–56 hari, segar',
    bk: 31,
    pk: 11.9,
    sk: 29.7,
  ),
  RumputItem(
    nama: 'Rumput grinting',
    umur: 'Tua, segar',
    bk: 35,
    pk: 10.3,
    sk: 28.0,
  ),
  RumputItem(
    nama: 'Rumput pangola',
    umur: '15–28 hari, segar',
    bk: 18,
    pk: 11.0,
    sk: 31.9,
  ),
  RumputItem(
    nama: 'Rumput pangola',
    umur: '43–56 hari, segar',
    bk: 23,
    pk: 8.3,
    sk: 33.5,
  ),
  RumputItem(
    nama: 'Rumput pangola',
    umur: 'Tua, segar',
    bk: 40,
    pk: 5.8,
    sk: 40.8,
  ),
  RumputItem(
    nama: 'Alang-alang',
    umur: '15–28 hari, segar',
    bk: 23,
    pk: 12.2,
    sk: 35.0,
  ),
  RumputItem(
    nama: 'Alang-alang',
    umur: '43–56 hari, segar',
    bk: 26,
    pk: 6.5,
    sk: 37.3,
  ),
  RumputItem(
    nama: 'Alang-alang',
    umur: 'Tua, segar',
    bk: 50,
    pk: 5.1,
    sk: 35.4,
  ),
  RumputItem(
    nama: 'Tebon jagung',
    umur: '43–56 hari, segar',
    bk: 19,
    pk: 7.9,
    sk: 30.5,
  ),
  RumputItem(
    nama: 'Tebon jagung',
    umur: '57–70 hari, segar',
    bk: 22,
    pk: 8.6,
    sk: 29.1,
  ),
  RumputItem(
    nama: 'Tebon jagung',
    umur: 'Tanpa tongkol, segar',
    bk: 20,
    pk: 5.5,
    sk: 29.5,
  ),
  RumputItem(
    nama: 'Tebon jagung',
    umur: 'Tanpa tongkol, kering matahari',
    bk: 86,
    pk: 7.0,
    sk: 33.8,
  ),
  RumputItem(
    nama: 'Jerami padi (tanpa malai)',
    umur: 'Segar',
    bk: 40,
    pk: 4.3,
    sk: 33.8,
  ),
  RumputItem(
    nama: 'Jerami padi (tanpa malai)',
    umur: 'Kering matahari',
    bk: 86,
    pk: 3.7,
    sk: 35.9,
  ),
];
