// Platform tanpa dart:io (mis. web): sqflite tidak tersedia, jadi tidak ada
// yang perlu diinisialisasi. Aplikasi tetap berjalan dengan UI-nya.
Future<void> initDatabaseFactory() async {}
