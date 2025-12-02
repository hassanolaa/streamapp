import 'dart:convert';
import 'dart:io';
import 'package:streamapp/features/videos/data/models/info_model.dart';
import 'package:streamapp/features/videos/data/models/items_model.dart';
import 'package:streamapp/features/videos/data/models/search_result_model.dart';

abstract class VideosRemoteDataSource {
  /// Get list of available search providers (YouTube, PeerTube, SoundCloud, etc.)
  Future<List<String>> getSearchProviders();
  
  /// Search for content using a specific provider
  Future<SearchResultModel> search(
    String provider,
    String query, {
    List<String>? filters,
  });
  
  /// Load more results using pagination token
  Future<ItemsModel> loadMore(String pageToken);
  
  /// Get detailed stream/video information
  Future<StreamInfoModel> getStreamInfo(String url);
  
  /// Get playlist information
  Future<PlaylistInfoModel> getPlaylistInfo(String url);
  
  /// Get channel information
  Future<ChannelInfoModel> getChannelInfo(String url);
}

class VideosRemoteDataSourceImpl implements VideosRemoteDataSource {
  final String tuberJarPath;
  final String? javaPath;

  VideosRemoteDataSourceImpl({
    required this.tuberJarPath,
    this.javaPath,
  });

  /// Get the correct Java executable path
  String _getJavaPath() {
    print('Using Java path: ${javaPath ?? "system default"}');
    if (javaPath != null) return javaPath!;
    
    // Try to find Java 21+ in common locations
    final possiblePaths = [
      '/usr/lib/jvm/java-25-openjdk-amd64/bin/java',
      '/usr/lib/jvm/java-21-openjdk-amd64/bin/java',
      '/usr/lib/jvm/java-20-openjdk-amd64/bin/java',
      '/usr/lib/jvm/default-java/bin/java',
      'java', // Fallback to system PATH
    ];

    for (final path in possiblePaths) {
      if (path == 'java' || File(path).existsSync()) {
        return path;
      }
    }

    return 'java'; // Ultimate fallback
  }

  /// Execute tuber CLI command and return parsed JSON
  Future<dynamic> _executeCommand(List<String> args) async {
    try {
      final javaExec = _getJavaPath();
      
      // Execute the Java command
      final result = await Process.run(
        javaExec,
        ['-jar', tuberJarPath, ...args],
        runInShell: false, // Changed to false to avoid shell PATH issues
      );

      // Check for errors
      if (result.exitCode != 0) {
        final errorMessage = result.stderr?.toString() ?? 'Unknown error';
        throw TuberException(
          'Tuber command failed with exit code ${result.exitCode}: $errorMessage',
        );
      }

      // Parse JSON output
      final output = result.stdout.toString().trim();
      if (output.isEmpty) {
        throw TuberException('Empty response from tuber');
      }

      return jsonDecode(output);
    } on ProcessException catch (e) {
      throw TuberException('Failed to execute tuber process: ${e.message}\nJava path: ${_getJavaPath()}');
    } on FormatException catch (e) {
      throw TuberException('Invalid JSON response from tuber: ${e.message}');
    } catch (e) {
      throw TuberException('Unexpected error executing tuber: $e');
    }
  }

  @override
  Future<List<String>> getSearchProviders() async {
    try {
      final result = await _executeCommand(['search-providers']);
      return List<String>.from(result as List);
    } catch (e) {
      throw TuberException('Failed to get search providers: $e');
    }
  }

  @override
  Future<SearchResultModel> search(
    String provider,
    String query, {
    List<String>? filters,
  }) async {
    try {
      final args = ['search', provider, query];
      if (filters != null && filters.isNotEmpty) {
        args.addAll(filters);
      }

      final result = await _executeCommand(args);
      return SearchResultModel.fromJson(result as Map<String, dynamic>);
    } catch (e) {
      throw TuberException('Failed to search: $e');
    }
  }

  @override
  Future<ItemsModel> loadMore(String pageToken) async {
    try {
      final result = await _executeCommand(['more', pageToken]);
      return ItemsModel.fromJson(result as Map<String, dynamic>);
    } catch (e) {
      throw TuberException('Failed to load more items: $e');
    }
  }

  @override
  Future<StreamInfoModel> getStreamInfo(String url) async {
    try {
      final result = await _executeCommand(['stream', url]);
      return StreamInfoModel.fromJson(result as Map<String, dynamic>);
    } catch (e) {
      throw TuberException('Failed to get stream info: $e');
    }
  }

  @override
  Future<PlaylistInfoModel> getPlaylistInfo(String url) async {
    try {
      final result = await _executeCommand(['playlist', url]);
      return PlaylistInfoModel.fromJson(result as Map<String, dynamic>);
    } catch (e) {
      throw TuberException('Failed to get playlist info: $e');
    }
  }

  @override
  Future<ChannelInfoModel> getChannelInfo(String url) async {
    try {
      final result = await _executeCommand(['channel', url]);
      return ChannelInfoModel.fromJson(result as Map<String, dynamic>);
    } catch (e) {
      throw TuberException('Failed to get channel info: $e');
    }
  }
}

/// Custom exception for Tuber-related errors
class TuberException implements Exception {
  final String message;

  TuberException(this.message);

  @override
  String toString() => 'TuberException: $message';
}
