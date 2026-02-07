import 'package:html/dom.dart';
import '../../domain/entities/media.dart';

class BangumiModel {
  final String id;
  final String title;
  final String originalTitle;
  final String poster;
  final String infoText;
  final double rating;
  final String summary;
  final String durationDetail;

  BangumiModel({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.poster,
    required this.infoText,
    required this.rating,
    required this.summary,
    required this.durationDetail,
  });

  factory BangumiModel.fromElement(Element item, String sourceId, Map<String, String>? detailData) {
    final titleElement = item.querySelector('h3 > a.l');
    final titleZh = titleElement?.text.trim() ?? '未知标题';

    final originalTitleElement = item.querySelector('h3 > small.grey');
    final titleOriginal = originalTitleElement?.text.trim() ?? '';

    var posterUrl = '';
    final imgElement = item.querySelector('.subjectCover img');
    if (imgElement != null) {
      var src = imgElement.attributes['src'] ?? '';
      if (src.startsWith('//')) {
        src = 'https:$src';
      }
      posterUrl = src.replaceAll(RegExp(r'/s/|/m/'), '/l/');
    }

    final infoElement = item.querySelector('.info.tip');
    final infoText = infoElement?.text.trim() ?? '';

    double ratingVal = 0.0;
    final ratingElement = item.querySelector('.rateInfo small.fade');
    if (ratingElement != null) {
      ratingVal = double.tryParse(ratingElement.text) ?? 0.0;
    }

    String summaryStr = '暂无简介';
    String durationStr = '';

    if (detailData != null) {
      if (detailData['summary'] != null && detailData['summary']!.isNotEmpty) {
        summaryStr = detailData['summary']!;
      }
      if (detailData['duration'] != null && detailData['duration']!.isNotEmpty) {
        durationStr = detailData['duration']!;
      }
    }

    return BangumiModel(
      id: sourceId,
      title: titleZh,
      originalTitle: titleOriginal,
      poster: posterUrl,
      infoText: infoText,
      rating: ratingVal,
      summary: summaryStr,
      durationDetail: durationStr,
    );
  }

  Media toEntity() {
    final infoParts = infoText.split(' / ');
    String releaseDate = '';
    String duration = '';
    String staff = '';
    String year = '';

    for (var part in infoParts) {
      part = part.trim();
      if (RegExp(r'\d{4}年').hasMatch(part)) {
        if (RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})日').hasMatch(part)) {
          final match = RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})日').firstMatch(part)!;
          final y = match.group(1)!;
          final m = match.group(2)!.padLeft(2, '0');
          final d = match.group(3)!.padLeft(2, '0');
          releaseDate = '$y-$m-$d';
          year = y;
        } else if (RegExp(r'(\d{4})年(\d{1,2})月').hasMatch(part)) {
          final match = RegExp(r'(\d{4})年(\d{1,2})月').firstMatch(part)!;
          final y = match.group(1)!;
          final m = match.group(2)!.padLeft(2, '0');
          releaseDate = '$y-$m-01';
          year = y;
        } else if (RegExp(r'(\d{4})年').hasMatch(part)) {
          final match = RegExp(r'(\d{4})年').firstMatch(part)!;
          final y = match.group(1)!;
          releaseDate = '$y-01-01';
          year = y;
        } else {
          // Fallback if match but structure unexpected (should verify)
          releaseDate = part;
          final yearMatch = RegExp(r'(\d{4})').firstMatch(part);
          if (yearMatch != null) {
            year = yearMatch.group(1) ?? '';
          }
        }
      } else if (RegExp(r'\d+话').hasMatch(part)) {
        duration = part;
      } else {
        if (staff.isNotEmpty) staff += ' / ';
        staff += part;
      }
    }

    List<String> directors = [];
    if (infoText.isNotEmpty) {
      final firstPart = infoText.split(' / ').first.trim();
      if (!RegExp(r'\d{4}年').hasMatch(firstPart) && !RegExp(r'\d+话').hasMatch(firstPart)) {
        directors = [firstPart];
      }
    }

    // Override duration if detail fetch provided more info (e.g. episodes count)
    if (durationDetail.isNotEmpty) {
      duration = durationDetail; // e.g. "12集"
    }
    if (duration.isEmpty) duration = '未知';
    if (releaseDate.isEmpty) releaseDate = '未知日期';
    if (year.isEmpty) year = '----';

    return Media(
      id: '',
      sourceType: 'bgm',
      sourceId: id,
      sourceUrl: 'https://bgm.tv/subject/$id',
      mediaType: 'anime',
      titleZh: title,
      titleOriginal: originalTitle,
      releaseDate: releaseDate,
      duration: duration,
      year: year,
      posterUrl: poster,
      summary: summary,
      staff: staff.isEmpty ? '暂无制作信息' : staff,
      directors: directors,
      rating: rating,
      ratingBangumi: rating,
    );
  }
}
