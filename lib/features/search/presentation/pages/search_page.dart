import 'dart:developer';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/domain/entities/media.dart';
import '../../domain/repositories/search_repository.dart';
import '../widgets/search_result_item.dart';
import 'package:drama_tracker_flutter/features/search/data/datasources/search_history_service.dart';
import '../../domain/entities/search_history_item.dart';
import '../../../../app/theme/app_theme.dart';

class SearchPage extends StatefulWidget {
  final String initialQuery;
  final bool autoSearch;
  final String searchType; // 'anime' or 'movie'

  const SearchPage({
    super.key,
    this.initialQuery = '',
    this.autoSearch = false,
    this.searchType = 'anime',
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final SearchRepository _searchRepository = SearchRepositoryImpl();
  final SearchHistoryService _historyService = SearchHistoryService();

  List<Media> _results = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _lastSearchedQuery = '';
  List<SearchHistoryItem> _history = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.text = widget.initialQuery;
    if (widget.autoSearch && widget.initialQuery.isNotEmpty) {
      _performSearch(widget.initialQuery);
    }
  }

  Future<void> _loadHistory() async {
    final history = await _historyService.getHistory();
    if (mounted) {
      setState(() {
        _history = history;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      if (query.isNotEmpty && query != _lastSearchedQuery) {
        _performSearch(query);
      }
    });
  }

  void _onSearchSubmitted(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel(); // Cancel pending debounce
    _searchFocusNode.unfocus(); // Dismiss keyboard
    if (query.isNotEmpty) {
      _performSearch(query, force: true);
    }
  }

  Future<void> _performSearch(String query, {bool force = false}) async {
    if (query.isEmpty) return;
    if (!force && query == _lastSearchedQuery) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _results = [];
      _lastSearchedQuery = query;
    });

    try {
      // Aggregated Search based on searchType
      // 'movie': TMDb, Maoyan, (and Douban if available via repository)
      // 'anime': Bangumi (searchAnime)

      List<Future<List<Media>>> searchFutures = [];

      if (widget.searchType == 'movie') {
        // Search Movies/TV (TMDb, Maoyan, etc.)
        searchFutures.add(_searchRepository.searchMovie(query));
      } else if (widget.searchType == 'anime') {
        // Search Anime (Bangumi)
        searchFutures.add(_searchRepository.searchAnime(query));
      }

      final results = await Future.wait(searchFutures);

      if (!mounted) return;

      final combinedResults = results.expand((element) => element).toList();

      // Save to history (Non-blocking)
      try {
        await _historyService.addHistory(query, 'mixed'); // Use 'mixed' or keep existing types
        if (mounted) {
          await _loadHistory();
        }
      } catch (e) {
        log('Failed to save search history: $e');
      }

      if (!mounted) return;

      setState(() {
        _results = combinedResults;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '搜索失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final hintColor = Theme.of(context).hintColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: scaffoldBg,
        elevation: 0,
        title: Text('搜索', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.grey[400] : Colors.grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[200],
                borderRadius: BorderRadius.circular(24),
                border: isDark
                    ? Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      )
                    : null,
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                autofocus: true,
                style: TextStyle(color: textColor),
                onSubmitted: (value) {
                  _onSearchSubmitted(value);
                },
                decoration: InputDecoration(
                  hintText: widget.searchType == 'movie' ? '搜索电影/电视剧' : '搜索动漫',
                  hintStyle: TextStyle(color: hintColor),
                  prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? (_searchController.text != _lastSearchedQuery
                          ? IconButton(
                              icon: Icon(Icons.check_circle, size: 20, color: AppTheme.primary),
                              onPressed: () {
                                _onSearchSubmitted(_searchController.text);
                              },
                            )
                          : IconButton(
                              icon: Icon(Icons.delete, size: 20, color: isDark ? Colors.grey[400] : Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _results = [];
                                  _errorMessage = '';
                                  _lastSearchedQuery = '';
                                });
                                // Cancel any pending debounce
                                _debounce?.cancel();
                              },
                            ))
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (text) {
                  setState(() {}); // trigger rebuild to show/hide clear button
                  _onSearchChanged(text);
                },
              ),
            ),
          ),

          // Content Area
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: TextStyle(color: textColor)))
                    : (_results.isEmpty &&
                            _searchController.text.isEmpty) // Show history when no results and input empty
                        ? _buildHistorySection(context)
                        : _results.isEmpty
                            ? Center(child: Text('没有找到相关结果', style: TextStyle(color: textColor)))
                            : ListView.builder(
                                itemCount: _results.length,
                                itemBuilder: (context, index) {
                                  return SearchResultItem(
                                    result: _results[index],
                                    searchType: widget.searchType,
                                    onTap: () {
                                      // Optional: Handle item tap if unrelated to specific buttons
                                      _searchFocusNode.unfocus();
                                    },
                                  );
                                },
                              ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    if (_history.isEmpty) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '搜索历史',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: isDark ? Colors.grey[400] : Colors.grey),
                onPressed: () async {
                  await _historyService.clearHistory();
                  await _loadHistory();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _history.map((item) {
              return ActionChip(
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[100],
                elevation: 0,
                side: isDark ? BorderSide(color: Colors.white.withValues(alpha: 0.1)) : BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.query,
                      style: TextStyle(color: textColor, fontSize: 13),
                    ),
                  ],
                ),
                onPressed: () {
                  _searchController.text = item.query;
                  _performSearch(item.query);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
