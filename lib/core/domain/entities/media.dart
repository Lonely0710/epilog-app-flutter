class Media {
  // ID
  final String id;

  // media_source相关字段
  final String sourceType; // douban/imdb/bgm/maoyan
  final String sourceId;
  final String sourceUrl;

  // media相关字段
  final String mediaType; // movie/tv/anime
  final String titleZh;
  final String titleOriginal;
  final String releaseDate; // 详细首播年月日
  final String duration; // 时长（分钟/话数）
  final String year; // 年份(从releaseDate提取)
  final String posterUrl;
  final String summary; // 剧情简介
  final String staff; // 制作人员 (Anime usage)
  final List<String> directors;
  final List<String> actors;
  final List<Map<String, String>> networks; // TV broadcast platforms [{name, logoUrl}]

  // 评分相关
  final double rating; // 综合评分(用于兼容旧版本)
  final double ratingDouban; // 豆瓣评分
  final double ratingImdb; // IMDb评分
  final double ratingBangumi; // Bangumi评分
  final double ratingMaoyan; // 猫眼评分

  // 状态
  final bool isCollected;
  final String collectionId; // 收藏记录ID
  final String? watchingStatus; // 'wish', 'watching', 'watched', 'dropped', 'on_hold'

  final bool isNew; // 是否新上映

  const Media({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.sourceUrl,
    required this.mediaType,
    required this.titleZh,
    required this.titleOriginal,
    required this.releaseDate,
    required this.duration,
    required this.year,
    required this.posterUrl,
    required this.summary,
    required this.staff,
    this.directors = const [],
    this.actors = const [],
    this.networks = const [],
    required this.rating,
    this.ratingDouban = 0.0,
    this.ratingImdb = 0.0,
    this.ratingBangumi = 0.0,
    this.ratingMaoyan = 0.0,
    this.isCollected = false,
    this.collectionId = '',
    this.watchingStatus,
    this.isNew = false,
  });

  factory Media.empty() {
    return const Media(
      id: '',
      sourceType: '',
      sourceId: '',
      sourceUrl: '',
      mediaType: '',
      titleZh: '',
      titleOriginal: '',
      releaseDate: '',
      duration: '',
      year: '',
      posterUrl: '',
      summary: '',
      staff: '',
      networks: <Map<String, String>>[],
      rating: 0.0,
    );
  }

  factory Media.fromJson(Map<String, dynamic> json) {
    // Handle staff field - can be JSON object or legacy string
    String staffStr = '';
    List<String> directors = [];
    List<String> actors = [];

    final staffData = json['staff'];
    if (staffData is Map<String, dynamic>) {
      staffStr = staffData['info'] ?? '';
      directors = (staffData['directors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      actors = (staffData['actors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    } else if (staffData is String) {
      staffStr = staffData;
    }

    // Override with top-level directors/actors if present
    if (json['directors'] != null) {
      directors = (json['directors'] as List<dynamic>).map((e) => e.toString()).toList();
    }
    if (json['actors'] != null) {
      actors = (json['actors'] as List<dynamic>).map((e) => e.toString()).toList();
    }

    return Media(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      sourceType: json['sourceType'] ?? '',
      sourceId: json['sourceId'] ?? '',
      sourceUrl: json['sourceUrl'] ?? '',
      mediaType: json['mediaType'] ?? '',
      titleZh: json['titleZh'] ?? '',
      titleOriginal: json['titleOriginal'] ?? '',
      releaseDate: json['releaseDate'] ?? '',
      duration: json['duration'] ?? '',
      year: json['year'] ?? '',
      posterUrl: json['posterUrl'] ?? '',
      summary: json['summary'] ?? '',
      staff: staffStr,
      directors: directors,
      actors: actors,
      networks: _parseNetworks(json['networks']),
      rating: _parseDouble(json['rating']),
      ratingDouban: _parseDouble(json['ratingDouban']),
      ratingImdb: _parseDouble(json['ratingImdb']),
      ratingBangumi: _parseDouble(json['ratingBangumi']),
      ratingMaoyan: _parseDouble(json['ratingMaoyan']),

      isNew: json['isNew'] ?? false,
      // Collection state fields
      collectionId: json['collectionId']?.toString() ?? '',
      watchingStatus: json['watchingStatus'] as String?,
      isCollected: json['isCollected'] ?? false,
    );
  }

  Media copyWith({
    String? id,
    String? sourceType,
    String? sourceId,
    String? sourceUrl,
    String? mediaType,
    String? titleZh,
    String? titleOriginal,
    String? releaseDate,
    String? duration,
    String? year,
    String? posterUrl,
    String? summary,
    String? staff,
    List<String>? directors,
    List<String>? actors,
    List<Map<String, String>>? networks,
    double? rating,
    double? ratingDouban,
    double? ratingImdb,
    double? ratingBangumi,
    double? ratingMaoyan,
    bool? isCollected,
    String? collectionId,
    String? watchingStatus,
    bool? isNew,
  }) {
    return Media(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      mediaType: mediaType ?? this.mediaType,
      titleZh: titleZh ?? this.titleZh,
      titleOriginal: titleOriginal ?? this.titleOriginal,
      releaseDate: releaseDate ?? this.releaseDate,
      duration: duration ?? this.duration,
      year: year ?? this.year,
      posterUrl: posterUrl ?? this.posterUrl,
      summary: summary ?? this.summary,
      staff: staff ?? this.staff,
      directors: directors ?? this.directors,
      actors: actors ?? this.actors,
      networks: networks ?? this.networks,
      rating: rating ?? this.rating,
      ratingDouban: ratingDouban ?? this.ratingDouban,
      ratingImdb: ratingImdb ?? this.ratingImdb,
      ratingBangumi: ratingBangumi ?? this.ratingBangumi,
      ratingMaoyan: ratingMaoyan ?? this.ratingMaoyan,
      isCollected: isCollected ?? this.isCollected,
      collectionId: collectionId ?? this.collectionId,
      watchingStatus: watchingStatus ?? this.watchingStatus,
      isNew: isNew ?? this.isNew,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      if (value.isEmpty) return 0.0;
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static List<Map<String, String>> _parseNetworks(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];
    return value
        .map<Map<String, String>>((net) {
          if (net is Map) {
            return {
              'name': net['name']?.toString() ?? '',
              'logoUrl': net['logoUrl']?.toString() ?? '',
            };
          }
          return {'name': '', 'logoUrl': ''};
        })
        .where((n) => n['name']!.isNotEmpty)
        .toList();
  }
}
