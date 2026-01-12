import 'package:html/dom.dart';
import '../../domain/entities/media.dart';

class DoubanModel {
  final String id;
  final String title;
  final String originalTitle;
  final double rating;
  final String poster;
  final String summary;
  final String releaseDate;
  final String duration;
  final String year;
  final String directors;
  final String actors;
  final String staff;

  DoubanModel({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.rating,
    required this.poster,
    required this.summary,
    required this.releaseDate,
    required this.duration,
    required this.year,
    required this.directors,
    required this.actors,
    required this.staff,
  });

  // Since Douban parsing involves HTML and async detail fetching,
  // we might use this model just to hold the final combined data,
  // or use it to parse the initial list item.
  // Given the complexity of Douban service (fetching detail separately),
  // it might be cleaner to let the Service orchestrate the fetch and use this Model
  // as a data holder (POJO) that converts to Entity.

  // Or we can have `DoubanListItemModel` from Element.
  factory DoubanModel.fromElement(
      Element element, String sourceId, Map<String, String>? detailData) {
    // Basic info from element
    final titleLink = element.querySelector('h3 a');
    String titleZh = titleLink?.text.trim() ?? '未知标题';

    final subjectCast = element.querySelector('.subject-cast');
    String staffStr = '';
    String yearStr = '----';

    if (subjectCast != null) {
      final text = subjectCast.text.trim();
      final yearMatch = RegExp(r'\d{4}').firstMatch(text);
      if (yearMatch != null) {
        yearStr = yearMatch.group(0)!;
      }
      staffStr = text.replaceAll(RegExp(r'原名:.*?(?:/|$)'), '').trim();
      if (staffStr.startsWith('/')) staffStr = staffStr.substring(1).trim();
    }

    final ratingEl = element.querySelector('.rating_nums');
    double ratingVal = 0.0;
    if (ratingEl != null && ratingEl.text.isNotEmpty) {
      ratingVal = double.tryParse(ratingEl.text) ?? 0.0;
    }

    // Detail data overrides
    String posterUrl = detailData?['posterUrl'] ?? '';
    String summaryStr = '暂无简介';
    if (detailData?['summary'] != null && detailData!['summary']!.isNotEmpty) {
      summaryStr = detailData['summary']!;
    }
    String durationStr = detailData?['duration'] ?? '未知';
    String releaseDateStr = detailData?['releaseDate'] ?? '未知日期';
    String titleOrig = detailData?['titleOriginal'] ?? '';

    return DoubanModel(
      id: sourceId,
      title: titleZh,
      originalTitle: titleOrig,
      rating: ratingVal,
      poster: posterUrl,
      summary: summaryStr,
      releaseDate: releaseDateStr,
      duration: durationStr,
      year: yearStr,
      directors:
          '', // Logic to extract directors from staffStr left to toEntity or here?
      // Kept simple for now, staffStr usage is dominant in current App.
      actors: '',
      staff: staffStr,
    );
  }

  Media toEntity() {
    return Media(
      sourceType: 'douban',
      sourceId: id,
      sourceUrl: 'https://movie.douban.com/subject/$id',
      mediaType: 'movie',
      titleZh: title,
      titleOriginal: originalTitle,
      releaseDate: releaseDate,
      duration: duration,
      year: year,
      posterUrl: poster,
      summary: summary,
      staff: staff.isEmpty ? '暂无制作信息' : staff,
      rating: rating,
      ratingDouban: rating,
      ratingMaoyan: 0.0,
      directors: _parseDirectors(staff),
      actors: _parseActors(staff),
    );
  }

  List<String> _parseDirectors(String staff) {
    if (staff.isEmpty) return [];
    final parts = staff.split('/');
    if (parts.isNotEmpty) {
      return parts.first.trim().split(' ').where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  List<String> _parseActors(String staff) {
    if (staff.isEmpty) return [];
    final parts = staff.split('/');
    if (parts.length > 1) {
      return parts[1].trim().split(' ').where((s) => s.isNotEmpty).toList();
    }
    return [];
  }
}
