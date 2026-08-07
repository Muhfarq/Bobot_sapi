import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/sapi_model.dart';
import 'form_update_sapi_screen.dart';

class UpdateSapiScreen extends StatefulWidget {
  final ValueNotifier<int>? refreshNotifier;
  const UpdateSapiScreen({super.key, this.refreshNotifier});

  @override
  State<UpdateSapiScreen> createState() => _UpdateSapiScreenState();
}

class _UpdateSapiScreenState extends State<UpdateSapiScreen> {
  final _searchController = TextEditingController();
  List<SapiModel> _daftarSapi = [];
  List<SapiModel> _filteredSapi = [];
  bool _isLoading = true;

  final Color primaryGreen = const Color(0xFF004D34);
  final Color lightCardGreen = const Color(0xFF80F3BD);
  final Color cardTextColor = const Color(0xFF004D34);
  final Color fieldColor = const Color(0xFFF2F2F2);

  @override
  void initState() {
    super.initState();
    _loadSapi();
    widget.refreshNotifier?.addListener(_loadSapi);
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_loadSapi);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSapi() async {
    final data = await DBHelper.instance.getAllSapi();
    setState(() {
      _daftarSapi = data;
      _filteredSapi = data;
      _isLoading = false;
    });
  }

  void _filterSapi(String keyword) {
    setState(() {
      _filteredSapi = _daftarSapi.where((sapi) {
        return sapi.namaSapi.toLowerCase().contains(keyword.toLowerCase());
      }).toList();
    });
  }

  void _pilihSapiAndNavigate(SapiModel sapi) async {
    // Berpindah ke Screen Baru khusus Form Update
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormUpdateSapiScreen(sapi: sapi),
      ),
    );

    if (result == true) {
      _loadSapi();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Update Sapi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryGreen,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : _daftarSapi.isEmpty
              ? const Center(child: Text('Belum ada data sapi.'))
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: fieldColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterSapi,
                          style: const TextStyle(fontSize: 16),
                          decoration: const InputDecoration(
                            hintText: 'Cari Sapi',
                            hintStyle: TextStyle(color: Colors.black45),
                            prefixIcon: Icon(Icons.search, color: Colors.black45),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Daftar Card Sapi
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filteredSapi.length,
                          itemBuilder: (context, index) {
                            final sapi = _filteredSapi[index];
                            return GestureDetector(
                              onTap: () => _pilihSapiAndNavigate(sapi),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: lightCardGreen,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      sapi.namaSapi,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: cardTextColor,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: cardTextColor,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}