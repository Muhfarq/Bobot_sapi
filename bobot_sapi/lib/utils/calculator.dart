const double adgRealistis = 1.0;
const double targetDefaultSimmental = 750.0;

// Rumus Schoorl (Menggunakan Lingkar Dada)
double hitungBobotSapi(double lingkarDada) {
  return ((lingkarDada + 22) * (lingkarDada + 22)) / 100;
}

double hitungEstimasiPakan(double bobotSapi) {
  return bobotSapi * 0.03;
}

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

List<double> prediksiBobot6Bulan(double bobotSekarang) {
  return List.generate(6, (index) {
    final bulanKe = index + 1;
    return bobotSekarang + (adgRealistis * bulanKe * 30);
  });
}