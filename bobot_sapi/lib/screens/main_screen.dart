import 'package:flutter/material.dart';

import 'input_sapi_screen.dart';
import 'update_sapi_screen.dart';
import 'history_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final _historyRefresh = ValueNotifier<int>(0);
  final _updateRefresh = ValueNotifier<int>(0);

  late final List<Widget> _screens = [
    const InputSapiScreen(),
    UpdateSapiScreen(refreshNotifier: _updateRefresh),
    HistoryScreen(refreshNotifier: _historyRefresh),
  ];

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      _updateRefresh.value++;
    }
    if (index == 2) {
      _historyRefresh.value++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor opsional, sesuaikan dengan warna background aplikasi kamu
      backgroundColor: const Color(0xFFFAFAFA), 
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      // Gunakan extendBody agar bayangan (shadow) dari floating navbar terlihat lebih menyatu
      extendBody: true, 
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final accentGreen = const Color(0xFF00A76E);

    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / 3;
          final capsuleW = itemWidth - 12;
          const capsuleH = 48.0;

          final icons = [Icons.add, Icons.refresh, Icons.history];
          final labels = ['Input', 'Update', 'History'];

          return SizedBox(
            height: 62,
            child: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(3, (index) {
                    return GestureDetector(
                      onTap: () => _onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: itemWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 16),
                            Icon(
                              icons[index],
                              color: Colors.black45,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: itemWidth * _selectedIndex + 6,
                  top: (62 - capsuleH) / 2,
                  child: GestureDetector(
                    onTap: () => _onTap(_selectedIndex),
                    child: Container(
                      width: capsuleW,
                      height: capsuleH,
                      decoration: BoxDecoration(
                        color: accentGreen,
                        borderRadius: BorderRadius.circular(capsuleH / 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icons[_selectedIndex], color: Colors.white, size: 22),
                          const SizedBox(width: 6),
                          Text(
                            labels[_selectedIndex],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}