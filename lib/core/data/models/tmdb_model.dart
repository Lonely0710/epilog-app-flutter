import '../../domain/entities/media.dart';

class TmdbModel {
  final Map<String, dynamic> json;
  final String mediaType;

  TmdbModel(this.json, this.mediaType);

  factory TmdbModel.fromJson(Map<String, dynamic> json, String mediaType) {
    return TmdbModel(json, mediaType);
  }

  Media toEntity() {
    final isMovie = mediaType == 'movie';
    // item keys are directly from json map
    final item = json;

    final id = item['id'].toString();
    final titleZh = isMovie ? item['title'] : item['name'];
    final titleOriginal =
        isMovie ? item['original_title'] : item['original_name'];

    // Determine release date
    final releaseDate = isMovie
        ? (item['release_date'] ?? '未知日期')
        : (item['first_air_date'] ?? '未知日期');

    String year = '----';
    if (releaseDate != '未知日期' && releaseDate.length >= 4) {
      year = releaseDate.substring(0, 4);
    }

    // Poster
    final posterPath = item['poster_path'];
    final posterUrl =
        posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';

    final rating = (item['vote_average'] as num?)?.toDouble() ?? 0.0;

    // Duration
    String duration = '未知';
    if (isMovie && item.containsKey('runtime')) {
      final runtime = item['runtime'];
      if (runtime != null) duration = '$runtime分钟';
    } else if (!isMovie) {
      if (item.containsKey('number_of_episodes')) {
        final episodes = item['number_of_episodes'];
        if (episodes != null) {
          duration = '共$episodes集';
        }
      } else if (item.containsKey('episode_run_time')) {
        final runtimes = item['episode_run_time'] as List?;
        if (runtimes != null && runtimes.isNotEmpty) {
          duration = '${runtimes.first}分钟/集';
        }
      }
    }

    // Staff
    List<String> directors = [];
    List<String> actors = [];

    if (item.containsKey('credits')) {
      final credits = item['credits'];
      if (credits['crew'] != null) {
        final crew = credits['crew'] as List;
        directors = crew
            .where((member) => member['job'] == 'Director')
            .map((member) => member['name'] as String)
            .take(3)
            .toList();
      }
      if (credits['cast'] != null) {
        final cast = credits['cast'] as List;
        actors =
            cast.map((member) => member['name'] as String).take(5).toList();
      }
      if (!isMovie && item.containsKey('created_by')) {
        final creators = item['created_by'] as List;
        directors.addAll(creators.map((c) => c['name'] as String));
      }
    }

    final summary = item['overview'] ?? '暂无简介';

    return Media(
      sourceType: 'tmdb',
      sourceId: id,
      sourceUrl: 'https://www.themoviedb.org/$mediaType/$id',
      mediaType: mediaType,
      titleZh: titleZh ?? '未知标题',
      titleOriginal: titleOriginal ?? '',
      releaseDate: releaseDate,
      duration: duration,
      year: year,
      posterUrl: posterUrl,
      summary: summary,
      staff: '',
      directors: directors,
      actors: actors,
      rating: rating,
      ratingImdb: rating,
    );
  }
}
