import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamapp/features/videos/data/models/search_result_model.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';
import 'package:streamapp/features/videos/data/repositories/videos_repository_impl.dart';
import 'package:streamapp/features/videos/presentation/cubit/videos_state.dart';

class VideosCubit extends Cubit<VideosState> {
  final VideosRepository repository;
  String? _currentPageToken;
  List<SummaryModel> _allItems = [];
  String _lastProvider = 'YouTube';
  String _lastQuery = '';

  VideosCubit({required this.repository}) : super(VideosInitial());

  Future<void> searchVideos(String provider, String query, {List<String>? filters}) async {
    try {
      emit(VideosLoading());
      
      _lastProvider = provider;
      _lastQuery = query;

      final result = await repository.search(provider, query, filters: filters);
      
      _allItems = result.items.getSummaries();
      _currentPageToken = result.items.nextPageToken;

      emit(VideosSearchSuccess(
        searchResult: result,
        allItems: _allItems,
        hasMore: _currentPageToken != null,
      ));
    } catch (e) {
      emit(VideosError(e.toString()));
    }
  }

  Future<void> loadMoreVideos() async {
    if (_currentPageToken == null) return;

    try {
      emit(VideosLoadingMore(_allItems));

      final moreItems = await repository.loadMore(_currentPageToken!);
      
      _allItems.addAll(moreItems.getSummaries());
      _currentPageToken = moreItems.nextPageToken;

      emit(VideosSearchSuccess(
        searchResult: null as SearchResultModel, // Keep previous search result
        allItems: _allItems,
        hasMore: _currentPageToken != null,
      ));
    } catch (e) {
      emit(VideosError(e.toString()));
    }
  }

  Future<void> getStreamInfo(String url) async {
    try {
      emit(VideosLoading());
      final info = await repository.getStreamInfo(url);
      print('Fetched stream info: $info');
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
}
