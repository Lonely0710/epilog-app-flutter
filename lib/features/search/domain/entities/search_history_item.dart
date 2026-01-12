class SearchHistoryItem {
  final String query;
  final String type; // 'anime', 'movie', etc.
  final int timestamp;

  SearchHistoryItem({
    required this.query,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'type': type,
      'timestamp': timestamp,
    };
  }

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      query: json['query'] ?? '',
      type: json['type'] ?? 'anime',
      timestamp: json['timestamp'] ?? 0,
    );
  }
}
