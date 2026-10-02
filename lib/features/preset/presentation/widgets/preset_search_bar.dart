import 'package:flutter/material.dart';
import 'package:aig/core/theme/app_design_tokens.dart';

class PresetSearchBar extends StatelessWidget {
  const PresetSearchBar({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search presets, categories, descriptions...',
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.search_rounded),
      ),
    );
  }
}
