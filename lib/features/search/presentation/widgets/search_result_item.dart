import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/domain/entities/media.dart';
import 'package:drama_tracker_flutter/features/search/presentation/widgets/circular_rating.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/presentation/pages/web_browser_page.dart';
import '../../../../core/presentation/widgets/app_snack_bar.dart';
import '../../../../features/collections/data/repositories/collection_repository_impl.dart';

class SearchResultItem extends StatelessWidget {
  final Media result;
  final VoidCallback? onTap;
  final String searchType;

  const SearchResultItem({
    super.key,
    required this.result,
    this.onTap,
    this.searchType = 'anime',
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: result.posterUrl,
                width: 80,
                height: 115,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 80,
                  height: 115,
                  color: AppColors.placeholder,
                ),
                errorWidget: (context, url, error) => Container(
                  width: 80,
                  height: 115,
                  color: AppColors.placeholder,
                  child: Icon(Icons.broken_image, color: AppColors.textTertiary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row: Title + Original Title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          result.titleZh,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.titleOriginal,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Summary
                  if (result.summary.isNotEmpty) ...[
                    Text(
                      result.summary,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                  ] else ...[
                    const SizedBox(height: 6),
                  ],

                  // Year & Duration Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        result.year,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          fontFamily: AppTheme.primaryFont,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${result.releaseDate}   ${result.duration}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w300,
                            fontFamily: AppTheme.primaryFont,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Media Tag for Movie/TV
                      if (searchType == 'movie') ...[
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            result.mediaType == 'tv' ? 'TV' : 'MOVIE',
                            style: const TextStyle(
                              color: AppColors.textOnPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Rating Row with Site Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // TMDb Rating
                      if (result.ratingImdb > 0) ...[
                        Image.asset(
                          'assets/icons/ic_tmdb.png',
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 4),
                        CircularRating(rating: result.ratingImdb, size: 28),
                        const SizedBox(width: 12),
                      ],

                      // Maoyan Rating
                      if (result.ratingMaoyan > 0) ...[
                        Image.asset(
                          'assets/icons/ic_maoyan.png',
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 4),
                        CircularRating(rating: result.ratingMaoyan, size: 28),
                        const SizedBox(width: 12),
                      ],

                      // Douban Rating
                      if (result.ratingDouban > 0) ...[
                        Image.asset(
                          'assets/icons/ic_douban_green.png',
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 4),
                        CircularRating(rating: result.ratingDouban, size: 28),
                        const SizedBox(width: 12),
                      ],

                      // Bangumi Rating
                      if (result.ratingBangumi > 0) ...[
                        Image.asset(
                          'assets/icons/ic_bangumi.png',
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 4),
                        CircularRating(rating: result.ratingBangumi, size: 28),
                        const SizedBox(width: 12),
                      ],

                      // N/A if no ratings
                      if (result.ratingImdb <= 0 &&
                          result.ratingMaoyan <= 0 &&
                          result.ratingDouban <= 0 &&
                          result.ratingBangumi <= 0) ...[
                        Image.asset(
                          _getIconPath(result.sourceType),
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const Spacer(),

                      InkWell(
                        onTap: () {
                          // Determine URL based on source
                          String url = result.sourceUrl;
                          if (url.isEmpty) {
                            if (result.sourceType == 'douban') {
                              url = 'https://movie.douban.com/subject/${result.sourceId}';
                            } else if (result.sourceType == 'bgm') {
                              url = 'https://chii.in/subject/${result.sourceId}';
                            } else if (result.sourceType == 'maoyan') {
                              url = 'https://m.maoyan.com/movie/${result.sourceId}';
                            } else if (result.sourceType == 'tmdb') {
                              url = 'https://www.themoviedb.org/${result.mediaType}/${result.sourceId}';
                            }
                          }

                          context.push(
                            '/webview',
                            extra: WebBrowserPageArgs.fromSiteType(
                              siteType: _mapSourceToSiteType(result.sourceType),
                              url: url,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primary, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.send_rounded,
                                size: 14,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'SITE',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  fontFamily: AppTheme.primaryFont,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Staff Information
                  if (searchType == 'movie') ...[
                    // Directors
                    Row(
                      children: [
                        Icon(Icons.videocam, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            result.directors.isNotEmpty ? result.directors.join(' / ') : '暂无导演信息',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Actors
                    Row(
                      children: [
                        Icon(Icons.face_outlined, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            result.actors.isNotEmpty ? result.actors.join(' / ') : '暂无演员信息',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _CollectionStar(media: result),
                      ],
                    ),
                  ] else ...[
                    // Anime Style (Single Line)
                    Row(
                      children: [
                        const Icon(Icons.face_outlined, size: 16, color: Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            result.staff,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _CollectionStar(media: result),
                      ],
                    )
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getIconPath(String sourceType) {
    switch (sourceType) {
      case 'douban':
        return 'assets/icons/ic_douban_green.png';
      case 'tmdb':
        return 'assets/icons/ic_tmdb.png';
      case 'bgm':
        return 'assets/icons/ic_bangumi.png';
      case 'maoyan':
        return 'assets/icons/ic_maoyan.png';
      default:
        return 'assets/icons/ic_bangumi.png';
    }
  }

  SiteType _mapSourceToSiteType(String sourceType) {
    if (sourceType == 'douban') return SiteType.douban;
    if (sourceType == 'bgm') return SiteType.bangumi;
    if (sourceType == 'tmdb') return SiteType.tmdb;
    if (sourceType == 'maoyan') return SiteType.maoyan;
    return SiteType.other;
  }
}

class _CollectionStar extends StatefulWidget {
  final Media media;
  const _CollectionStar({required this.media});

  @override
  State<_CollectionStar> createState() => _CollectionStarState();
}

class _CollectionStarState extends State<_CollectionStar> {
  bool _isLoading = false;
  bool _isCollected = false;
  String? _collectionId;
  final _repo = CollectionRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final id = await _repo.checkCollectionStatus(widget.media.sourceId, widget.media.sourceType);
      if (mounted && id != null) {
        setState(() {
          _isCollected = true;
          _collectionId = id;
        });
      }
    } catch (e) {
      // Ignore errors for status check
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: Padding(
          padding: EdgeInsets.all(4.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(12),
      child: Icon(
        _isCollected ? Icons.star_rounded : Icons.star_border_rounded,
        color: _getStatusColor(),
        size: 24,
      ),
    );
  }

  Future<void> _handleTap() async {
    setState(() => _isLoading = true);
    try {
      if (_isCollected) {
        // Toggle Remove
        if (_collectionId != null) {
          await _repo.removeFromCollection(_collectionId!);
        }
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isCollected = false;
            _collectionId = null;
          });
          AppSnackBar.showInfo(context, '已从收藏中移除');
        }
      } else {
        // Toggle Add (Default Wish)
        final newId = await _repo.addToCollection(widget.media, status: 'wish');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isCollected = true;
            _collectionId = newId;
          });
          AppSnackBar.showSuccess(context, '已加入想看');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.showError(context, message: '操作失败: $e');
      }
    }
  }

  Color _getStatusColor() {
    if (!_isCollected) return AppColors.starInactive;
    return AppColors.starActive;
  }
}
