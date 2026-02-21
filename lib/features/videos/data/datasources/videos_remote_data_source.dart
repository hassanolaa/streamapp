import 'dart:convert';
import 'dart:io';

import 'package:streamapp/core/config/app_config.dart';
import 'package:streamapp/features/videos/data/models/info_model.dart';
import 'package:streamapp/features/videos/data/models/items_model.dart';
import 'package:streamapp/features/videos/data/models/search_result_model.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';

abstract class VideosRemoteDataSource {
  Future<List<String>> getSearchProviders();
  Future<List<String>> getFilters(String provider);
  Future<List<String>> getSortOptions(String provider);

  Future<SearchResultModel> search(
    String provider,
    String query, {
    List<String>? filters,
    String? sortCriteria,
  });

  Future<SearchResultModel> searchMultipleProviders(
    List<String> providers,
    String query, {
    List<String>? filters,
    String? sortCriteria,
  });

  Future<ItemsModel> loadMore(String pageToken);

  Future<StreamInfoModel> getStreamInfo(String url);
  Future<PlaylistInfoModel> getPlaylistInfo(String url);
  Future<ChannelInfoModel> getChannelInfo(String url);

  Future<ItemsModel> loadMoreMultipleProviders(
    Map<String, String> pageTokens,
  );

  Future<List<String>> getCatalogs();
  Future<List<PlaylistInfoModel>> getCatalog(String catalogProvider);
}

class VideosRemoteDataSourceImpl implements VideosRemoteDataSource {
  final String? tuberPath;

  VideosRemoteDataSourceImpl({this.tuberPath});

  /// Detect tuber in PATH if not provided
  Future<String> _getTuberPath() async {
    if (tuberPath != null && await File(tuberPath!).exists()) {
      return tuberPath!;
    }

    // Try to find tuber in PATH
    final result = await Process.run(
      'which',
      ['tuber'],
      runInShell: true,
    );

    if (result.exitCode != 0 || result.stdout.toString().trim().isEmpty) {
      throw TuberException(
          'Tuber binary not found in PATH. Please install or provide absolute path.');
    }

    return result.stdout.toString().trim();
  }

  /// Execute tuber binary
  Future<dynamic> _executeCommand(List<String> args) async {
    final path = await _getTuberPath();


    // Build environment with correct Java path
    final env = <String, String>{...Platform.environment};
    
    // Get JAVA_HOME from AppConfig
    final javaHome = AppConfig.getJavaHome();
    if (javaHome != null) {
      env['JAVA_HOME'] = javaHome;
      final javaBinPath = '$javaHome/bin';
      
      // Prepend Java bin directory to PATH to ensure correct Java version is used
      if (env.containsKey('PATH')) {
        env['PATH'] = '$javaBinPath:${env['PATH']}';
      } else {
        env['PATH'] = javaBinPath;
      }
      
    
    } else {
      print('⚠️ No JAVA_HOME configured, using system default');
    }

  final process = await Process.start(
      "tuber",
      args,
      runInShell: true,
     // environment: env,
    );

   // Read stdout
final stdoutString = await process.stdout.transform(utf8.decoder).join();

// Read stderr
final stderrString = await process.stderr.transform(utf8.decoder).join();

// Wait for exit
final exitCode = await process.exitCode;

if (exitCode != 0) {
  print('❌ Exit code: $exitCode');
  print('stderr: $stderrString');
  throw TuberException(stderrString);
}


    final output = process.stdout.toString().trim();

    if (output.isEmpty) {
      throw TuberException('Empty response from tuber');
    }

    try {
      return jsonDecode(stdoutString);
    } catch (e) {
      throw TuberException('Invalid JSON output from tuber: $e\nOutput: $output');
    }
  }

  @override
  Future<List<String>> getSearchProviders() async {
    final result = await _executeCommand(['search-providers']);
    return List<String>.from(result as List);
  }

  @override
  Future<List<String>> getFilters(String provider) async {
    final result = await _executeCommand(['filters', provider]);
    return List<String>.from(result as List);
  }

  @override
  Future<List<String>> getSortOptions(String provider) async {
    final result = await _executeCommand(['sort-options', provider]);
    return List<String>.from(result as List);
  }

  @override
  Future<SearchResultModel> search(
    String provider,
    String query, {
    List<String>? filters,
    String? sortCriteria,
  }) async {
    final args = ['search', provider, query];

    if (filters != null && filters.isNotEmpty) {
      args.add('--filters');
      args.add(filters.join(':'));
    }

    if (sortCriteria != null && sortCriteria.isNotEmpty) {
      args.add('--sort');
      args.add(sortCriteria);
    }

    final result = await _executeCommand(args);
    return SearchResultModel.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<ItemsModel> loadMore(String pageToken) async {
    final result = await _executeCommand(['more', pageToken]);
    return ItemsModel.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<StreamInfoModel> getStreamInfo(String url) async {
    final result = await _executeCommand(['stream', url]);
    return StreamInfoModel.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<PlaylistInfoModel> getPlaylistInfo(String url) async {
    final result = await _executeCommand(['playlist', url]);
    return PlaylistInfoModel.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<ChannelInfoModel> getChannelInfo(String url) async {
    final result = await _executeCommand(['channel', url]);
    return ChannelInfoModel.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<List<String>> getCatalogs() async {
    final result = await _executeCommand(['catalogs']);
    return List<String>.from(result as List);
  }

  @override
  Future<List<PlaylistInfoModel>> getCatalog(String catalogProvider) async {
    final result = await _executeCommand(['catalog', catalogProvider]);
    return (result as List)
        .map((json) =>
            PlaylistInfoModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SearchResultModel> searchMultipleProviders(
    List<String> providers,
    String query, {
    List<String>? filters,
    String? sortCriteria,
  }) async {
    final futures = providers.map((provider) async {
      try {
        final result = await search(
          provider,
          query,
          filters: filters,
          sortCriteria: sortCriteria,
        );
        return MapEntry(provider, result);
      } catch (_) {
        return null;
      }
    });

    final results = await Future.wait(futures);

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

    return _mergeSearchResults(validResults.values.toList(), pageTokens);
  }

  @override
  Future<ItemsModel> loadMoreMultipleProviders(
    Map<String, String> pageTokens,
  ) async {
    final futures = pageTokens.entries.map((entry) async {
      try {
        return await loadMore(entry.value);
      } catch (_) {
        return null;
      }
    });

    final results = await Future.wait(futures);
    final validResults = results.whereType<ItemsModel>().toList();

    if (validResults.isEmpty) {
      throw TuberException('Failed to load more from all providers');
    }

    final allItems = <SummaryModel>[];
    final detailedItems = <StreamInfoModel>[];
    final newPageTokens = <String, String>{};

    for (var i = 0; i < validResults.length; i++) {
      final result = validResults[i];
      allItems.addAll(result.items);
        detailedItems.addAll(result.detailedItems);

      if (result.nextPageToken != null) {
        final provider = pageTokens.keys.elementAt(i);
        newPageTokens[provider] = result.nextPageToken!;
      }
    }

    

    return ItemsModel(
      items: allItems,
      detailedItems: detailedItems,
      nextPageToken:
          newPageTokens.isNotEmpty ? newPageTokens.values.join('|') : null,
    );
  }

  SearchResultModel _mergeSearchResults(
    List<SearchResultModel> results,
    Map<String, String> pageTokens,
  ) {
    final allItems = <SummaryModel>[];
    final detailedItems = <StreamInfoModel>[];

    for (var result in results) {
      allItems.addAll(result.items.items);
      detailedItems.addAll(result.items.detailedItems);
    }

    final first = results.first;

    final mergedItems = ItemsModel(
      items: allItems,
      detailedItems: detailedItems,
      nextPageToken:
          pageTokens.isNotEmpty ? pageTokens.values.join('|') : null,
    );

    return SearchResultModel(
      items: mergedItems,
      suggestion: first.suggestion,
      isCorrected: first.isCorrected,
    );
  }
}

class TuberException implements Exception {
  final String message;
  TuberException(this.message);

  @override
  String toString() => 'TuberException: $message';
}
