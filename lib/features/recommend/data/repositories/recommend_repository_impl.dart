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
    return _tmdbService.getTopRatedMovies(page: page);
  }

  @override
  Future<List<Media>> getTopRatedTVShows(int page) async {
    return _tmdbService.getTopRatedTVShows(page: page);
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
    return _tmdbService.discoverMovies(page: page, year: year, genre: genre);
  }

  @override
  Future<List<Media>> discoverTVShows(int page,
      {int? year, String? genre}) async {
    return _tmdbService.discoverTVShows(page: page, year: year, genre: genre);
  }
}
