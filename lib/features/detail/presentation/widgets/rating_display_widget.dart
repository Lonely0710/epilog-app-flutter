import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/domain/entities/media.dart';
import '../../../../core/presentation/pages/web_browser_page.dart';
import '../../../../features/search/presentation/widgets/circular_rating.dart';

class RatingDisplayWidget extends StatelessWidget {
  final Media media;

  const RatingDisplayWidget({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    if (media.mediaType == 'anime') {
      return _buildAnimeRating(context);
    }
    return _buildStandardRating(context);
  }

  String _getReleaseDateLabel() {
    switch (media.mediaType) {
      case 'anime':
        return '放送日';
      case 'tv':
        return '首播时间';
      case 'movie':
        return '上映时间';
      default:
        return '上映时间';
    }
  }

  // Open the browser page
  void _openBrowser(BuildContext context, String url, SiteType siteType) {
    if (url.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WebBrowserPage(
          args: WebBrowserPageArgs.fromSiteType(
            siteType: siteType,
            url: url,
          ),
        ),
      ),
    );
  }

  Future<void> _handleRatingTap(BuildContext context, SiteType siteType) async {
    String? url;

    // 1. Direct match: If existing media matches the siteType
    if (_mapSourceToSiteType(media.sourceType) == siteType) {
      if (media.sourceUrl.isNotEmpty) {
        url = media.sourceUrl;
      } else {
        url = _constructIdUrl(siteType, media.sourceId);
      }
    }
    // 2. Supabase match: Query media_source table
    else if (media.sourceType == 'supabase') {
      try {
        final client = Supabase.instance.client;
        final dbSourceTypes = _getDbSourceTypes(siteType);

        // Query media_source using the internal media ID
        final response = await client
            .from('media_source')
            .select('source_id')
            .eq('media_id', media.sourceId)
            .inFilter('source_type', dbSourceTypes)
            .maybeSingle();

        if (response != null && response['source_id'] != null) {
          final sourceId = response['source_id'] as String;
          if (sourceId.isNotEmpty) {
            url = _constructIdUrl(siteType, sourceId);
          }
        }
      } catch (e) {
        debugPrint('Error fetching source_url: $e');
      }
    }

    // 3. Fallback: Search URL
    url ??= _getSearchUrl(siteType);

    if (context.mounted && url != null) {
      _openBrowser(context, url, siteType);
    }
  }

  Widget _buildAnimeRating(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    // Premium Card Design: White background, subtle shadow, clean typography
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: isDark ? 0.1 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Left Accent Bar (Floating & Rounded)
            Positioned(
              left: 6,
              top: 12,
              bottom: 12,
              width: 4,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primary,
                      AppTheme.primary.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Release Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getReleaseDateLabel(),
                        style: TextStyle(
                          fontFamily: AppTheme.primaryFont,
                          fontSize: 12,
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        media.releaseDate.isNotEmpty
                            ? media.releaseDate
                            : 'Unknown',
                        style: TextStyle(
                          fontFamily: AppTheme.primaryFont,
                          fontSize: 18, // Slightly larger
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),

                  // Right: Rating - uses CircularRating style with gradient colors
                  Row(
                    children: [
                      CircularRating(
                        rating: media.ratingBangumi > 0
                            ? media.ratingBangumi
                            : media.rating,
                        size: 56,
                        strokeWidth: 4,
                        // No color passed - uses AppColors.getRatingColor() gradient
                      ),
                      const SizedBox(width: 16),
                      // Bangumi Icon
                      GestureDetector(
                        onTap: () =>
                            _handleRatingTap(context, SiteType.bangumi),
                        behavior: HitTestBehavior.opaque,
                        child: Opacity(
                          opacity: 0.9,
                          child: Image.asset(
                            'assets/icons/ic_bangumi_fill.png',
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardRating(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    final ratings = <Widget>[];

    if (media.ratingDouban > 0) {
      ratings.add(_buildRatingItem(
        context,
        'Douban',
        media.ratingDouban,
        'assets/icons/ic_douban_green.png',
        null,
        siteType: SiteType.douban,
      ));
    }

    if (media.ratingImdb > 0) {
      ratings.add(_buildRatingItem(
        context,
        'TMDB',
        media.ratingImdb,
        'assets/icons/ic_tmdb.png',
        null,
        useWhiteBackground: false,
        siteType: SiteType.tmdb,
      ));
    }

    if (media.ratingMaoyan > 0) {
      ratings.add(_buildRatingItem(
        context,
        'Maoyan',
        media.ratingMaoyan,
        'assets/icons/ic_maoyan.png',
        null,
        siteType: SiteType.maoyan,
      ));
    }

    // Fallback
    if (ratings.isEmpty && media.rating > 0) {
      ratings.add(_buildRatingItem(
        context,
        'Rating',
        media.rating,
        null,
        AppTheme.primary,
      ));
    }

    if (ratings.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: isDark ? 0.1 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Left Accent Bar (Floating & Rounded)
            Positioned(
              left: 6,
              top: 12,
              bottom: 12,
              width: 4,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primary,
                      AppTheme.primary.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Release Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getReleaseDateLabel(),
                        style: TextStyle(
                          fontFamily: AppTheme.primaryFont,
                          fontSize: 12,
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        media.releaseDate.isNotEmpty
                            ? media.releaseDate
                            : 'Unknown',
                        style: TextStyle(
                          fontFamily: AppTheme.primaryFont,
                          fontSize: 18,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),

                  // Right: All Ratings
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _divideWidgets(ratings, isVertical: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _divideWidgets(List<Widget> widgets, {bool isVertical = false}) {
    if (widgets.isEmpty) return [];
    if (widgets.length == 1) return widgets;

    final List<Widget> divided = [];
    for (int i = 0; i < widgets.length; i++) {
      divided.add(widgets[i]);
      if (i < widgets.length - 1) {
        divided.add(
          Container(
            height: isVertical ? 16 : 30,
            width: isVertical ? 30 : 1,
            color: Colors.transparent, // Just spacing, no line
          ),
        );
      }
    }
    return divided;
  }

  Widget _buildRatingItem(
    BuildContext context,
    String label,
    double score,
    String? iconPath,
    Color? color, {
    bool useWhiteBackground = true,
    SiteType? siteType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    // Yellow rating score in dark mode as requested
    final scoreColor = isDark ? Colors.amber : textColor;

    // Check if this is Maoyan or TMDB icon
    final isMaoyanIcon = iconPath?.contains('maoyan') ?? false;
    final isTmdbIcon = iconPath?.contains('tmdb') ?? false;

    Widget iconWidget;
    if (iconPath != null) {
      iconWidget = Container(
        width: 36, // Consistent container size
        height: 36,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isMaoyanIcon && isDark
              ? Colors.white.withValues(alpha: 0.9)
              : null,
          border: isTmdbIcon && isDark
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                )
              : null,
          borderRadius: BorderRadius.circular(6),
          shape:
              isMaoyanIcon && isDark ? BoxShape.rectangle : BoxShape.rectangle,
        ),
        child: Image.asset(
          iconPath,
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        ),
      );

      if (siteType != null) {
        iconWidget = Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleRatingTap(context, siteType),
            borderRadius: BorderRadius.circular(6),
            child: iconWidget,
          ),
        );
      }
    } else {
      iconWidget = Icon(Icons.star, color: color ?? AppTheme.primary, size: 28);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Text grouping for baseline alignment
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  score.toStringAsFixed(1),
                  style: TextStyle(
                    fontFamily: AppTheme.primaryFont,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: scoreColor, // Yellow in dark mode
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  '/10',
                  style: TextStyle(
                    fontFamily: AppTheme.primaryFont,
                    fontSize: 11,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // Source Icon - with consistent container size
            iconWidget,
          ],
        ),
      ],
    );
  }

  SiteType _mapSourceToSiteType(String sourceType) {
    switch (sourceType.toLowerCase()) {
      case 'douban':
        return SiteType.douban;
      case 'bgm':
      case 'bangumi':
        return SiteType.bangumi;
      case 'tmdb':
      case 'imdb':
        return SiteType.tmdb;
      case 'maoyan':
        return SiteType.maoyan;
      default:
        return SiteType.other;
    }
  }

  List<String> _getDbSourceTypes(SiteType siteType) {
    switch (siteType) {
      case SiteType.douban:
        return ['douban'];
      case SiteType.bangumi:
        return ['bangumi', 'bgm'];
      case SiteType.tmdb:
        return ['tmdb', 'imdb'];
      case SiteType.maoyan:
        return ['maoyan'];
      default:
        return [];
    }
  }

  String? _constructIdUrl(SiteType siteType, String id) {
    switch (siteType) {
      case SiteType.douban:
        return 'https://movie.douban.com/subject/$id';
      case SiteType.bangumi:
        return 'https://chii.in/subject/$id';
      case SiteType.maoyan:
        return 'https://m.maoyan.com/movie/$id';
      case SiteType.tmdb:
        return 'https://www.themoviedb.org/${media.mediaType}/$id';
      default:
        return null;
    }
  }

  String? _getSearchUrl(SiteType siteType) {
    // 2. If not matched, use Search URL fallback
    // This allows clicking "Maoyan" icon on a "Douban" item to search Maoyan for it.
    final query = Uri.encodeComponent(media.titleZh);
    final queryOriginal = Uri.encodeComponent(
        media.titleOriginal.isNotEmpty ? media.titleOriginal : media.titleZh);

    switch (siteType) {
      case SiteType.douban:
        return 'https://m.douban.com/search/?query=$query';
      case SiteType.bangumi:
        return 'https://chii.in/subject_search/$queryOriginal?cat=2'; // cat=2 for anime/generic
      case SiteType.maoyan:
        return 'https://m.maoyan.com/search?kw=$query';
      case SiteType.tmdb:
        return 'https://www.themoviedb.org/search?query=$queryOriginal';
      default:
        return null;
    }
  }
}
