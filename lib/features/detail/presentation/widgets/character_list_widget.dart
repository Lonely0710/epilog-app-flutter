import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/domain/entities/character.dart';
import '../../../../core/domain/entities/media.dart';
import '../../../../core/services/media_providers/bangumi_service.dart';

class CharacterListWidget extends StatefulWidget {
  final Media media;

  const CharacterListWidget({super.key, required this.media});

  @override
  State<CharacterListWidget> createState() => _CharacterListWidgetState();
}

class _CharacterListWidgetState extends State<CharacterListWidget> {
  final _bangumiService = BangumiService();
  List<Character> _characters = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    String? sourceId;

    // 1. Check if the media object itself has the BGM ID
    if (widget.media.sourceType == 'bgm' && widget.media.sourceId.isNotEmpty) {
      sourceId = widget.media.sourceId;
    } else {
      // 2. If not, try to find it via media_source table (User Instruction)
      // We need a way to link to media_id.
      // Using collectionId if available is one path.
      if (widget.media.collectionId.isNotEmpty) {
        try {
          final supabase = Supabase.instance.client;
          // Get media_id from collection
          final collectionRes =
              await supabase.from('collections').select('media_id').eq('id', widget.media.collectionId).maybeSingle();

          if (collectionRes != null) {
            final mediaId = collectionRes['media_id'];
            // Get source_id from media_source
            final sourceRes = await supabase
                .from('media_source')
                .select('source_id')
                .eq('media_id', mediaId)
                .eq('source_type', 'bgm')
                .maybeSingle();

            if (sourceRes != null) {
              sourceId = sourceRes['source_id'];
            }
          }
        } catch (e) {
          log('Error resolving BGM ID from DB: $e');
        }
      }
    }

    if (sourceId == null || sourceId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Fail silently or show empty
        });
      }
      return;
    }

    try {
      final chars = await _bangumiService.getCharacters(sourceId);
      if (mounted) {
        setState(() {
          _characters = chars;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Error loading characters: $e');
      if (mounted) {
        setState(() {
          _error = '加载失败';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_characters.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_alt_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '角色介绍',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220, // Adjust height based on card size
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            scrollDirection: Axis.horizontal,
            itemCount: _characters.length,
            separatorBuilder: (ctx, i) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final char = _characters[index];
              return _buildCharacterCard(context, char);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterCard(BuildContext context, Character char) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2);

    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: char.imageUrl,
              height: 140, // Taller image
              width: 120,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),
              errorWidget: (context, url, error) => Container(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                child: const Icon(Icons.person, color: Colors.grey),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    char.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (char.role.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        char.role,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                  if (char.cv.isNotEmpty) ...[
                    const Spacer(),
                    Text(
                      'CV ${char.cv}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
