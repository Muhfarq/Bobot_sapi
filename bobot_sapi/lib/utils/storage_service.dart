// lib/utils/storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sapi.dart';

class StorageService {
  static const _key = 'daftar_sapi';

  static Future<List<Sapi>> loadSapi() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final List decoded = jsonDecode(raw);
    return decoded.map((e) => Sapi.fromJson(e)).toList();
  }

  static Future<void> saveSapi(List<Sapi> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list.map((s) => s.toJson()).toList()));
  }

  static Future<void> tambahSapi(Sapi sapi) async {
    final list = await loadSapi();
    list.add(sapi);
    await saveSapi(list);
  }

  static Future<void> updateSapi(Sapi updated) async {
    final list = await loadSapi();
    final idx = list.indexWhere((s) => s.id == updated.id);
    if (idx != -1) list[idx] = updated;
    await saveSapi(list);
  }

  static Future<void> hapusPengukuran(String sapiId, String pengukuranId) async {
    final list = await loadSapi();
    final sapi = list.firstWhere((s) => s.id == sapiId);
    sapi.riwayat.removeWhere((p) => p.id == pengukuranId);
    await saveSapi(list);
  }
}
