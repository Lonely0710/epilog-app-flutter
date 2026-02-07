import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../../../../core/domain/entities/media.dart';
import '../../../../core/services/convex_service.dart';

abstract class SearchRepository {
  Future<List<Media>> searchAnime(String query);
  Future<List<Media>> searchMovie(String query);
  Future<List<Media>> searchAll(String query);

  factory SearchRepository() {
    return ConvexSearchRepositoryImpl();
  }
}

class ConvexSearchRepositoryImpl implements SearchRepository {
  @override
  Future<List<Media>> searchAnime(String query) => _searchMedia(query, 'anime');

  @override
  Future<List<Media>> searchMovie(String query) => _searchMedia(query, 'movie');

  @override
  Future<List<Media>> searchAll(String query) => _searchMedia(query, 'all');

  Future<List<Media>> _searchMedia(String query, String type) async {
    if (query.isEmpty) return [];

    try {
      final client = ConvexService.instance.client;

      final results = await client.action(
        name: 'searchMedia:search',
        args: {
          'query': query,
          'type': type,
        },
      );

      final List<dynamic> list;
      final Object rawResults = results;

      if (rawResults is List) {
        list = rawResults;
      } else if (rawResults is String) {
        try {
          final decoded = jsonDecode(rawResults);
          if (decoded is List) {
            list = decoded;
          } else {
            return [];
          }
        } catch (e) {
          return [];
        }
      } else {
        return [];
      }

      return list
          .map((item) {
            try {
              final map = Map<String, dynamic>.from(item as Map);
              return Media.fromJson(map);
            } catch (e) {
              return null;
            }
          })
          .whereType<Media>()
          .toList();
    } catch (e) {
      debugPrint('❌ Repo: Convex Search failed: $e');
      return [];
    }
  }
}
