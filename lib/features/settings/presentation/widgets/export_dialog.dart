import 'dart:io';
import 'dart:ui' as import_ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/services/export_service.dart';

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  bool _isExportAll = true;
  String _selectedType = 'tv';
  bool _isExporting = false;

  final ExportService _exportService = ExportService();

  final Map<String, String> _typeLabels = {
    'tv': '电视剧',
    'movie': '电影',
    'anime': '动漫',
  };

  void _handleExport() async {
    setState(() => _isExporting = true);

    try {
      List<String>? mediaTypes;
      if (!_isExportAll) {
        mediaTypes = [_selectedType];
      }

      final File csvFile =
          await _exportService.exportCollections(mediaTypes: mediaTypes);

      if (mounted) {
        // Share the file
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(csvFile.path)]);
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showTypePicker(BuildContext context) {
    final types = _typeLabels.keys.toList();
    final initialIndex = types.indexOf(_selectedType);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pickerBg = isDark ? const Color(0xFF1A2A3A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: pickerBg.withValues(alpha: isDark ? 0.95 : 0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: import_ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                  // Toolbar
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: pickerBg.withValues(alpha: isDark ? 0.8 : 0.5),
                      border: Border(
                          bottom: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.2))),
                    ),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Text(
                        '完成',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: AppTheme.primaryFont,
                        ),
                      ),
                    ),
                  ),
                  // Picker
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 40,
                      scrollController: FixedExtentScrollController(
                        initialItem: initialIndex >= 0 ? initialIndex : 0,
                      ),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedType = types[index];
                        });
                      },
                      children: types.map((type) {
                        return Center(
                          child: Text(
                            _typeLabels[type]!,
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: AppTheme.primaryFont,
                              color: textColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: dialogBg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.file_upload_outlined,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '数据导出',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Divider
            Container(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 20),

            // Options
            _buildRadioOption(
              title: '导出全部',
              value: true,
            ),
            _buildRadioOption(
              title: '按类型导出',
              value: false,
            ),

            // Partial Options Picker Trigger
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(left: 36.0, top: 4, right: 12),
                child: GestureDetector(
                  onTap: () => _showTypePicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _typeLabels[_selectedType] ?? '选择类型',
                          style: TextStyle(
                            fontSize: 15,
                            color: textColor,
                            fontFamily: AppTheme.primaryFont,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            color: isDark ? Colors.grey[400] : Colors.grey,
                            size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              crossFadeState: _isExportAll
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 300),
            ),

            const SizedBox(height: 28),

            // Buttons
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Center(
                        child: Text(
                          '取消',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Export Button
                Expanded(
                  child: GestureDetector(
                    onTap: _isExporting ? null : _handleExport,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isExporting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '导出',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption({required String title, required bool value}) {
    final isSelected = _isExportAll == value;
    return GestureDetector(
      onTap: () => setState(() => _isExportAll = value),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: AppTheme.primary),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
