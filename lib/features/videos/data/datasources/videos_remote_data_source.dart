import 'dart:convert';
import 'dart:io';
import 'package:streamapp/features/videos/data/models/info_model.dart';
import 'package:streamapp/features/videos/data/models/items_model.dart';
import 'package:streamapp/features/videos/data/models/search_result_model.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';

abstract class VideosRemoteDataSource {
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

  /// Get detailed stream/video information
  Future<StreamInfoModel> getStreamInfo(String url);

  /// Get playlist information
  Future<PlaylistInfoModel> getPlaylistInfo(String url);

  /// Get channel information
  Future<ChannelInfoModel> getChannelInfo(String url);

  /// Load more from multiple providers
  Future<ItemsModel> loadMoreMultipleProviders(Map<String, String> pageTokens);

  /// Get list of available catalog providers
  Future<List<String>> getCatalogs();

  /// Get catalog playlists for a specific provider
  Future<List<PlaylistInfoModel>> getCatalog(String catalogProvider);
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

      print('🔧 Executing command: $javaExec -jar $tuberJarPath ${args.join(" ")}');

      // Execute the Java command
      final result = await Process.run(
        javaExec,
        ['-jar', tuberJarPath, ...args],
        runInShell: false,
      );

      // Check for errors
      if (result.exitCode != 0) {
        final errorMessage = result.stderr?.toString() ?? 'Unknown error';
        print('❌ Command failed with exit code ${result.exitCode}');
        print('stderr: $errorMessage');
        throw TuberException(
          'Tuber command failed with exit code ${result.exitCode}: $errorMessage',
        );
      }

      // Parse JSON output
      final output = result.stdout.toString().trim();

      // 🔍 DEBUG: Print raw output
      print('📤 Raw stdout length: ${output.length}');
      print('📤 Raw stdout (first 500 chars): ${output.substring(0, output.length > 500 ? 500 : output.length)}');

      if (output.isEmpty) {
        throw TuberException('Empty response from tuber');
      }

      // Try to find JSON start
      final jsonStartIndex = output.indexOf('{');
      final jsonStartIndexArray = output.indexOf('[');

      if (jsonStartIndex == -1 && jsonStartIndexArray == -1) {
        print('❌ No JSON found in output!');
        print('Full output: $output');
        throw TuberException('No JSON found in response');
      }

      // Extract JSON only (skip any logging/debug output before JSON)
      final jsonStart = jsonStartIndex != -1 &&
              (jsonStartIndexArray == -1 || jsonStartIndex < jsonStartIndexArray)
          ? jsonStartIndex
          : jsonStartIndexArray;

      final cleanOutput = output.substring(jsonStart);
      print('✅ Clean JSON (first 200 chars): ${cleanOutput.substring(0, cleanOutput.length > 200 ? 200 : cleanOutput.length)}');

      return jsonDecode(cleanOutput);
    } on ProcessException catch (e) {
      throw TuberException(
          'Failed to execute tuber process: ${e.message}\nJava path: ${_getJavaPath()}');
    } on FormatException catch (e) {
      print('❌ JSON Parse Error: ${e.message}');
      throw TuberException('Invalid JSON response from tuber: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
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
  Future<List<String>> getFilters(String provider) async {
    try {
      final result = await _executeCommand(['filters', provider]);
      return List<String>.from(result as List);
    } catch (e) {
      throw TuberException('Failed to get filters for $provider: $e');
    }
  }

  @override
  Future<List<String>> getSortOptions(String provider) async {
    try {
      final result = await _executeCommand(['sort-options', provider]);
      return List<String>.from(result as List);
    } catch (e) {
      throw TuberException('Failed to get sort options for $provider: $e');
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
      final args = ['search', provider, query];

      // Add filters if provided
      // Format: --filters filter1:filter2:filter3
      if (filters != null && filters.isNotEmpty) {
        args.add('--filters');
        args.add(filters.join(':'));
      }

      // Add sort criteria if provided
      // Format: --sort riteria>
      if (sortCriteria != null && sortCriteria.isNotEmpty) {
        args.add('--sort');
        args.add(sortCriteria);
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

  @override
  Future<List<String>> getCatalogs() async {
    try {
      final result = await _executeCommand(['catalogs']);
      return List<String>.from(result as List);
    } catch (e) {
      throw TuberException('Failed to get catalogs: $e');
    }
  }

  @override
  Future<List<PlaylistInfoModel>> getCatalog(String catalogProvider) async {
    try {
      final result = await _executeCommand(['catalog', catalogProvider]);
      final playlists = (result as List)
          .map((json) =>
              PlaylistInfoModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return playlists;
    } catch (e) {
      throw TuberException('Failed to get catalog for $catalogProvider: $e');
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
    String? sortCriteria,
  }) async {
    try {
      // Execute searches in parallel
      final searchFutures = providers.asMap().entries.map((entry) async {
        try {
          final result = await search(
            entry.value,
            query,
            filters: filters,
            sortCriteria: sortCriteria,
          );
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

      for (var entry
          in results.whereType<MapEntry<String, SearchResultModel>>()) {
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
        nextPageToken:
            newPageTokens.isNotEmpty ? newPageTokens.values.join('|') : null,
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
