import 'package:equatable/equatable.dart';
import 'package:streamapp/features/series/data/models/series_model.dart';

abstract class SeriesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SeriesInitial extends SeriesState {}

class SeriesLoading extends SeriesState {}

class SeriesCatalogsLoaded extends SeriesState {
  final Map<String, List<SeriesModel>> catalogs;

  SeriesCatalogsLoaded(this.catalogs);

  @override
  List<Object?> get props => [catalogs];
}

class SeriesSearchSuccess extends SeriesState {
  final List<SeriesModel> series;
  final int currentPage;
  final bool hasMore;
  final int totalResults;

  SeriesSearchSuccess({
    required this.series,
    required this.currentPage,
    required this.hasMore,
    required this.totalResults,
  });

  @override
  List<Object?> get props => [series, currentPage, hasMore, totalResults];
}

class SeriesLoadingMore extends SeriesState {
  final List<SeriesModel> currentSeries;

  SeriesLoadingMore(this.currentSeries);

  @override
  List<Object?> get props => [currentSeries];
}

class SeriesError extends SeriesState {
  final String message;

  SeriesError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Series Details ──

class SeriesDetailLoaded extends SeriesState {
  final SeriesDetailModel detail;
  final SeriesCreditsModel credits;
  final List<SeriesVideoModel> videos;
  final List<SeriesModel> similarSeries;
  final List<SeriesModel> recommendedSeries;

  SeriesDetailLoaded({
    required this.detail,
    required this.credits,
    required this.videos,
    required this.similarSeries,
    required this.recommendedSeries,
  });

  @override
  List<Object?> get props =>
      [detail, credits, videos, similarSeries, recommendedSeries];
}

// ── Season Detail ──

class SeasonDetailLoaded extends SeriesState {
  final SeasonDetailModel season;

  SeasonDetailLoaded(this.season);

  @override
  List<Object?> get props => [season];
}

// ── Genres loaded (for filters) ──

class SeriesGenresLoaded extends SeriesState {
  final List<SeriesGenreModel> genres;

  SeriesGenresLoaded(this.genres);

  @override
  List<Object?> get props => [genres];
}
