import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';

class FilterBar extends StatelessWidget {
  final String currentType; // '电影' or '电视剧'
  final Function(String) onTypeChanged;
  final VoidCallback onFilterTap;
  final int? selectedYear;
  final String? selectedGenre;
  final VoidCallback? onYearClear;
  final VoidCallback? onGenreClear;

  const FilterBar({
    super.key,
    required this.currentType,
    required this.onTypeChanged,
    required this.onFilterTap,
    this.selectedYear,
    this.selectedGenre,
    this.onYearClear,
    this.onGenreClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTypeSelector(context),

          const SizedBox(width: 16),
          // Chips Area
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (selectedYear != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: selectedYear.toString(),
                        onDeleted: onYearClear,
                      ),
                    ),
                  if (selectedGenre != null)
                    _FilterChip(
                      label: selectedGenre!,
                      onDeleted: onGenreClear,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          GestureDetector(
            onTap: onFilterTap,
            child: Row(
              children: [
                Text('筛选',
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color)),
                const SizedBox(width: 4),
                Icon(Icons.filter_alt_rounded,
                    size: 18,
                    color: Theme.of(context).textTheme.bodyMedium?.color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(BuildContext context) {
    return Row(
      children: [
        _TypeItem(
          label: '电视剧',
          isSelected: currentType == '电视剧',
          onTap: () => onTypeChanged('电视剧'),
        ),
        const SizedBox(width: 20),
        _TypeItem(
          label: '电影',
          isSelected: currentType == '电影',
          onTap: () => onTypeChanged('电影'),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;

  const _FilterChip({required this.label, this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDeleted,
            child: const Icon(
              Icons.close,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).textTheme.bodyLarge?.color
                  : AppColors.textTertiary,
              fontFamily: AppTheme.primaryFont,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 2),
            // A small dot or indicator if needed, or simple text change as per 'content app' style
            // User example showed "▾", maybe we add that?
          ],
        ],
      ),
    );
  }
}
