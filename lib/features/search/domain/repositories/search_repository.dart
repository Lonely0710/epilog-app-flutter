import 'dart:developer';
import '../../../../core/domain/entities/media.dart';
import '../../../../core/services/media_providers/bangumi_service.dart';
import '../../../../core/services/media_providers/douban_service.dart';
import '../../../../core/services/media_providers/maoyan_service.dart';
import '../../../../core/services/media_providers/tmdb_service.dart';

abstract class SearchRepository {
  Future<List<Media>> searchAnime(String query);
  Future<List<Media>> searchMovie(String query);
}

class SearchRepositoryImpl implements SearchRepository {
  final BangumiService _bangumiService;
  final DoubanService _doubanService;
  final TmdbService _tmdbService;
  final MaoyanService _maoyanService;

  SearchRepositoryImpl({
    BangumiService? bangumiService,
    DoubanService? doubanService,
    TmdbService? tmdbService,
    MaoyanService? maoyanService,
  })  : _bangumiService = bangumiService ?? BangumiService(),
        _doubanService = doubanService ?? DoubanService(),
        _tmdbService = tmdbService ?? TmdbService(),
        _maoyanService = maoyanService ?? MaoyanService();

  @override
  Future<List<Media>> searchAnime(String query) async {
    final rawResults = await _bangumiService.searchAnime(query);
    return _filterRelevantResults(rawResults);
  }

  @override
  Future<List<Media>> searchMovie(String query) async {
    // Parallel execution for TMDb, Maoyan, and Douban
    // using catching to ensure one failure doesn't block others
    final results = await Future.wait([
      _tmdbService.searchMovie(query).catchError((e) {
        log('TMDb search failed: $e');
        return <Media>[];
      }),
      _maoyanService.searchMovie(query).catchError((e) {
        log('Maoyan search failed: $e');
        return <Media>[];
      }),
      _doubanService.searchMovie(query).catchError((e) {
        log('Douban search failed: $e');
        return <Media>[];
      }),
    ]);

    final tmdbResults = results[0];
    final maoyanResults = results[1];
    final doubanResults = results[2];

    // Priority: TMDb > Maoyan > Douban
    // Deduplication logic based on title and year
    final merged = _deduplicateResults([...tmdbResults, ...maoyanResults, ...doubanResults]);
    return _filterRelevantResults(merged);
  }

  List<Media> _filterRelevantResults(List<Media> results) {
    // Filter out items that are likely low quality or empty placeholders
    return results.where((item) {
      if (item.posterUrl.isEmpty) return false;
      if (item.titleZh.isEmpty || item.titleZh == '未知标题') return false;
      // You can add more strict filters here if needed
      return true;
    }).toList();
  }

  List<Media> _deduplicateResults(List<Media> allResults) {
    final uniqueResults = <String, Media>{};
    final seenKeys = <String>{};

    for (var result in allResults) {
      // Normalize key: Title + Year (e.g. "inception_2010")
      // Remove spaces, punctuation, lowercase
      final cleanTitle =
          result.titleZh.replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[^\w\u4e00-\u9fa5]'), '').toLowerCase();
      final key = '${cleanTitle}_${result.year}';

      if (!seenKeys.contains(key)) {
        uniqueResults[key] = result;
        seenKeys.add(key);
      } else {
        // Merge ratings if we found a duplicate
        final existing = uniqueResults[key]!;
        Media merged = existing;

        if (result.sourceType == 'douban' && result.ratingDouban > 0) {
          merged = merged.copyWith(ratingDouban: result.ratingDouban);
        } else if (result.sourceType == 'maoyan' && result.ratingMaoyan > 0) {
          merged = merged.copyWith(ratingMaoyan: result.ratingMaoyan);
        } else if (result.sourceType == 'tmdb' && result.ratingImdb > 0) {
          // If existing didn't come from TMDb (unlikely due to priority), add
          merged = merged.copyWith(ratingImdb: result.ratingImdb);
        }

        uniqueResults[key] = merged;
      }
    }

    return uniqueResults.values.toList();
  }
}
