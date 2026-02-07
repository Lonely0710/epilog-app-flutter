import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_snack_bar.dart';
import '../../../../core/domain/entities/media.dart';
import '../../../collections/domain/repositories/collection_repository.dart';
import '../widgets/rating_display_widget.dart';
import '../widgets/watch_status_bottom_sheet.dart';
import '../widgets/character_list_widget.dart';

/// Media detail page displaying full information about a movie/TV show/anime.
class MediaDetailPage extends StatefulWidget {
  final Media media;

  const MediaDetailPage({super.key, required this.media});

  @override
  State<MediaDetailPage> createState() => _MediaDetailPageState();
}

class _MediaDetailPageState extends State<MediaDetailPage> {
  final _repository = ConvexCollectionRepositoryImpl.instance;
  Stream<Media?>? _mediaStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    if (widget.media.id.isNotEmpty) {
      _mediaStream = _repository.watchMedia(widget.media.id);
    } else if (widget.media.sourceId.isNotEmpty && widget.media.sourceType.isNotEmpty) {
      _mediaStream = _repository.watchMediaBySource(widget.media.sourceId, widget.media.sourceType);
    } else {
      // Fallback if no ID and no Source info (unlikely)
      _mediaStream = Stream.value(widget.media);
    }
  }

  Future<void> _updateWatchStatus(Media currentMedia, String status) async {
    // Show feedback immediately
    if (mounted) {
      String statusText = '想看';
      IconData statusIcon = Icons.bookmark;
      Color statusColor = AppColors.starActive;

      switch (status) {
        case 'watching':
          statusText = '在看';
          statusIcon = Icons.play_circle;
          statusColor = Colors.blue;
          break;
        case 'watched':
          statusText = '看过';
          statusIcon = Icons.check_circle;
          statusColor = AppColors.success;
          break;
        case 'on_hold':
          statusText = '搁置';
          statusIcon = Icons.pause_circle;
          statusColor = Colors.grey;
          break;
      }

      AppSnackBar.show(
        context,
        type: SnackBarType.success,
        message: '已标记为$statusText',
        customIcon: Icon(statusIcon, color: statusColor, size: 24),
        customColor: statusColor,
      );
    }

    try {
      if (currentMedia.collectionId.isNotEmpty) {
        await _repository.updateWatchStatus(currentMedia.collectionId, status);
      } else {
        // If not collected yet, add it
        // Note: For search results, simple widget.media might lack source IDs if not parsed correctly,
        // but we assume updated parsing logic handles it.
        await _repository.addToCollection(widget.media, status: status);
      }
    } catch (e) {
      log('Error updating status: $e');
      if (mounted) {
        AppSnackBar.showError(context, message: '更新失败: $e');
      }
    }
  }

  void _showWatchStatusSheet(Media currentMedia) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WatchStatusBottomSheet(
        media: currentMedia,
        currentStatus: currentMedia.watchingStatus ?? 'wish',
        onStatusSelected: (status) {
          _updateWatchStatus(currentMedia, status);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showCategorySheet(Media currentMedia) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                '加入资料库',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildOption(
              context,
              iconWidget: Icon(Icons.movie_creation_outlined, color: AppTheme.primary, size: 20),
              label: 'Movie Library',
              onTap: () =>
                  _addToCollectionWithCategory(currentMedia, 'movie', 'Movie Library', 'assets/icons/ic_popcorn.png'),
            ),
            _buildOption(
              context,
              iconWidget: Icon(Icons.tv, color: AppTheme.primary, size: 20),
              label: 'TV Show',
              onTap: () => _addToCollectionWithCategory(currentMedia, 'tv', 'TV Show', 'assets/icons/ic_popcorn.png'),
            ),
            _buildOption(
              context,
              iconWidget: Image.asset('assets/icons/ic_bilibili.png', width: 20, height: 20),
              label: 'Anime Wall',
              onTap: () =>
                  _addToCollectionWithCategory(currentMedia, 'anime', 'Anime Wall', 'assets/icons/ic_bilibili.png'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required Widget iconWidget,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: iconWidget,
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Future<void> _addToCollectionWithCategory(
      Media currentMedia, String mediaType, String categoryLabel, String iconPath) async {
    // Show success feedback immediately
    AppSnackBar.show(
      context,
      type: SnackBarType.success,
      message: '已加入$categoryLabel想看',
      customIcon: Image.asset(
        iconPath,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
      ),
      customColor: AppTheme.primary,
    );

    try {
      // Determine preferred source type based on collection category:
      // - movie/tv: prefer TMDB as source
      // - anime: prefer Bangumi (bgm) as source
      String preferredSourceType;
      String preferredSourceId;
      String preferredSourceUrl;

      if (mediaType == 'anime') {
        // For anime, prefer Bangumi source
        preferredSourceType = 'bgm';
        if (currentMedia.sourceType == 'bgm') {
          preferredSourceId = currentMedia.sourceId;
          preferredSourceUrl = currentMedia.sourceUrl;
        } else {
          // Use current source ID but with bgm sourceType (fallback assumption)
          preferredSourceId = currentMedia.sourceId;
          preferredSourceUrl = 'https://bgm.tv/subject_search/${Uri.encodeComponent(currentMedia.titleZh)}?cat=2';
        }
      } else {
        // For movie/tv, prefer TMDB source
        preferredSourceType = 'tmdb';
        if (currentMedia.sourceType == 'tmdb') {
          preferredSourceId = currentMedia.sourceId;
          preferredSourceUrl = currentMedia.sourceUrl;
        } else {
          preferredSourceId = currentMedia.sourceId;
          preferredSourceUrl = 'https://www.themoviedb.org/$mediaType/${currentMedia.sourceId}';
        }
      }

      // Modify media with preferred source type
      final modifiedMedia = currentMedia.copyWith(
        mediaType: mediaType,
        sourceType: preferredSourceType,
        sourceId: preferredSourceId,
        sourceUrl: preferredSourceUrl,
      );

      await _repository.addToCollection(modifiedMedia, status: 'wish');
      // No setState needed, stream will update
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, message: '添加失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mediaStream == null) return const Center(child: CircularProgressIndicator()); // Should not happen

    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<Media?>(
      stream: _mediaStream,
      builder: (context, snapshot) {
        // Use latest media from stream, or fallback to widget.media
        final media = snapshot.data ?? widget.media;

        // If stream returned null (e.g. not found in DB), media is widget.media (uncollected)
        // If stream returned object (found), media is that object (collected)

        final currentIsCollected = media.isCollected;
        final currentWatchStatus = media.watchingStatus ?? 'wish';

        return Scaffold(
          backgroundColor: bgColor,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, media),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleRow(media, currentIsCollected, currentWatchStatus),
                      const SizedBox(height: 24),
                      RatingDisplayWidget(media: media),
                      const SizedBox(height: 32),

                      // Synopsis
                      Text(
                        '简介',
                        style: TextStyle(
                          fontFamily: AppTheme.primaryFont,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildExpandableSynopsis(media.summary),
                      const SizedBox(height: 32),

                      // Staff / Cast
                      if (media.mediaType == 'anime') ...[
                        _buildAnimeStaffSection(media),
                        CharacterListWidget(media: media),
                      ] else ...[
                        if (media.directors.isNotEmpty) ...[
                          _buildDirectorsSection(media),
                          const SizedBox(height: 24),
                        ],
                        if (media.actors.isNotEmpty) _buildActorsSection(media),
                      ],
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper methods...

  Widget _buildSliverAppBar(BuildContext context, Media media) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final buttonBg = isDark ? Colors.black.withValues(alpha: 0.5) : AppColors.surfaceElevated.withValues(alpha: 0.9);

    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.width * 1.5,
      pinned: true,
      backgroundColor: bgColor,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: buttonBg,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: media.posterUrl,
              child: CachedNetworkImage(
                imageUrl: media.posterUrl,
                fit: BoxFit.cover,
                // Ensure image covers the space completely
                alignment: Alignment.topCenter,
                placeholder: (context, url) => Container(
                  color: AppColors.surfaceDeep,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                errorWidget: (context, url, error) => Image.asset(
                  'assets/icons/ic_np_poster.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Gradient Overlay - Extended slightly to prevent "leakage"
            Positioned(
              bottom: -1, // Overlap slightly
              left: 0,
              right: 0,
              height: 250, // Increased height for better gradient smooth
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      bgColor.withValues(alpha: 0.6),
                      bgColor.withValues(alpha: 0.9),
                      bgColor,
                    ],
                    stops: const [0.0, 0.5, 0.8, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Text(
                media.titleOriginal.isNotEmpty ? media.titleOriginal : media.titleZh,
                style: TextStyle(
                  fontFamily: AppTheme.primaryFont,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : textColor, // Brighter in dark mode
                  shadows: [
                    Shadow(
                      color: isDark ? Colors.black : AppColors.surfaceElevated,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow(Media media, bool isCollected, String watchStatus) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? episodeText;
    if (media.mediaType == 'anime' || media.mediaType == 'tv') {
      episodeText = media.duration.isNotEmpty ? media.duration : '??';
      if (RegExp(r'^\d+$').hasMatch(episodeText)) {
        episodeText = '$episodeText集';
      } else {
        episodeText = episodeText.replaceAll('共', '');
      }
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            media.titleZh,
            style: TextStyle(
              fontFamily: AppTheme.primaryFont,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Movie Duration
        if (media.mediaType == 'movie' && media.duration.isNotEmpty)
          Row(
            children: [
              Icon(Icons.access_time, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 4),
              Text(
                media.duration,
                style: TextStyle(
                  fontFamily: AppTheme.primaryFont,
                  fontSize: 14,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),

        // TV/Anime Episode Count
        if (episodeText != null)
          Row(
            children: [
              Icon(Icons.layers_outlined, color: isDark ? Colors.white : AppColors.textPrimary, size: 20),
              const SizedBox(width: 4),
              Text(
                episodeText,
                style: TextStyle(
                  fontFamily: AppTheme.primaryFont,
                  fontSize: 18,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),

        InkWell(
          onTap: () {
            if (isCollected) {
              _showWatchStatusSheet(media);
            } else {
              _showCategorySheet(media);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              _getStatusIcon(isCollected, watchStatus),
              color: _getStatusColor(isCollected, watchStatus),
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimeStaffSection(Media media) {
    // Parse staff string: "Director Name / Original Name / Script Name"
    // Also handle if staff is empty or doesn't have enough parts
    log('Building Anime Staff Section. Staff string: "${media.staff}"');

    final staffParts = media.staff.split('/');
    final directorName = staffParts.isNotEmpty ? staffParts[0].trim() : '';
    final originalName = staffParts.length > 1 ? staffParts[1].trim() : '';
    final scriptName = staffParts.length > 2 ? staffParts[2].trim() : '';
    final charDesignName = staffParts.length > 3 ? staffParts[3].trim() : '';

    // If parsing failed to get any meaningful names (e.g. empty string),
    // try to fall back to the standard directors/actors lists if available.
    if (directorName.isEmpty && originalName.isEmpty && scriptName.isEmpty && charDesignName.isEmpty) {
      if (media.directors.isNotEmpty || media.actors.isNotEmpty) {
        log('Staff string parsing yielded nothing, falling back to standard directors/actors.');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (media.directors.isNotEmpty) ...[
              _buildDirectorsSection(media),
              const SizedBox(height: 24),
            ],
            if (media.actors.isNotEmpty) ...[
              _buildActorsSection(media),
              const SizedBox(height: 24),
            ],
          ],
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (directorName.isNotEmpty) ...[
          _buildStaffSectionTitle('导演', Icons.person_rounded, directorName),
          const SizedBox(height: 16),
        ],
        if (originalName.isNotEmpty) ...[
          _buildStaffSectionTitle('原作', Icons.book_rounded, originalName),
          const SizedBox(height: 16),
        ],
        if (scriptName.isNotEmpty) ...[
          _buildStaffSectionTitle('脚本', Icons.edit_rounded, scriptName),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildStaffSectionTitle(String title, IconData icon, String content) {
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
                icon,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDirectorsSection(Media media) {
    return _buildSectionWithChips(
      '导演',
      Icons.person_rounded,
      media.directors,
    );
  }

  Widget _buildActorsSection(Media media) {
    return _buildSectionWithChips(
      '主演',
      Icons.face_outlined,
      media.actors,
    );
  }

  Widget _buildSectionWithChips(String title, IconData icon, List<String> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;

    if (items.isEmpty) return const SizedBox.shrink();
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
                icon,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map((item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildExpandableSynopsis(String summary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (summary.isEmpty) return const SizedBox.shrink();
    return Text(
      summary,
      style: TextStyle(
        fontFamily: AppTheme.primaryFont,
        fontSize: 15,
        height: 1.6,
        color: isDark ? Colors.white70 : AppColors.textSecondary,
      ),
      maxLines: 6,
      overflow: TextOverflow.ellipsis,
    );
  }

  IconData _getStatusIcon(bool isCollected, String watchStatus) {
    if (!isCollected) return Icons.bookmark_border;
    switch (watchStatus) {
      case 'watching':
        return Icons.play_circle;
      case 'watched':
        return Icons.check_circle;
      case 'on_hold':
        return Icons.pause_circle;
      case 'wish':
      default:
        return Icons.bookmark;
    }
  }

  Color _getStatusColor(bool isCollected, String watchStatus) {
    if (!isCollected) return AppColors.starActive;
    switch (watchStatus) {
      case 'watching':
        return Colors.blue;
      case 'watched':
        return AppColors.success;
      case 'on_hold':
        return Colors.grey;
      case 'wish':
      default:
        return AppColors.starActive;
    }
  }
}
