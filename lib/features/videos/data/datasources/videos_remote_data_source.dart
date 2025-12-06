import 'dart:convert';
import 'dart:io';
import 'package:streamapp/features/videos/data/models/info_model.dart';
import 'package:streamapp/features/videos/data/models/items_model.dart';
import 'package:streamapp/features/videos/data/models/search_result_model.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';

abstract class VideosRemoteDataSource {
  /// Get list of available search providers
  Future<List<String>> getSearchProviders();

  /// Search for content using a specific provider
  Future<SearchResultModel> search(
    String provider,
    String query, {
    List<String>? filters,
  });

  /// Search multiple providers simultaneously
  Future<SearchResultModel> searchMultipleProviders(
    List<String> providers,
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

  /// Load more from multiple providers
  Future<ItemsModel> loadMoreMultipleProviders(Map<String, String> pageTokens);
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
        runInShell: false,
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
      throw TuberException(
          'Failed to execute tuber process: ${e.message}\nJava path: ${_getJavaPath()}');
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
      print('Getting playlist info for URL: $url');
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

  SearchResultModel _mergeSearchResults(
  List<SearchResultModel> results,
  Map<String, String> pageTokens,
) {
  if (results.isEmpty) {
    throw TuberException('No results to merge');
  }

  if (results.length == 1) {
    return results.first;
  }

  // Collect all items from all results
  final allItems = <SummaryModel>[];
  for (var result in results) {
    allItems.addAll(result.items.items);
  }

  // Use the first result as base and merge items
  final firstResult = results.first;
  
  // Create a merged items model with combined page tokens
  final mergedItems = ItemsModel(
    items: allItems,
    nextPageToken: pageTokens.isNotEmpty 
        ? pageTokens.values.join('|') // Store all tokens separated by |
        : null,
  );

  return SearchResultModel(
    items: mergedItems,
    suggestion: firstResult.suggestion,
    isCorrected: firstResult.isCorrected,
  );
}

@override
Future<SearchResultModel> searchMultipleProviders(
  List<String> providers,
  String query, {
  List<String>? filters,
}) async {
  try {
    // Execute searches in parallel
    final searchFutures = providers.asMap().entries.map((entry) async {
      try {
        final result = await search(entry.value, query, filters: filters);
        return MapEntry(entry.value, result);
      } catch (e) {
        print('Warning: Failed to search ${entry.value}: $e');
        return null;
      }
    });

    final results = await Future.wait(searchFutures);

    // Filter out null results and separate into map
    final validResults = <String, SearchResultModel>{};
    final pageTokens = <String, String>{};

    for (var entry in results.whereType<MapEntry<String, SearchResultModel>>()) {
      validResults[entry.key] = entry.value;
      if (entry.value.items.nextPageToken != null) {
        pageTokens[entry.key] = entry.value.items.nextPageToken!;
      }
    }

    if (validResults.isEmpty) {
      throw TuberException('All provider searches failed');
    }

    // Merge all results with page tokens
    return _mergeSearchResults(validResults.values.toList(), pageTokens);
  } catch (e) {
    throw TuberException('Failed to search multiple providers: $e');
  }
}

@override
/// Load more from multiple providers
Future<ItemsModel> loadMoreMultipleProviders(
  Map<String, String> pageTokens,
) async {
  try {
    // Load more from each provider in parallel
    final loadFutures = pageTokens.entries.map((entry) async {
      try {
        return await loadMore(entry.value);
      } catch (e) {
        print('Warning: Failed to load more from ${entry.key}: $e');
        return null;
      }
    });

    final results = await Future.wait(loadFutures);
    final validResults = results.whereType<ItemsModel>().toList();

    if (validResults.isEmpty) {
      throw TuberException('Failed to load more from all providers');
    }

    // Merge all items
    final allItems = <SummaryModel>[];
    final newPageTokens = <String, String>{};

    for (var i = 0; i < validResults.length; i++) {
      final result = validResults[i];
      allItems.addAll(result.items);
      
      if (result.nextPageToken != null) {
        final provider = pageTokens.keys.elementAt(i);
        newPageTokens[provider] = result.nextPageToken!;
      }
    }

    return ItemsModel(
      items: allItems,
      nextPageToken: newPageTokens.isNotEmpty 
          ? newPageTokens.values.join('|')
          : null,
    );
  } catch (e) {
    throw TuberException('Failed to load more from multiple providers: $e');
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
