// lib/widgets/extracted_data_chip.dart

import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ExtractedDataChip extends StatelessWidget {
  final String label;
  final bool extracted;

  const ExtractedDataChip({
    super.key,
    required this.label,
    this.extracted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: extracted
            ? AppTheme.success.withOpacity(0.15)
            : AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: extracted
              ? AppTheme.success.withOpacity(0.4)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (extracted)
            const Icon(Icons.auto_awesome_rounded,
                color: AppTheme.success, size: 12)
          else
            const Icon(Icons.edit_rounded, color: AppTheme.textHint, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: extracted ? AppTheme.success : AppTheme.textHint,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
