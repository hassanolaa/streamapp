import 'package:get_storage/get_storage.dart';
import 'package:streamapp/features/videos/data/models/info_model.dart';
import 'package:streamapp/features/videos/data/models/search_result_model.dart';

abstract class VideosLocalDataSource {
  /// Cache search results
  Future<void> cacheSearchResults(String query, SearchResultModel results);
  
  /// Get cached search results
  Future<SearchResultModel?> getCachedSearchResults(String query);
  
  /// Cache stream info
  Future<void> cacheStreamInfo(String url, StreamInfoModel info);
  
  /// Get cached stream info
  Future<StreamInfoModel?> getCachedStreamInfo(String url);
  
  /// Save search history
  Future<void> addToSearchHistory(String query);
  
  /// Get search history
  Future<List<String>> getSearchHistory();
  
  /// Clear search history
  Future<void> clearSearchHistory();
  
  /// Clear all cache
  Future<void> clearAllCache();
}

class VideosLocalDataSourceImpl implements VideosLocalDataSource {
  final GetStorage storage;
  
  static const String _searchCachePrefix = 'search_cache_';
  static const String _streamCachePrefix = 'stream_cache_';
  static const String _searchHistoryKey = 'search_history';
  static const Duration _cacheExpiration = Duration(hours: 24);

  VideosLocalDataSourceImpl({required this.storage});

  String _getCacheKey(String prefix, String key) {
    // Create a safe cache key
    final sanitized = key.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    return '$prefix$sanitized';
  }

  @override
  Future<void> cacheSearchResults(String query, SearchResultModel results) async {
    try {
      final cacheData = {
        'data': results.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await storage.write(_getCacheKey(_searchCachePrefix, query), cacheData);
    } catch (e) {
      // Silent fail - caching is not critical
      print('Failed to cache search results: $e');
    }
  }

  @override
  Future<SearchResultModel?> getCachedSearchResults(String query) async {
    try {
      final cached = storage.read<Map<String, dynamic>>(
        _getCacheKey(_searchCachePrefix, query),
      );
      
      if (cached == null) return null;

      // Check if cache is expired
      final timestamp = cached['timestamp'] as int?;
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (DateTime.now().difference(cacheTime) > _cacheExpiration) {
          // Cache expired, remove it
          await storage.remove(_getCacheKey(_searchCachePrefix, query));
          return null;
        }
      }

      return SearchResultModel.fromJson(cached['data'] as Map<String, dynamic>);
    } catch (e) {
      print('Failed to get cached search results: $e');
      return null;
    }
  }

  @override
  Future<void> cacheStreamInfo(String url, StreamInfoModel info) async {
    try {
      final cacheData = {
        'data': info.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await storage.write(_getCacheKey(_streamCachePrefix, url), cacheData);
    } catch (e) {
      print('Failed to cache stream info: $e');
    }
  }

  @override
  Future<StreamInfoModel?> getCachedStreamInfo(String url) async {
    try {
      final cached = storage.read<Map<String, dynamic>>(
        _getCacheKey(_streamCachePrefix, url),
      );
      
      if (cached == null) return null;

      // Check if cache is expired
      final timestamp = cached['timestamp'] as int?;
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (DateTime.now().difference(cacheTime) > _cacheExpiration) {
          await storage.remove(_getCacheKey(_streamCachePrefix, url));
          return null;
        }
      }

      return StreamInfoModel.fromJson(cached['data'] as Map<String, dynamic>);
    } catch (e) {
      print('Failed to get cached stream info: $e');
      return null;
    }
  }

  @override
  Future<void> addToSearchHistory(String query) async {
    try {
      final history = await getSearchHistory();
      
      // Remove if already exists (to move to top)
      history.remove(query);
      
      // Add to beginning
      history.insert(0, query);
      
      // Keep only last 20 searches
      if (history.length > 20) {
        history.removeRange(20, history.length);
      }

      await storage.write(_searchHistoryKey, history);
    } catch (e) {
      print('Failed to add to search history: $e');
    }
  }

  @override
  Future<List<String>> getSearchHistory() async {
    try {
      final history = storage.read<List>(_searchHistoryKey);
      if (history == null) return [];
      return List<String>.from(history);
    } catch (e) {
      print('Failed to get search history: $e');
      return [];
    }
  }

  @override
  Future<void> clearSearchHistory() async {
    try {
      await storage.remove(_searchHistoryKey);
    } catch (e) {
      print('Failed to clear search history: $e');
    }
  }

  @override
  Future<void> clearAllCache() async {
    try {
      await storage.erase();
    } catch (e) {
      print('Failed to clear cache: $e');
    }
  }
}
