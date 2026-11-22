import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Android/iOS tetap memakai factory bawaan plugin sqflite. FFI hanya dipakai
// di desktop (Windows/Linux/macOS) agar database lokal tetap berfungsi offline.
Future<void> initDatabaseFactory() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
