import '../../domain/entities/media.dart';

class MaoyanModel {
  final String id;
  final String title;
  final String originalTitle;
  final double score;
  final String poster;
  final String releaseDate;
  final String duration;
  final String year;
  final String director;
  final String actorsStr;
  final String genresStr;
  final String wish;
  final bool isNew;
  final String pubDesc;

  MaoyanModel({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.score,
    required this.poster,
    required this.releaseDate,
    required this.duration,
    required this.year,
    required this.director,
    required this.actorsStr,
    required this.genresStr,
    required this.wish,
    required this.isNew,
    required this.pubDesc,
  });

  factory MaoyanModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'].toString();
    final title = json['nm'] ?? '未知标题';
    final originalTitle = json['enm'] ?? '';
    final score = (json['sc'] as num?)?.toDouble() ?? 0.0;

    // Wish count
    final wish = (json['wish'] as num?)?.toString() ?? '0';

    // Poster parsing
    String poster = json['img'] ?? '';
    if (poster.isNotEmpty && !poster.startsWith('http')) {
      // Handle relative paths if necessary, though simpler check used in service
      // usually it's full url but with .w.h pattern
    }
    // Clean up w.h pattern
    if (poster.contains('/w.h/')) {
      poster = poster.replaceAll('/w.h/', '/');
    }

    final pubDesc = json['pubDesc'] ?? '';
    final releaseDate = json['rt'] ?? '';

    String year = '----';
    if (releaseDate.isNotEmpty && releaseDate.length >= 4) {
      year = releaseDate.substring(0, 4);
    } else if (pubDesc.isNotEmpty) {
      final yearMatch = RegExp(r'\d{4}').firstMatch(pubDesc);
      if (yearMatch != null) year = yearMatch.group(0)!;
    }

    final director = json['dir'] ?? '';
    final actorsStr = json['star'] ?? '';
    final genresStr = json['cat'] ?? '';

    // isNew logic
    final bool isNew = json['showStateButton'] != null && json['showStateButton']['content'] == '购票';

    return MaoyanModel(
      id: id,
      title: title,
      originalTitle: originalTitle,
      score: score,
      poster: poster,
      releaseDate: releaseDate,
      duration: "${json['dur'] ?? 0}分钟",
      year: year,
      director: director,
      actorsStr: actorsStr,
      genresStr: genresStr,
      wish: wish,
      isNew: isNew,
      pubDesc: pubDesc,
    );
  }

  Media toEntity() {
    String staff = '';
    if (director.isNotEmpty) staff += '导演: $director ';
    if (actorsStr.isNotEmpty) staff += '主演: $actorsStr';

    final actorList = actorsStr.split(',').map((s) => s.trim().toString()).where((s) => s.isNotEmpty).toList();

    return Media(
      id: '',
      sourceType: 'maoyan',
      sourceId: id,
      sourceUrl: 'https://m.maoyan.com/movie/$id',
      mediaType: 'movie',
      titleZh: title,
      titleOriginal: originalTitle,
      releaseDate: releaseDate,
      duration: duration,
      year: year,
      posterUrl: poster,
      summary: '暂无简介',
      staff: staff.isEmpty ? '暂无制作信息' : staff,
      rating: score,
      ratingMaoyan: score,
      directors: director.isNotEmpty ? [director] : [],
      actors: actorList,
      isNew: isNew,
    );
  }
}
