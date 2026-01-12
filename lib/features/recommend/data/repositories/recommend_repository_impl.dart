import '../../../../core/domain/entities/media.dart';
import '../../../../core/services/media_providers/maoyan_service.dart';
import '../../../../core/services/media_providers/tmdb_service.dart';
import '../../domain/repositories/recommend_repository.dart';

class RecommendRepositoryImpl implements RecommendRepository {
  final MaoyanService _maoyanService;
  final TmdbService _tmdbService;

  RecommendRepositoryImpl(this._maoyanService, this._tmdbService);

  @override
  Future<List<Media>> getRecentMovies() {
    return _maoyanService.getMoviesOnShowing();
  }

  @override
  Future<List<Media>> getTopRatedMovies(int page) async {
    // Fetch 2 pages to get 40 items (user wants ~33)
    // Page 1 -> API Page 1, 2
    // Page 2 -> API Page 3, 4
    final apiPageStart = (page - 1) * 2 + 1;
    final results = await Future.wait([
      _tmdbService.getTopRatedMovies(page: apiPageStart),
      _tmdbService.getTopRatedMovies(page: apiPageStart + 1),
    ]);
    return [...results[0], ...results[1]];
  }

  @override
  Future<List<Media>> getTopRatedTVShows(int page) async {
    final apiPageStart = (page - 1) * 2 + 1;
    final results = await Future.wait([
      _tmdbService.getTopRatedTVShows(page: apiPageStart),
      _tmdbService.getTopRatedTVShows(page: apiPageStart + 1),
    ]);
    return [...results[0], ...results[1]];
  }

  @override
  Future<List<Media>> getTopRatedAll(int page) async {
    final movies = await getTopRatedMovies(page);
    final tvShows = await getTopRatedTVShows(page);

    final combined = [...movies, ...tvShows];
    // Sort by rating desc
    combined.sort((a, b) => (b.ratingImdb).compareTo(a.ratingImdb));
    return combined;
  }

  @override
  Future<List<Media>> discoverMovies(int page,
      {int? year, String? genre}) async {
    final apiPageStart = (page - 1) * 2 + 1;
    final results = await Future.wait([
      _tmdbService.discoverMovies(page: apiPageStart, year: year, genre: genre),
      _tmdbService.discoverMovies(
          page: apiPageStart + 1, year: year, genre: genre),
    ]);
    return [...results[0], ...results[1]];
  }

  @override
  Future<List<Media>> discoverTVShows(int page,
      {int? year, String? genre}) async {
    final apiPageStart = (page - 1) * 2 + 1;
    final results = await Future.wait([
      _tmdbService.discoverTVShows(
          page: apiPageStart, year: year, genre: genre),
      _tmdbService.discoverTVShows(
          page: apiPageStart + 1, year: year, genre: genre),
    ]);
    return [...results[0], ...results[1]];
  }
}
