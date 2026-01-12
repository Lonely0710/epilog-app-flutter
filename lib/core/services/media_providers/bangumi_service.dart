import 'dart:convert';
import 'dart:developer';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/media.dart';
import '../../data/models/bangumi_model.dart';

class BangumiService {
  static const String _baseUrl = 'https://bgm.tv';

  Future<List<Media>> searchAnime(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url = '$_baseUrl/subject_search/$encodedQuery?cat=2';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Cookie': 'chii_searchDateLine=0',
        },
      );

      if (response.statusCode != 200) {
        log('Bangumi API Error: ${response.statusCode}');
        return [];
      }

      final document = parser.parse(utf8.decode(response.bodyBytes));
      final items = document.querySelectorAll('#browserItemList > li');
      List<Future<Media?>> futures = [];

      for (var item in items) {
        futures.add(_processItem(item));
      }

      final results = await Future.wait(futures);
      return results.whereType<Media>().toList();
    } catch (e) {
      log('Bangumi search error: $e');
      return [];
    }
  }

  Future<Media?> _processItem(Element item) async {
    try {
      final titleElement = item.querySelector('h3 > a.l');
      if (titleElement == null) return null;

      final href = titleElement.attributes['href'] ?? '';
      final sourceId = href.split('/').last;

      Map<String, String>? detailData;
      try {
        detailData = await _fetchSubjectDetail(sourceId);
      } catch (e) {
        log('Error fetching Bangumi detail for $sourceId: $e');
      }

      final model = BangumiModel.fromElement(item, sourceId, detailData);
      return model.toEntity();
    } catch (e) {
      log('Error parsing Bangumi item: $e');
      return null;
    }
  }

  Future<Map<String, String>> _fetchSubjectDetail(String sourceId) async {
    final url = '$_baseUrl/subject/$sourceId';
    final Map<String, String> result = {};

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Cookie': 'chii_searchDateLine=0',
      },
    );

    if (response.statusCode == 200) {
      final document = parser.parse(utf8.decode(response.bodyBytes));

      final summaryElement = document.querySelector('#subject_summary');
      if (summaryElement != null) {
        var text = summaryElement.text;
        text = text.replaceAll(String.fromCharCode(160), '\n');
        text = text.replaceAll(RegExp(r'\s{4,}'), '\n');
        result['summary'] = text.trim();
      }

      final infoboxItems = document.querySelectorAll('#infobox li');
      for (var li in infoboxItems) {
        if (li.text.contains('话数:')) {
          var episodes = li.text.replaceAll('话数:', '').trim();
          if (RegExp(r'^\d+$').hasMatch(episodes)) {
            episodes += '集';
          }
          result['duration'] = episodes;
          break;
        }
      }
    }
    return result;
  }

  Future<Map<String, List<Media>>> getWeeklySchedule() async {
    const url = '$_baseUrl/calendar';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Cookie': 'chii_searchDateLine=0',
        },
      );

      if (response.statusCode != 200) {
        log('Bangumi Calendar API Error: ${response.statusCode}');
        return {};
      }

      final document = parser.parse(utf8.decode(response.bodyBytes));
      final weekItems = document
          .querySelectorAll('#colunmSingle .BgmCalendar ul.large > li.week');

      final Map<String, List<Media>> schedule = {};

      for (var weekItem in weekItems) {
        String dayKey = '';
        final dt = weekItem.querySelector('dt');
        if (dt != null) {
          final classList = dt.classes;
          if (classList.contains('Sun')) {
            dayKey = 'Sun';
          } else if (classList.contains('Mon')) {
            dayKey = 'Mon';
          } else if (classList.contains('Tue')) {
            dayKey = 'Tue';
          } else if (classList.contains('Wed')) {
            dayKey = 'Wed';
          } else if (classList.contains('Thu')) {
            dayKey = 'Thu';
          } else if (classList.contains('Fri')) {
            dayKey = 'Fri';
          } else if (classList.contains('Sat')) {
            dayKey = 'Sat';
          }
        }

        if (dayKey.isEmpty) continue;

        final animeItems = weekItem.querySelectorAll('dd ul.coverList > li');
        List<Media> animeList = [];

        for (var item in animeItems) {
          try {
            String title = '';
            String id = '';
            String cover = '';

            final titleLink = item.querySelector('.info p a.nav');
            if (titleLink != null) {
              title = titleLink.text.trim();
              final href = titleLink.attributes['href'] ?? '';
              id = href.split('/').last;
            }

            // Fallback for title/link in other structure
            if (title.isEmpty) {
              final altLink = item.querySelector('.info a');
              if (altLink != null) {
                title = altLink.text.trim();
                final href = altLink.attributes['href'] ?? '';
                id = href.split('/').last;
              }
            }

            final style = item.attributes['style'] ?? '';
            final urlMatch = RegExp(r"url\('?([^')]+)'?\)").firstMatch(style);
            if (urlMatch != null) {
              cover = urlMatch.group(1) ?? '';
              if (cover.startsWith('//')) cover = 'https:$cover';
              cover = cover.replaceAll(RegExp(r'/s/|/g/|/c/'), '/l/');
            }

            String originalTitle = '';

            final subtitleElement = item.querySelector('.info small em');
            if (subtitleElement != null) {
              originalTitle = subtitleElement.text.trim();
            }

            if (title.isNotEmpty && id.isNotEmpty) {
              animeList.add(Media(
                sourceType: 'bgm',
                sourceId: id,
                sourceUrl: '$_baseUrl/subject/$id',
                mediaType: 'anime',
                titleZh: title,
                titleOriginal: originalTitle,
                posterUrl: cover,
                summary: '',
                releaseDate: '',
                duration: '',
                year: '',
                staff: '',
                rating: 0.0,
                ratingBangumi: 0.0,
              ));
            }
          } catch (e) {
            log('Error parsing daily anime item: $e');
          }
        }
        schedule[dayKey] = animeList;
      }
      return schedule;
    } catch (e) {
      log('Bangumi calendar fetch error: $e');
      return {};
    }
  }
}
