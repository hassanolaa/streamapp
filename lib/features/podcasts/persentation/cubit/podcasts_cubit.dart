import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamapp/features/podcasts/persentation/cubit/podcasts_state.dart';
import 'package:streamapp/features/videos/data/models/info_model.dart';
import 'package:streamapp/features/videos/data/models/search_result_model.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';
import 'package:streamapp/features/videos/data/repositories/videos_repository_impl.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_state.dart';

class PodcastCubit extends Cubit<PodcastState> {
  final VideosRepository repository;

  Map<String, String>? _currentPageTokens;
  List<SummaryModel> _allItems = [];
  SearchResultModel? _lastSearchResult;
  String _lastQuery = '';
  final List<String> _searchProviders = ['podcastindex'];

  PodcastCubit({required this.repository}) : super(PodcastInitial());

  /// Search across multiple providers (YouTube + SoundCloud)
  Future<void> searchPodcast(
    String query, {
    List<String>? filters,
    String? sortCriteria,
  }) async {
    try {
      emit(PodcastLoading());
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

      emit(PodcastSearchSuccess(
        searchResult: result,
        allItems: _allItems,
        hasMore: _currentPageTokens != null && _currentPageTokens!.isNotEmpty,
        pageTokens: _currentPageTokens,
      ));
    } catch (e) {
      emit(PodcastError(e.toString()));
    }
  }

  Future<void> loadMorePodcast() async {
    if (_currentPageTokens == null || _currentPageTokens!.isEmpty) return;

    try {
      emit(PodcastLoadingMore(_allItems));

      final moreItems =
          await repository.loadMoreMultipleProviders(_currentPageTokens!);
      _allItems.addAll(moreItems.getSummaries());

      // Update page tokens
      _currentPageTokens = _parsePageTokens(moreItems.nextPageToken);

      emit(PodcastSearchSuccess(
        searchResult: _lastSearchResult,
        allItems: _allItems,
        hasMore: _currentPageTokens != null && _currentPageTokens!.isNotEmpty,
        pageTokens: _currentPageTokens,
      ));
    } catch (e) {
      emit(PodcastError(e.toString()));
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
      emit(PodcastLoading());
      final info = await repository.getStreamInfo(url);
      print('Fetched stream info: $info');
      print('Available streams: ${info}');
      emit(PodcastStreamInfoSuccess(info));
    } catch (e) {
      emit(PodcastError(e.toString()));
    }
  }

  Future<void> getPlaylistInfo(String url) async {
    try {
      emit(PodcastLoading());
      final info = await repository.getPlaylistInfo(url);
      emit(PodcastPlaylistInfoSuccess(info));
    } catch (e) {
      emit(PodcastError(e.toString()));
    }
  }

  Future<void> getChannelInfo(String url) async {
    try {
      emit(PodcastLoading());
      final info = await repository.getChannelInfo(url);
      emit(PodcastChannelInfoSuccess(info));
    } catch (e) {
      emit(PodcastError(e.toString()));
    }
  }

  Future<void> loadSearchHistory() async {
    try {
      final history = await repository.getSearchHistory();
      emit(PodcastSearchHistoryLoaded(history));
    } catch (e) {
      emit(PodcastError(e.toString()));
    }
  }

  Future<void> clearSearchHistory() async {
    try {
      await repository.clearSearchHistory();
      emit(PodcastSearchHistoryLoaded([]));
    } catch (e) {
      emit(PodcastError(e.toString()));
    }
  }

  Map<String, List<PlaylistInfoModel>> _allCatalogs = {};

/// Load all available catalogs
Future<void> loadCatalogs() async {
  try {
    emit(PodcastLoading());

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
    emit(PodcastCatalogsLoaded(catalogs));
  } catch (e) {
    emit(PodcastError(e.toString()));
  }
}
}
