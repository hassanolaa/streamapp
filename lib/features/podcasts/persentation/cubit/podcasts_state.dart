import 'package:equatable/equatable.dart';
import 'package:streamapp/features/videos/data/models/info_model.dart';
import 'package:streamapp/features/videos/data/models/search_result_model.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';

abstract class PodcastState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PodcastInitial extends PodcastState {}

class PodcastLoading extends PodcastState {}

class PodcastSearchSuccess extends PodcastState {
  final SearchResultModel? searchResult;
  final List<SummaryModel> allItems;
  final bool hasMore;
  final Map<String, String>? pageTokens; // Track tokens per provider

  PodcastSearchSuccess({
    this.searchResult,
    required this.allItems,
    this.hasMore = false,
    this.pageTokens,
  });

  @override
  List<Object?> get props => [searchResult, allItems, hasMore, pageTokens];
}

class PodcastLoadingMore extends PodcastState {
  final List<SummaryModel> currentItems;

  PodcastLoadingMore(this.currentItems);

  @override
  List<Object?> get props => [currentItems];
}

class PodcastStreamInfoSuccess extends PodcastState {
  final StreamInfoModel streamInfo;

  PodcastStreamInfoSuccess(this.streamInfo);

  @override
  List<Object?> get props => [streamInfo];
}

class PodcastPlaylistInfoSuccess extends PodcastState {
  final PlaylistInfoModel playlistInfo;

  PodcastPlaylistInfoSuccess(this.playlistInfo);

  @override
  List<Object?> get props => [playlistInfo];
}

class PodcastChannelInfoSuccess extends PodcastState {
  final ChannelInfoModel channelInfo;

  PodcastChannelInfoSuccess(this.channelInfo);

  @override
  List<Object?> get props => [channelInfo];
}

class PodcastError extends PodcastState {
  final String message;

  PodcastError(this.message);

  @override
  List<Object?> get props => [message];
}

class PodcastSearchHistoryLoaded extends PodcastState {
  final List<String> history;

  PodcastSearchHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}


class PodcastCatalogsLoaded extends PodcastState {
  final Map<String, List<PlaylistInfoModel>> catalogs;

  PodcastCatalogsLoaded(this.catalogs);

  @override
  List<Object?> get props => [catalogs];
}