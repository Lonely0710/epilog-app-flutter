import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../../core/domain/entities/media.dart';
import '../../../collections/domain/repositories/collection_repository.dart';

class ExportService {
  final CollectionRepository _repository;

  ExportService({CollectionRepository? repository}) : _repository = repository ?? CollectionRepository();

  Future<File> exportCollections({List<String>? mediaTypes}) async {
    // 1. Fetch Data
    final List<Media> mediaList = await _repository.getCollectedMedia(mediaTypes: mediaTypes);

    // 2. Generate CSV Content
    final StringBuffer csvBuffer = StringBuffer();

    // Determine which columns to show
    final bool isAnimeOnly = mediaTypes != null && mediaTypes.length == 1 && mediaTypes.contains('anime');
    final bool isTvMovieOnly = mediaTypes != null &&
        !mediaTypes.contains('anime') &&
        (mediaTypes.contains('tv') || mediaTypes.contains('movie'));

    final List<String> headers = [
      'Title (CN)',
      'Title (Original)',
      'Media Type',
      'Release Date',
      'Duration',
    ];

    // Rating columns conditional logic
    if (isTvMovieOnly) {
      headers.addAll(['Rating (Maoyan)', 'Rating (Douban)', 'Rating (IMDb)']);
    } else if (isAnimeOnly) {
      headers.addAll(['Rating (Bangumi)']);
    } else {
      // All
      headers.addAll(['Rating (Maoyan)', 'Rating (Douban)', 'Rating (IMDb)', 'Rating (Bangumi)']);
    }

    headers.addAll(['Watch Status', 'Collection Date']);

    // Write Header
    csvBuffer.writeln(headers.join(','));

    // Rows
    for (final media in mediaList) {
      final List<String> row = [];
      row.add(_escape(media.titleZh));
      row.add(_escape(media.titleOriginal));
      row.add(_escape(media.mediaType));
      row.add(_escape(media.releaseDate));
      row.add(_escape(media.duration));

      if (isTvMovieOnly) {
        row.add(media.ratingMaoyan.toString());
        row.add(media.ratingDouban.toString());
        row.add(media.ratingImdb.toString());
      } else if (isAnimeOnly) {
        row.add(media.ratingBangumi.toString());
      } else {
        // All
        row.add(media.ratingMaoyan.toString());
        row.add(media.ratingDouban.toString());
        row.add(media.ratingImdb.toString());
        row.add(media.ratingBangumi.toString());
      }

      row.add(_escape(media.watchingStatus ?? ''));
      // Date placeholder
      row.add('');

      csvBuffer.writeln(row.join(','));
    }

    // 3. Save to Temp File
    final directory = await getTemporaryDirectory();
    final String fileName = 'epilog_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final File file = File('${directory.path}/$fileName');

    return await file.writeAsString(csvBuffer.toString());
  }

  String _escape(String? value) {
    if (value == null) return '';
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
