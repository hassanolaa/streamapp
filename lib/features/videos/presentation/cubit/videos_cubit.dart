import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamapp/features/videos/data/models/info_model.dart';
import 'package:streamapp/features/videos/data/models/search_result_model.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';
import 'package:streamapp/features/videos/data/repositories/videos_repository_impl.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_state.dart';

class VideosCubit extends Cubit<VideosState> {
  final VideosRepository repository;

  Map<String, String>? _currentPageTokens;
  List<SummaryModel> _allItems = [];
  SearchResultModel? _lastSearchResult;
  String _lastQuery = '';
  final List<String> _searchProviders = ['youtube', 'soundcloud'];

  VideosCubit({required this.repository}) : super(VideosInitial());

  /// Search across multiple providers (YouTube + SoundCloud)
  Future<void> searchVideos(
    String query, {
    List<String>? filters,
    String? sortCriteria,
  }) async {
    try {
      emit(VideosLoading());
      _lastQuery = query;

      final result = await repository.searchMultipleProviders(
        _searchProviders,
        query,
        filters: filters,
        sortCriteria: sortCriteria,
      );

      _lastSearchResult = result;
      _allItems = result.items.getSummaries();

      // Parse page tokens from result
      _currentPageTokens = _parsePageTokens(result.items.nextPageToken);

      emit(VideosSearchSuccess(
        searchResult: result,
        allItems: _allItems,
        hasMore: _currentPageTokens != null && _currentPageTokens!.isNotEmpty,
        pageTokens: _currentPageTokens,
      ));
    } catch (e) {
      emit(VideosError(e.toString()));
    }
  }

  Future<void> loadMoreVideos() async {
    if (_currentPageTokens == null || _currentPageTokens!.isEmpty) return;

    try {
      emit(VideosLoadingMore(_allItems));

      final moreItems =
          await repository.loadMoreMultipleProviders(_currentPageTokens!);
      _allItems.addAll(moreItems.getSummaries());

      // Update page tokens
      _currentPageTokens = _parsePageTokens(moreItems.nextPageToken);

      emit(VideosSearchSuccess(
        searchResult: _lastSearchResult,
        allItems: _allItems,
        hasMore: _currentPageTokens != null && _currentPageTokens!.isNotEmpty,
        pageTokens: _currentPageTokens,
      ));
    } catch (e) {
      emit(VideosError(e.toString()));
    }
  }

  /// Parse page tokens from string format "token1|token2"
  Map<String, String>? _parsePageTokens(String? tokenString) {
    if (tokenString == null || tokenString.isEmpty) return null;

    final tokens = tokenString.split('|');
    if (tokens.length != _searchProviders.length) return null;

    final pageTokens = <String, String>{};
    for (var i = 0; i < _searchProviders.length; i++) {
      if (tokens[i].isNotEmpty) {
        pageTokens[_searchProviders[i]] = tokens[i];
      }
    }

    return pageTokens.isNotEmpty ? pageTokens : null;
  }

  Future<void> getStreamInfo(String url) async {
    try {
      emit(VideosLoading());
      final info = await repository.getStreamInfo(url);
      print('Fetched stream info: $info');
      print('Available streams: ${info}');
      emit(VideosStreamInfoSuccess(info));
    } catch (e) {
      emit(VideosError(e.toString()));
    }
  }

  Future<void> getPlaylistInfo(String url) async {
    try {
      emit(VideosLoading());
      final info = await repository.getPlaylistInfo(url);
      emit(VideosPlaylistInfoSuccess(info));
    } catch (e) {
      emit(VideosError(e.toString()));
    }
  }

  Future<void> getChannelInfo(String url) async {
    try {
      emit(VideosLoading());
      final info = await repository.getChannelInfo(url);
      emit(VideosChannelInfoSuccess(info));
    } catch (e) {
      emit(VideosError(e.toString()));
    }
  }

  Future<void> loadSearchHistory() async {
    try {
      final history = await repository.getSearchHistory();
      emit(VideosSearchHistoryLoaded(history));
    } catch (e) {
      emit(VideosError(e.toString()));
    }
  }

  Future<void> clearSearchHistory() async {
    try {
      await repository.clearSearchHistory();
      emit(VideosSearchHistoryLoaded([]));
    } catch (e) {
      emit(VideosError(e.toString()));
    }
  }

  Map<String, List<PlaylistInfoModel>> _allCatalogs = {};

/// Load all available catalogs
Future<void> loadCatalogs() async {
  try {
    emit(VideosLoading());

    // Get available catalog providers
    final catalogProviders = await repository.getCatalogs();
    
    final catalogs = <String, List<PlaylistInfoModel>>{};

    // Load catalogs from each provider
    for (final provider in catalogProviders) {
      try {
        final catalogContent = await repository.getCatalog(provider);
        if (catalogContent.isNotEmpty) {
          catalogs[provider] = catalogContent;
        }
      } catch (e) {
        print('Warning: Failed to load catalog from $provider: $e');
      }
    }

    _allCatalogs = catalogs;
    emit(VideosCatalogsLoaded(catalogs));
  } catch (e) {
    emit(VideosError(e.toString()));
  }
}
}
