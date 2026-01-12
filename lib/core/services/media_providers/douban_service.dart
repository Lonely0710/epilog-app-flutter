import 'dart:convert';
import 'dart:developer';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import '../../domain/entities/media.dart';
import '../../data/models/douban_model.dart';

class DoubanService {
  static const String _baseUrl = 'https://www.douban.com/search?cat=1002&q=';
  static const String _movieBaseUrl = 'https://movie.douban.com';

  Future<List<Media>> searchMovie(String query) async {
    final url = '$_baseUrl$query';
    log('Searching Douban: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
          'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
          'Cache-Control': 'max-age=0',
          'Sec-Ch-Ua':
              '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
          'Sec-Ch-Ua-Mobile': '?0',
          'Sec-Ch-Ua-Platform': '"macOS"',
          'Sec-Fetch-Dest': 'document',
          'Sec-Fetch-Mode': 'navigate',
          'Sec-Fetch-Site': 'none',
          'Sec-Fetch-User': '?1',
          'Upgrade-Insecure-Requests': '1',
        },
      );

      if (response.statusCode != 200) {
        log('Douban API Error: ${response.statusCode}');
        return [];
      }

      final document = parser.parse(utf8.decode(response.bodyBytes));
      final resultList = document.querySelectorAll('.result-list .result');

      List<Media> results = [];

      for (var item in resultList) {
        try {
          // Parse basic info to get ID
          final titleLink = item.querySelector('h3 a');
          if (titleLink == null) continue;
          final onclick = titleLink.attributes['onclick'] ?? '';
          final idMatch = RegExp(r'sid:\s*(\d+)').firstMatch(onclick);
          if (idMatch == null) continue;
          final sourceId = idMatch.group(1)!;

          // Fetch Detail (Optimization: could be parallel or lazy, but keeping logic same as before)
          Map<String, String>? detailData;
          try {
            detailData = await _fetchSubjectDetail(sourceId);
          } catch (e) {
            log('Error fetching Douban detail for $sourceId: $e');
          }

          final model = DoubanModel.fromElement(item, sourceId, detailData);
          results.add(model.toEntity());
        } catch (e) {
          log('Error parsing Douban item: $e');
        }
      }

      return results;
    } catch (e) {
      log('Error searching Douban: $e');
      return [];
    }
  }

  Future<Map<String, String>> _fetchSubjectDetail(String sourceId) async {
    final url = '$_movieBaseUrl/subject/$sourceId';
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to load detail: ${response.statusCode}');
    }

    final doc = parser.parse(utf8.decode(response.bodyBytes));
    final result = <String, String>{};

    final img = doc.querySelector('#mainpic img');
    if (img != null) {
      result['posterUrl'] = img.attributes['src'] ?? '';
    }

    final summaryEl =
        doc.querySelector('#link-report-intra span[property="v:summary"]');
    if (summaryEl != null) {
      result['summary'] =
          summaryEl.text.trim().replaceAll(RegExp(r'\s+'), '\n');
    }

    final h1 = doc.querySelector('h1');
    if (h1 != null) {
      // Original title parsing could be improved but left as placeholder in original logic
    }

    final runtime = doc.querySelector('span[property="v:runtime"]');
    if (runtime != null) {
      result['duration'] = runtime.text.trim();
    }

    final release = doc.querySelector('span[property="v:initialReleaseDate"]');
    if (release != null) {
      result['releaseDate'] = release.text.trim();
    }

    return result;
  }
}
