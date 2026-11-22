import 'package:flutter/material.dart';

class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String hintText;
  final ValueChanged<T?>? onChanged;

  const AppDropdown({
    super.key,
    this.value,
    required this.items,
    required this.hintText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const hintStyle = TextStyle(
      color: Colors.black38,
      fontSize: 16,
      fontWeight: FontWeight.normal,
    );

    return DropdownButtonFormField<T>(
      // Kunci mengikuti nilai agar pilihan ikut reset saat nilai diubah dari luar.
      key: ValueKey<T?>(value),
      initialValue: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black45),
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      hint: Text(hintText, style: hintStyle),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: hintStyle,
        filled: true,
        fillColor: const Color(0xFFF2F2F2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
