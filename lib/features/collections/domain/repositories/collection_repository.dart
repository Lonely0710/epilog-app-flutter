import 'package:drama_tracker_flutter/core/domain/entities/media.dart';

abstract class CollectionRepository {
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
}
