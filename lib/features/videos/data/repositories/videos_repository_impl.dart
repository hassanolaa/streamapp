import 'package:streamapp/features/videos/data/datasources/videos_local_data_source.dart';
import 'package:streamapp/features/videos/data/datasources/videos_remote_data_source.dart';
import 'package:streamapp/features/videos/data/models/info_model.dart';
import 'package:streamapp/features/videos/data/models/items_model.dart';
import 'package:streamapp/features/videos/data/models/search_result_model.dart';

abstract class VideosRepository {
  /// Get list of available search providers
  Future<List<String>> getSearchProviders();

  /// Get available filters for a specific provider
  Future<List<String>> getFilters(String provider);

  /// Get available sort options for a specific provider
  Future<List<String>> getSortOptions(String provider);

  /// Search for content using a specific provider
  Future<SearchResultModel> search(
    String provider,
    String query, {
    List<String>? filters,
    String? sortCriteria,
  });

  /// Search multiple providers simultaneously
  Future<SearchResultModel> searchMultipleProviders(
    List<String> providers,
    String query, {
    List<String>? filters,
    String? sortCriteria,
  });

  /// Load more results using pagination token
  Future<ItemsModel> loadMore(String pageToken);

  /// Load more from multiple providers
  Future<ItemsModel> loadMoreMultipleProviders(Map<String, String> pageTokens);

  /// Get detailed stream/video information
  Future<StreamInfoModel> getStreamInfo(String url);

  /// Get playlist information
  Future<PlaylistInfoModel> getPlaylistInfo(String url);

  /// Get channel information
  Future<ChannelInfoModel> getChannelInfo(String url);

  /// Get list of available catalog providers
  Future<List<String>> getCatalogs();

  /// Get catalog playlists for a specific provider
  Future<List<PlaylistInfoModel>> getCatalog(String catalogProvider);

  /// Get search history
  Future<List<String>> getSearchHistory();

  /// Clear search history
  Future<void> clearSearchHistory();
}

class VideosRepositoryImpl implements VideosRepository {
  final VideosRemoteDataSource remoteDataSource;
  final VideosLocalDataSource localDataSource;

  VideosRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<String>> getSearchProviders() async {
    try {
      return await remoteDataSource.getSearchProviders();
    } catch (e) {
      throw RepositoryException('Failed to get search providers: $e');
    }
  }

  @override
  Future<List<String>> getFilters(String provider) async {
    try {
      return await remoteDataSource.getFilters(provider);
    } catch (e) {
      throw RepositoryException('Failed to get filters for $provider: $e');
    }
  }

  @override
  Future<List<String>> getSortOptions(String provider) async {
    try {
      return await remoteDataSource.getSortOptions(provider);
    } catch (e) {
      throw RepositoryException('Failed to get sort options for $provider: $e');
    }
  }

  @override
  Future<SearchResultModel> search(
    String provider,
    String query, {
    List<String>? filters,
    String? sortCriteria,
  }) async {
    try {
      // Try to get from remote
      final result = await remoteDataSource.search(
        provider,
        query,
        filters: filters,
        sortCriteria: sortCriteria,
      );

      // Cache the result
      await localDataSource.cacheSearchResults(query, result);

      // Add to search history
      await localDataSource.addToSearchHistory(query);

      return result;
    } catch (e) {
      // If remote fails, try to get from cache
      final cached = await localDataSource.getCachedSearchResults(query);
      if (cached != null) {
        return cached;
      }

      throw RepositoryException('Failed to search: $e');
    }
  }

  @override
  Future<SearchResultModel> searchMultipleProviders(
    List<String> providers,
    String query, {
    List<String>? filters,
    String? sortCriteria,
  }) async {
    try {
      final result = await remoteDataSource.searchMultipleProviders(
        providers,
        query,
        filters: filters,
        sortCriteria: sortCriteria,
      );

      // Cache the result
      await localDataSource.cacheSearchResults(query, result);

      // Add to search history
      await localDataSource.addToSearchHistory(query);

      return result;
    } catch (e) {
      throw RepositoryException('Failed to search multiple providers: $e');
    }
  }

  @override
  Future<ItemsModel> loadMore(String pageToken) async {
    try {
      return await remoteDataSource.loadMore(pageToken);
    } catch (e) {
      throw RepositoryException('Failed to load more items: $e');
    }
  }

  @override
  Future<ItemsModel> loadMoreMultipleProviders(
      Map<String, String> pageTokens) async {
    try {
      return await remoteDataSource.loadMoreMultipleProviders(pageTokens);
    } catch (e) {
      throw RepositoryException('Failed to load more from multiple providers: $e');
    }
  }

  @override
  Future<StreamInfoModel> getStreamInfo(String url) async {
    try {
      // Check cache first
      final cached = await localDataSource.getCachedStreamInfo(url);
      if (cached != null) {
        return cached;
      }

      // Get from remote
      final result = await remoteDataSource.getStreamInfo(url);

      // Cache the result
      await localDataSource.cacheStreamInfo(url, result);

      return result;
    } catch (e) {
      throw RepositoryException('Failed to get stream info: $e');
    }
  }

  @override
  Future<PlaylistInfoModel> getPlaylistInfo(String url) async {
    try {
      return await remoteDataSource.getPlaylistInfo(url);
    } catch (e) {
      throw RepositoryException('Failed to get playlist info: $e');
    }
  }

  @override
  Future<ChannelInfoModel> getChannelInfo(String url) async {
    try {
      return await remoteDataSource.getChannelInfo(url);
    } catch (e) {
      throw RepositoryException('Failed to get channel info: $e');
    }
  }

  @override
  Future<List<String>> getCatalogs() async {
    try {
      return await remoteDataSource.getCatalogs();
    } catch (e) {
      throw RepositoryException('Failed to get catalogs: $e');
    }
  }

  @override
  Future<List<PlaylistInfoModel>> getCatalog(String catalogProvider) async {
    try {
      return await remoteDataSource.getCatalog(catalogProvider);
    } catch (e) {
      throw RepositoryException('Failed to get catalog for $catalogProvider: $e');
    }
  }

  @override
  Future<List<String>> getSearchHistory() async {
    try {
      return await localDataSource.getSearchHistory();
    } catch (e) {
      throw RepositoryException('Failed to get search history: $e');
    }
  }

  @override
  Future<void> clearSearchHistory() async {
    try {
      await localDataSource.clearSearchHistory();
    } catch (e) {
      throw RepositoryException('Failed to clear search history: $e');
    }
  }
}

/// Custom exception for repository-related errors
class RepositoryException implements Exception {
  final String message;
  RepositoryException(this.message);

  @override
  String toString() => 'RepositoryException: $message';
}
