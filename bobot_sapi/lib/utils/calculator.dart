const double adgRealistis = 1.0;
const double targetDefaultSimmental = 750.0;

// Rumus Baru (Menggunakan Lingkar Dada, Panjang Badan, dan Tinggi Gumba)
// double hitungBobotSapi(double lingkarDada, double panjangBadan, double tinggiGumba) {
//   return -736.634 +
//       (4.083793 * lingkarDada) +
//       (2.836318 * panjangBadan) +
//       (0.283673 * tinggiGumba);
// }

double hitungBobotSapi(double lingkarDada, double panjangBadan, double tinggiGumba) {
  final hasil = -736.634 +
      (4.083793 * lingkarDada) +
      (2.836318 * panjangBadan) +
      (0.283673 * tinggiGumba);
  return hasil < 0 ? 0 : hasil;
}

double hitungEstimasiPakan(double bobotSapi) {
  return bobotSapi * 0.03;
}

// Kadar bahan kering (BK) konsentrat: asumsi, ubah jika punya data pasti.
const double bkKonsentrat = 0.88;

double hitungBKHijauan(double beratSegar, double bkPersen) =>
    beratSegar * bkPersen / 100;

double hitungBKKonsentrat(double berat) => berat * bkKonsentrat;

// Rumus Panen Berdasar Hari: Bobot Awal + (ADG * Hari)
double hitungBobotPanenHari(double bobotAwal, int hari) {
  return bobotAwal + (adgRealistis * hari);
}

DateTime hitungTanggalPanenHari(int hari, {DateTime? tanggalUkur}) {
  final baseDate = tanggalUkur ?? DateTime.now();
  return baseDate.add(Duration(days: hari));
}

double hitungSisaBobot(double bobotSekarang, double targetBobot) {
  final sisa = targetBobot - bobotSekarang;
  return sisa < 0 ? 0 : sisa;
}

double hitungWaktuPanenBulan(double bobotSekarang, double targetBobot) {
  final sisaBobot = hitungSisaBobot(bobotSekarang, targetBobot);
  return sisaBobot / (adgRealistis * 30);
}

DateTime hitungTanggalPanen(double waktuBulan, {DateTime? tanggalUkur}) {
  final totalHari = (waktuBulan * 30).ceil();
  final baseDate = tanggalUkur ?? DateTime.now();
  return baseDate.add(Duration(days: totalHari));
}

List<double> prediksiBobotHari(double bobotSekarang, int goalHari) {
  if (goalHari <= 0) goalHari = 60;
  return List.generate(6, (index) {
    final stepHari = (goalHari / 5) * index;
    final hasil = bobotSekarang + (adgRealistis * stepHari);
    return hasil < 0 ? 0 : hasil;
  });
}