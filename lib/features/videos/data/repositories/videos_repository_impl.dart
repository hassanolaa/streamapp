import 'package:streamapp/features/videos/data/datasources/videos_local_data_source.dart';
import 'package:streamapp/features/videos/data/datasources/videos_remote_data_source.dart';
import 'package:streamapp/features/videos/data/models/info_model.dart';
import 'package:streamapp/features/videos/data/models/items_model.dart';
import 'package:streamapp/features/videos/data/models/search_result_model.dart';

abstract class VideosRepository {
  Future<List<String>> getSearchProviders();
  Future<SearchResultModel> search(
    String provider,
    String query, {
    List<String>? filters,
  });
  Future<ItemsModel> loadMore(String pageToken);
  Future<StreamInfoModel> getStreamInfo(String url);
  Future<PlaylistInfoModel> getPlaylistInfo(String url);
  Future<ChannelInfoModel> getChannelInfo(String url);
  Future<List<String>> getSearchHistory();
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
  Future<SearchResultModel> search(
    String provider,
    String query, {
    List<String>? filters,
  }) async {
    try {
      // Try to get from remote
      final result = await remoteDataSource.search(
        provider,
        query,
        filters: filters,
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
  Future<ItemsModel> loadMore(String pageToken) async {
    try {
      return await remoteDataSource.loadMore(pageToken);
    } catch (e) {
      throw RepositoryException('Failed to load more items: $e');
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
