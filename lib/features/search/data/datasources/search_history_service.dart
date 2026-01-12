import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/search_history_item.dart';

class SearchHistoryService {
  static const String _key = 'search_history_v1';
  static const int _maxItems = 20;

  Future<List<SearchHistoryItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_key);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => SearchHistoryItem.fromJson(json)).toList();
    } catch (e) {
      // In case of error (e.g. format change), return empty list and maybe clear corrupt data
      return [];
    }
  }

  Future<void> addHistory(String query, String type) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<SearchHistoryItem> history = await getHistory();

    // Remove existing item with same query (to move to top)
    history.removeWhere((item) => item.query == query);

    // Add new item to top
    history.insert(
      0,
      SearchHistoryItem(
        query: query,
        type: type,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    // Limit size
    if (history.length > _maxItems) {
      history = history.sublist(0, _maxItems);
    }

    // Save
    final String jsonString =
        jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> deleteHistoryItem(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<SearchHistoryItem> history = await getHistory();

    history.removeWhere((item) => item.query == query);

    final String jsonString =
        jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }
}
