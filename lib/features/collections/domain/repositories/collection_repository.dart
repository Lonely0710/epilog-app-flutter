import 'dart:async';

import 'package:flutter/foundation.dart'; // for debugPrint
import 'package:rxdart/rxdart.dart';
import '../../../../core/domain/entities/media.dart';
import '../../../../core/services/convex_service.dart';
import 'dart:convert';

abstract class CollectionRepository {
  factory CollectionRepository() {
    return ConvexCollectionRepositoryImpl.instance;
  }

  /// Ensures the media exists in the database (deduplicated) and adds it to the user's collection.
  /// [status]: 'wish', 'watching', 'watched', 'on_hold', 'dropped'
  /// Returns the collection ID.
  Future<String> addToCollection(Media media, {String status = 'wish'});

  /// Checks if the media is already collected by the current user.
  /// Returns the collection ID if exists, null otherwise.
  Future<String?> checkCollectionStatus(String sourceId, String sourceType);

  /// Removes the media from the user's collection.
  Future<void> removeFromCollection(String collectionId);

  /// Updates the watch status of an existing collection item.
  Future<void> updateWatchStatus(String collectionId, String status);

  /// Fetches all media collected by the current user.
  /// [mediaTypes]: Optional filter by media_type (e.g., ['movie', 'tv'] or ['anime'])
  Future<List<Media>> getCollectedMedia({List<String>? mediaTypes});

  /// Stream that emits whenever the collection changes (add/remove/update).
  Stream<void> get onCollectionChanged;

  /// Watch a specific media item for real-time updates
  Stream<Media?> watchMedia(String mediaId);

  /// Watch a specific media item for real-time updates by Source ID
  Stream<Media?> watchMediaBySource(String sourceId, String sourceType);
}

// ===========================================
// CONVEX IMPLEMENTATION
// ===========================================

class ConvexCollectionRepositoryImpl implements CollectionRepository {
  // Singleton Pattern
  static final ConvexCollectionRepositoryImpl _instance = ConvexCollectionRepositoryImpl._internal();
  static ConvexCollectionRepositoryImpl get instance => _instance;

  ConvexCollectionRepositoryImpl._internal();

  final _changeController = BehaviorSubject<void>();

  @override
  Stream<void> get onCollectionChanged => _changeController.stream;

  @override
  Stream<Media?> watchMedia(String mediaId) {
    if (mediaId.isEmpty) return Stream.value(null);

    late StreamController<Media?> controller;
    // We'll store the unsubscribe function returned by subscribe
    dynamic unsubscribe;

    controller = StreamController<Media?>(
      onListen: () {
        final client = ConvexService.instance.client;
        unsubscribe = client.subscribe(
          name: 'media:get',
          args: {'id': mediaId},
          onUpdate: (dynamic jsonStr, [dynamic error]) {
            if (error != null) {
              controller.addError(error);
              return;
            }

            if (jsonStr != null && jsonStr != 'null') {
              try {
                dynamic data;
                if (jsonStr is String) {
                  data = jsonDecode(jsonStr);
                } else {
                  data = jsonStr;
                }

                if (data == null) {
                  controller.add(null);
                } else {
                  controller.add(Media.fromJson(data as Map<String, dynamic>));
                }
              } catch (e) {
                controller.addError(e);
              }
            } else {
              controller.add(null);
            }
          },
          onError: (String error, String? code) {
            controller.addError('$error ${code ?? ''}');
          },
        );
      },
      onCancel: () {
        if (unsubscribe is Function) {
          unsubscribe();
        }
      },
    );

    return controller.stream;
  }

  @override
  Stream<Media?> watchMediaBySource(String sourceId, String sourceType) {
    if (sourceId.isEmpty || sourceType.isEmpty) return Stream.value(null);

    late StreamController<Media?> controller;
    dynamic unsubscribe;

    controller = StreamController<Media?>(
      onListen: () {
        final client = ConvexService.instance.client;
        unsubscribe = client.subscribe(
          name: 'media:getBySource',
          args: {'sourceId': sourceId, 'sourceType': sourceType},
          onUpdate: (dynamic jsonStr, [dynamic error]) {
            if (error != null) {
              controller.addError(error);
              return;
            }

            if (jsonStr != null && jsonStr != 'null') {
              try {
                dynamic data;
                if (jsonStr is String) {
                  data = jsonDecode(jsonStr);
                } else {
                  data = jsonStr;
                }

                if (data == null) {
                  controller.add(null);
                } else {
                  controller.add(Media.fromJson(data as Map<String, dynamic>));
                }
              } catch (e) {
                controller.addError(e);
              }
            } else {
              controller.add(null);
            }
          },
          onError: (String error, String? code) {
            controller.addError('$error ${code ?? ''}');
          },
        );
      },
      onCancel: () {
        if (unsubscribe is Function) {
          unsubscribe();
        }
      },
    );

    return controller.stream;
  }

  @override
  Future<String> addToCollection(Media media, {String status = 'wish'}) async {
    try {
      final client = ConvexService.instance.client;

      // Workaround for convex_flutter FFI bug: serialize arrays as JSON strings
      // The FFI layer calls .toString() on arrays instead of proper JSON encoding
      final actorsList = media.actors.map((e) => e.toString()).toList();
      final directorsList = media.directors.map((e) => e.toString()).toList();

      // Build staff object then encode as JSON string
      final staffObj = {
        'info': media.staff,
        'actors': actorsList,
        'directors': directorsList,
      };

      // Build args with JSON-encoded strings for arrays (workaround for FFI bug)
      final Map<String, dynamic> args = {
        'sourceType': media.sourceType,
        'sourceId': media.sourceId,
        'sourceUrl': media.sourceUrl,
        'mediaType': media.mediaType,
        'titleZh': media.titleZh,
        'titleOriginal': media.titleOriginal,
        'releaseDate': media.releaseDate,
        'duration': media.duration,
        'year': media.year,
        'posterUrl': media.posterUrl,
        'summary': media.summary,
        // Encode all arrays as JSON strings to bypass FFI bug
        'staffJson': jsonEncode(staffObj),
        'actorsJson': jsonEncode(actorsList),
        'directorsJson': jsonEncode(directorsList),
        'networksJson': jsonEncode(media.networks),

        'ratingDouban': media.ratingDouban,
        'ratingImdb': media.ratingImdb,
        'ratingBangumi': media.ratingBangumi,
        'ratingMaoyan': media.ratingMaoyan,
        'status': status,
      };

      final result = await client.mutation(name: 'collections:collectMedia', args: args);

      _changeController.add(null);
      return result.toString();
    } catch (e) {
      debugPrint('❌ Convex Add Collection Failed: $e');
      throw Exception('Failed to add to collection: $e');
    }
  }

  @override
  Future<String?> checkCollectionStatus(String sourceId, String sourceType) async {
    try {
      final client = ConvexService.instance.client;
      final result = await client.query('collections:checkCollectionStatus', {
        'sourceType': sourceType,
        'sourceId': sourceId,
      });

      final decoded = jsonDecode(result);
      if (decoded == null) return null;

      // Convex returns Map<String, dynamic> here
      final map = Map<String, dynamic>.from(decoded as Map);
      return map['collectionId']?.toString();
    } catch (e) {
      // Silent fail for check status
      return null;
    }
  }

  @override
  Future<void> removeFromCollection(String collectionId) async {
    try {
      final client = ConvexService.instance.client;
      await client.mutation(name: 'collections:removeCollection', args: {
        'collectionId': collectionId,
      });
      _changeController.add(null);
    } catch (e) {
      debugPrint('❌ Convex Remove Collection Failed: $e');
      throw Exception('Failed to remove from collection');
    }
  }

  @override
  Future<void> updateWatchStatus(String collectionId, String status) async {
    try {
      final client = ConvexService.instance.client;
      await client.mutation(name: 'collections:updateWatchStatus', args: {
        'collectionId': collectionId,
        'status': status,
      });
      _changeController.add(null);
    } catch (e) {
      debugPrint('❌ Convex Update Watch Status Failed: $e');
      throw Exception('Failed to update watch status: $e');
    }
  }

  @override
  Future<List<Media>> getCollectedMedia({List<String>? mediaTypes}) async {
    try {
      final client = ConvexService.instance.client;
      final dynamic results = await client.query('collections:getUserCollections', {
        '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      List<dynamic> list;
      if (results is String) {
        if (results.isEmpty || results == 'null') return [];
        final decoded = jsonDecode(results);
        if (decoded == null) return [];
        list = decoded as List;
      } else if (results is List) {
        list = results;
      } else {
        debugPrint('❌ Unexpected result type from Convex: ${results.runtimeType}');
        return [];
      }

      final medias = list.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return Media.fromJson(map);
      }).toList();

      if (mediaTypes != null) {
        final filtered = medias.where((m) => mediaTypes.contains(m.mediaType)).toList();
        return filtered;
      }
      return medias;
    } catch (e) {
      debugPrint('❌ Convex Get Collections Failed: $e');
      return [];
    }
  }
}
