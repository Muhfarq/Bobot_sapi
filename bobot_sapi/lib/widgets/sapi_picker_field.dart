import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/db_helper.dart';
import '../models/sapi_model.dart';
import 'app_text_field.dart';

class SapiPickerField extends StatelessWidget {
  final SapiModel? value;
  final ValueChanged<SapiModel?> onChanged;

  const SapiPickerField({
    super.key,
    this.value,
    required this.onChanged,
  });

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<SapiModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SapiPickerSheet(),
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;

    return GestureDetector(
      onTap: () => _openPicker(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 51),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? value!.namaSapi : 'Pilih Sapi',
                overflow: TextOverflow.ellipsis,
                style: hasValue
                    ? const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      )
                    : const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Colors.black38,
                      ),
              ),
            ),
            if (hasValue) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onChanged(null),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 18, color: Colors.black45),
                ),
              ),
            ],
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}

class _SapiPickerSheet extends StatefulWidget {
  const _SapiPickerSheet();

  @override
  State<_SapiPickerSheet> createState() => _SapiPickerSheetState();
}

class _SapiPickerSheetState extends State<_SapiPickerSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<SapiModel> _sapiList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSapi();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSapi({bool showLoading = false}) async {
    if (showLoading) setState(() => _loading = true);

    final keyword = _searchController.text.trim();
    final list = keyword.isEmpty
        ? await DBHelper.instance.getAllSapi()
        : await DBHelper.instance.searchSapi(keyword);

    if (!mounted) return;
    setState(() {
      _sapiList = list;
      _loading = false;
    });
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _loadSapi(),
    );
  }

  String _formatTanggal(String value) {
    final date = DateTime.tryParse(value);
    return date == null ? value : DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pilih Sapi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF005C3A),
            ),
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _searchController,
            hintText: 'Cari ID/Nama Sapi',
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _sapiList.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.trim().isEmpty
                              ? 'Belum ada data sapi'
                              : 'Sapi tidak ditemukan',
                          style: const TextStyle(color: Colors.black45),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _sapiList.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final sapi = _sapiList[index];
                          return ListTile(
                            title: Text(
                              sapi.namaSapi,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Masuk ${_formatTanggal(sapi.tanggalMasuk)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () => Navigator.of(context).pop(sapi),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
