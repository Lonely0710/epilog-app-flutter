import 'dart:async';
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/domain/entities/media.dart';
import '../../domain/repositories/collection_repository.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  // Singleton pattern
  static final CollectionRepositoryImpl _instance =
      CollectionRepositoryImpl._internal();

  factory CollectionRepositoryImpl() {
    return _instance;
  }

  CollectionRepositoryImpl._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final _controller = StreamController<void>.broadcast();

  @override
  Stream<void> get onCollectionChanged => _controller.stream;

  @override
  Future<String> addToCollection(Media media, {String status = 'wish'}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // 1. Resolve Media ID (Deduplication Logic)
      final mediaId = await _ensureMediaExists(media);

      // 2. Add to Collections
      // We use upsert to update status if it already exists, or insert if new.
      // unique constraint is (user_id, media_id)
      final res = await _client
          .from('collections')
          .upsert({
            'user_id': user.id,
            'media_id': mediaId,
            'watching_status': status,
          }, onConflict: 'user_id, media_id')
          .select('id')
          .single();

      log('Added to collection: ${media.titleZh} ($mediaId)');
      _controller.add(null);
      return res['id'] as String;
    } catch (e) {
      log('Error adding to collection: $e', error: e);
      rethrow;
    }
  }

  @override
  Future<String?> checkCollectionStatus(
      String sourceId, String sourceType) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    // We can't easily check collection status by sourceId directly without joining.
    // Query: collections -> media -> media_source
    // Or: media_source -> media -> collections

    try {
      final response = await _client
          .from('media_source')
          .select('''
        media:media_id (
          collections (
            id,
            watching_status
          )
        )
      ''')
          .eq('source_type', sourceType)
          .eq('source_id', sourceId)
          .maybeSingle();

      if (response == null) return null;

      final mediaData = response['media'] as Map<dynamic, dynamic>?;
      if (mediaData == null) return null;

      final collections = mediaData['collections'] as List<dynamic>?;
      if (collections != null && collections.isNotEmpty) {
        return collections[0]['id'] as String;
      }
    } catch (e) {
      log('Error checking status: $e');
    }
    return null;
  }

  @override
  Future<void> removeFromCollection(String collectionId) async {
    await _client.from('collections').delete().eq('id', collectionId);
    _controller.add(null);
  }

  @override
  Future<void> updateWatchStatus(String collectionId, String status) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      await _client
          .from('collections')
          .update({'watching_status': status}).eq('id', collectionId);

      log('Updated collection status: $status ($collectionId)');
      _controller.add(null);
    } catch (e) {
      log('Error updating collection status: $e', error: e);
      rethrow;
    }
  }

  // --- Helper: Deduplication & Insertion ---

  Future<String> _ensureMediaExists(Media media) async {
    // Step 1: Check by Source ID (Exact Match)
    final sourceRes = await _client
        .from('media_source')
        .select('media_id')
        .eq('source_type', media.sourceType)
        .eq('source_id', media.sourceId)
        .maybeSingle();

    if (sourceRes != null) {
      return sourceRes['media_id'] as String;
    }

    // Step 2: Check by Content (Fuzzy Match)
    // Only if we have valid title and matching criteria.
    // Criteria: Media Type AND Year (Release Date) AND (TitleZh OR TitleOrigin)
    // Note: Parsing year/date can be tricky.

    // Attempt parse date
    String? dateToMatch;
    if (media.releaseDate.isNotEmpty) {
      // Try to ensure format YYYY-MM-DD
      // Some APIs return '2023', others '2023-01-01'.
      if (media.releaseDate.length == 4) {
        dateToMatch =
            '${media.releaseDate}-01-01'; // Default to Jan 1st if only year
      } else {
        dateToMatch = media.releaseDate;
      }
    }

    String? existingMediaId;

    if (dateToMatch != null) {
      // We'll simplify and matching on title and media_type strictly for now,
      // adding date matching makes query complex if format mismatches.
      // But user requested "Strict matching".
      // Let's try to match media_type and title first.

      final fuzzyRes =
          await _client.from('media').select('id, release_date').match({
        'media_type': media.mediaType,
      }).or('title_zh.eq.${media.titleZh},title_origin.eq.${media.titleOriginal}');

      // Filter by Year in Dart for flexibility
      for (final item in fuzzyRes) {
        final dbDate = item['release_date'] as String?;
        if (dbDate != null) {
          final dbYear = DateTime.tryParse(dbDate)?.year;
          final inputYear = DateTime.tryParse(dateToMatch)?.year;
          if (dbYear != null &&
              inputYear != null &&
              (dbYear - inputYear).abs() <= 1) {
            existingMediaId = item['id'] as String;
            break;
          }
        }
      }
    }

    if (existingMediaId != null) {
      // Step 3a: Found by Fuzzy -> Insert new Source linking to this Media (so next time we find it by source)
      await _insertMediaSource(existingMediaId, media);
      return existingMediaId;
    }

    // Step 3b: Not found -> Create New Media and Source
    final newMediaId = await _insertNewMedia(media);
    await _insertMediaSource(newMediaId, media);
    return newMediaId;
  }

  Future<String> _insertNewMedia(Media media) async {
    // Parse Date for DB
    String? releaseDateVal;
    if (media.releaseDate.isNotEmpty) {
      // simple check
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(media.releaseDate)) {
        releaseDateVal = media.releaseDate;
      } else if (RegExp(r'^\d{4}$').hasMatch(media.releaseDate)) {
        releaseDateVal = '${media.releaseDate}-01-01';
      }
    }

    // Prepare staff json
    final Map<String, dynamic> staffJson = {
      'info': media.staff,
      'directors': media.directors,
      'actors': media.actors,
    };

    final res = await _client
        .from('media')
        .insert({
          'media_type': media.mediaType,
          'title_zh': media.titleZh,
          'title_origin': media.titleOriginal,
          'release_date': releaseDateVal,
          'duration': media.duration,
          'poster_url': media.posterUrl,
          'summary': media.summary,
          'staff': staffJson,
          'rating_douban': media.ratingDouban > 0 ? media.ratingDouban : null,
          'rating_bangumi':
              media.ratingBangumi > 0 ? media.ratingBangumi : null,
          'rating_tmdb': media.ratingImdb > 0
              ? media.ratingImdb
              : null, // Assuming ratingImdb maps to TMDB rating in app
          'rating_maoyan': media.ratingMaoyan > 0 ? media.ratingMaoyan : null,
        })
        .select('id')
        .single();

    return res['id'] as String;
  }

  Future<void> _insertMediaSource(String mediaId, Media media) async {
    await _client.from('media_source').insert({
      'media_id': mediaId,
      'source_type': media.sourceType,
      'source_id': media.sourceId,
      'source_url': media.sourceUrl,
    });
  }

  @override
  Future<List<Media>> getCollectedMedia({List<String>? mediaTypes}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return [];
    }

    try {
      // Build query: collections joined with media
      var query = _client.from('collections').select('''
            id,
            watching_status,
            created_at,
            media:media_id (
              id,
              media_type,
              title_zh,
              title_origin,
              release_date,
              duration,
              poster_url,
              summary,
              staff,
              rating_douban,
              rating_bangumi,
              rating_tmdb,
              rating_maoyan
            )
          ''').eq('user_id', user.id).order('created_at', ascending: false);

      final response = await query;

      final List<Media> result = [];
      for (final item in response) {
        final mediaData = item['media'] as Map<String, dynamic>?;
        if (mediaData == null) continue;

        final mediaType = mediaData['media_type'] as String? ?? '';

        // Filter by media types if specified
        if (mediaTypes != null && !mediaTypes.contains(mediaType)) {
          continue;
        }

        // Parse staff JSON
        final staffData = mediaData['staff'] as Map<String, dynamic>?;
        final staffInfo = staffData?['info'] as String? ?? '';
        final directors = (staffData?['directors'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final actors = (staffData?['actors'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        // Extract year from release_date
        final releaseDate = mediaData['release_date'] as String? ?? '';
        String year = '';
        if (releaseDate.isNotEmpty) {
          final parsed = DateTime.tryParse(releaseDate);
          if (parsed != null) {
            year = parsed.year.toString();
          }
        }

        result.add(Media(
          sourceType: 'supabase',
          sourceId: mediaData['id'] as String? ?? '',
          sourceUrl: '',
          mediaType: mediaType,
          titleZh: mediaData['title_zh'] as String? ?? '',
          titleOriginal: mediaData['title_origin'] as String? ?? '',
          releaseDate: releaseDate,
          duration: mediaData['duration'] as String? ?? '',
          year: year,
          posterUrl: mediaData['poster_url'] as String? ?? '',
          summary: mediaData['summary'] as String? ?? '',
          staff: staffInfo,
          directors: directors,
          actors: actors,
          rating: (mediaData['rating_douban'] as num?)?.toDouble() ?? 0.0,
          ratingDouban: (mediaData['rating_douban'] as num?)?.toDouble() ?? 0.0,
          ratingBangumi:
              (mediaData['rating_bangumi'] as num?)?.toDouble() ?? 0.0,
          ratingImdb: (mediaData['rating_tmdb'] as num?)?.toDouble() ?? 0.0,
          ratingMaoyan: (mediaData['rating_maoyan'] as num?)?.toDouble() ?? 0.0,
          isCollected: true,
          collectionId: item['id'] as String? ?? '',
          watchingStatus: item['watching_status'] as String? ?? 'wish',
        ));
      }

      return result;
    } catch (e) {
      log('Error fetching collected media: $e', error: e);
      return [];
    }
  }
}
