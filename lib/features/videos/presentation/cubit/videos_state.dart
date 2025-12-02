import 'package:equatable/equatable.dart';
import 'package:streamapp/features/videos/data/models/info_model.dart';
import 'package:streamapp/features/videos/data/models/search_result_model.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';

abstract class VideosState extends Equatable {
  @override
  List<Object?> get props => [];
}

class VideosInitial extends VideosState {}

class VideosLoading extends VideosState {}

class VideosSearchSuccess extends VideosState {
  final SearchResultModel searchResult;
  final List<SummaryModel> allItems;
  final bool hasMore;

  VideosSearchSuccess({
    required this.searchResult,
    required this.allItems,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [searchResult, allItems, hasMore];
}

class VideosLoadingMore extends VideosState {
  final List<SummaryModel> currentItems;

  VideosLoadingMore(this.currentItems);

  @override
  List<Object?> get props => [currentItems];
}

class VideosStreamInfoSuccess extends VideosState {
  final StreamInfoModel streamInfo;

  VideosStreamInfoSuccess(this.streamInfo);

  @override
  List<Object?> get props => [streamInfo];
}

class VideosPlaylistInfoSuccess extends VideosState {
  final PlaylistInfoModel playlistInfo;

  VideosPlaylistInfoSuccess(this.playlistInfo);

  @override
  List<Object?> get props => [playlistInfo];
}

class VideosChannelInfoSuccess extends VideosState {
  final ChannelInfoModel channelInfo;

  VideosChannelInfoSuccess(this.channelInfo);

  @override
  List<Object?> get props => [channelInfo];
}

class VideosError extends VideosState {
  final String message;

  VideosError(this.message);

  @override
  List<Object?> get props => [message];
}

class VideosSearchHistoryLoaded extends VideosState {
  final List<String> history;

  VideosSearchHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}
