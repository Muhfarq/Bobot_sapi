import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class StatusBanner extends StatelessWidget {
  final bool success;
  final String title;
  final String message;

  const StatusBanner({
    super.key,
    required this.success,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = success ? AppColors.successText : AppColors.dangerTitle;
    final messageColor = success ? AppColors.successText : AppColors.dangerText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: success ? AppColors.successBg : AppColors.dangerBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: success ? AppColors.successIcon : AppColors.dangerIcon,
              shape: BoxShape.circle,
            ),
            child: Icon(
              success ? Icons.check : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(fontSize: 12, color: messageColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
