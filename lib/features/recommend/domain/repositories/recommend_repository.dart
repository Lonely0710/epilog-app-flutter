import '../../../../core/domain/entities/media.dart';

abstract class RecommendRepository {
  Future<List<Media>> getRecentMovies();
  Future<List<Media>> getTopRatedMovies(int page);
  Future<List<Media>> getTopRatedTVShows(int page);
  Future<List<Media>> getTopRatedAll(int page);

  Future<List<Media>> discoverMovies(int page, {int? year, String? genre});
  Future<List<Media>> discoverTVShows(int page, {int? year, String? genre});
}
