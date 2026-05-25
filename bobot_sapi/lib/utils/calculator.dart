const double adgRealistis = 1.0;
const double targetDefaultSimmental = 750.0;

double hitungBobotSapi(double lingkarDada) {
  return ((lingkarDada + 22) * (lingkarDada + 22)) / 100;
}

double hitungEstimasiPakan(double bobotSapi) {
  return bobotSapi * 0.03;
}

double hitungSisaBobot(double bobotSekarang, double targetBobot) {
  final sisa = targetBobot - bobotSekarang;
  return sisa < 0 ? 0 : sisa;
}

double hitungWaktuPanenBulan(double bobotSekarang, double targetBobot) {
  final sisaBobot = hitungSisaBobot(bobotSekarang, targetBobot);
  return sisaBobot / (adgRealistis * 30);
}

DateTime hitungTanggalPanen(double waktuBulan) {
  final totalHari = (waktuBulan * 30).ceil();
  return DateTime.now().add(Duration(days: totalHari));
}

List<double> prediksiBobot6Bulan(double bobotSekarang) {
  return List.generate(6, (index) {
    final bulanKe = index + 1;
    return bobotSekarang + (adgRealistis * bulanKe * 30);
  });
}