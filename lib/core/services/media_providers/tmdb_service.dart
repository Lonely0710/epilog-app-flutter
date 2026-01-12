import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../services/secure_storage_service.dart';
import '../../domain/entities/media.dart';
import '../../data/models/tmdb_model.dart';

class TmdbService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  Future<List<Media>> searchMovie(String query) async {
    final apiKey = await SecureStorageService.tmdbApiKey;

    if (apiKey == null ||
        apiKey == 'YOUR_TMDB_API_KEY_HERE' ||
        apiKey.isEmpty) {
      log('TMDb API Key not set');
      return [];
    }

    final url =
        '$_baseUrl/search/multi?api_key=$apiKey&language=zh-CN&query=$query&include_adult=false';
    log('Searching TMDb: $url');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        log('TMDb API Error: ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      final results = data['results'] as List;

      // Filter
      final basicResults = results
          .where((item) =>
              item['media_type'] == 'movie' || item['media_type'] == 'tv')
          .toList();

      final detailedResults = await Future.wait(
        basicResults.take(8).map((item) => _fetchDetails(item, apiKey)),
      );

      return detailedResults.whereType<Media>().toList();
    } catch (e) {
      log('Error searching TMDb: $e');
      return [];
    }
  }

  Future<Media?> _fetchDetails(Map<String, dynamic> item, String apiKey) async {
    try {
      final mediaType = item['media_type'];
      final id = item['id'].toString();
      final detailUrl =
          '$_baseUrl/$mediaType/$id?api_key=$apiKey&language=zh-CN&append_to_response=credits';

      final response = await http.get(Uri.parse(detailUrl));
      if (response.statusCode == 200) {
        final detailData = json.decode(response.body);
        final model = TmdbModel.fromJson(detailData, mediaType);
        return model.toEntity();
      }
    } catch (e) {
      log('Error fetching details for ${item['id']}: $e');
    }
    // Fallback
    try {
      final model = TmdbModel.fromJson(item, item['media_type']);
      return model.toEntity();
    } catch (e) {
      return null;
    }
  }

  Future<List<Media>> getTopRatedMovies({int page = 1}) async {
    return _getTopRated('movie', page);
  }

  Future<List<Media>> getTopRatedTVShows({int page = 1}) async {
    return _getTopRated('tv', page);
  }

  Future<List<Media>> _getTopRated(String type, int page) async {
    final apiKey = await SecureStorageService.tmdbApiKey;
    if (apiKey == null || apiKey.isEmpty) return [];

    final url =
        '$_baseUrl/$type/top_rated?api_key=$apiKey&language=zh-CN&page=$page';
    log('Fetching Top Rated $type (Page $page): $url');

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((item) {
          // For Top Rated list, we don't fetch details to save quota/time, matching Android logic
          // Pass type explicitly as it might not be in the result item for some endpoints,
          // though usually 'media_type' is missing in specific list endpoints, so we pass it.
          return TmdbModel.fromJson(item, type).toEntity();
        }).toList();
      }
    } catch (e) {
      log('Error fetching top rated $type: $e');
    }
    return [];
  }

  Future<List<Media>> discoverMovies({
    int page = 1,
    int? year,
    String? genre,
  }) async {
    return _discoverMedia('movie', page, year, genre);
  }

  Future<List<Media>> discoverTVShows({
    int page = 1,
    int? year,
    String? genre,
  }) async {
    return _discoverMedia('tv', page, year, genre);
  }

  Future<List<Media>> _discoverMedia(
    String type,
    int page,
    int? year,
    String? genre,
  ) async {
    final apiKey = await SecureStorageService.tmdbApiKey;
    if (apiKey == null || apiKey.isEmpty) return [];

    // Base URL
    String url =
        '$_baseUrl/discover/$type?api_key=$apiKey&language=zh-CN&sort_by=vote_average.desc&vote_count.gte=300&page=$page';

    // Add filters
    if (year != null) {
      if (type == 'movie') {
        url += '&primary_release_year=$year';
      } else {
        url += '&first_air_date_year=$year';
      }
    }

    if (genre != null) {
      final genreId = _getGenreId(type, genre);
      if (genreId != null) {
        url += '&with_genres=$genreId';
      }
    }

    log('Discovering $type (Page $page, Year: $year, Genre: $genre): $url');

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((item) {
          return TmdbModel.fromJson(item, type).toEntity();
        }).toList();
      }
    } catch (e) {
      log('Error discovering $type: $e');
    }
    return [];
  }

  int? _getGenreId(String type, String genreName) {
    // Common genres
    final common = {
      '剧情': 18,
      '喜剧': 35,
      '动作': 28,
      '爱情': 10749,
      '科幻': 878,
      '动画': 16,
      '悬疑': 9648,
      '惊悚': 53,
      '犯罪': 80,
      '纪录': 99,
      '冒险': 12,
      '奇幻': 14,
      '家庭': 10751,
      '恐怖': 27,
      '历史': 36,
      '战争': 10752,
      '音乐': 10402,
      '西部': 37,
      // '电视电影': 10770, // Removed by user request
    };

    // TV Specific overrides or additions if needed
    // TMDb TV genres have some differences:
    // Action & Adventure: 10759
    // Sci-Fi & Fantasy: 10765
    // War & Politics: 10768

    if (type == 'tv') {
      if (genreName == '动作' || genreName == '冒险') return 10759;
      if (genreName == '科幻' || genreName == '奇幻') return 10765;
      if (genreName == '战争') return 10768; // War & Politics
    }

    return common[genreName];
  }
}
