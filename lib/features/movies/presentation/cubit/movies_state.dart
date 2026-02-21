import 'package:equatable/equatable.dart';
import 'package:streamapp/features/movies/data/models/movie_model.dart';

abstract class MoviesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MoviesInitial extends MoviesState {}

class MoviesLoading extends MoviesState {}

class MoviesCatalogsLoaded extends MoviesState {
  final Map<String, List<MovieModel>> catalogs;

  MoviesCatalogsLoaded(this.catalogs);

  @override
  List<Object?> get props => [catalogs];
}

class MoviesSearchSuccess extends MoviesState {
  final List<MovieModel> movies;
  final int currentPage;
  final bool hasMore;
  final int totalResults;

  MoviesSearchSuccess({
    required this.movies,
    required this.currentPage,
    required this.hasMore,
    required this.totalResults,
  });

  @override
  List<Object?> get props => [movies, currentPage, hasMore, totalResults];
}

class MoviesLoadingMore extends MoviesState {
  final List<MovieModel> currentMovies;

  MoviesLoadingMore(this.currentMovies);

  @override
  List<Object?> get props => [currentMovies];
}

class MoviesError extends MoviesState {
  final String message;

  MoviesError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Movie Details ──

class MovieDetailLoaded extends MoviesState {
  final MovieDetailModel detail;
  final CreditsModel credits;
  final List<MovieVideoModel> videos;
  final List<MovieModel> similarMovies;
  final List<MovieModel> recommendedMovies;

  MovieDetailLoaded({
    required this.detail,
    required this.credits,
    required this.videos,
    required this.similarMovies,
    required this.recommendedMovies,
  });

  @override
  List<Object?> get props =>
      [detail, credits, videos, similarMovies, recommendedMovies];
}

// ── Person Details ──

class PersonDetailLoaded extends MoviesState {
  final PersonDetailModel person;
  final PersonCreditsModel credits;

  PersonDetailLoaded({
    required this.person,
    required this.credits,
  });

  @override
  List<Object?> get props => [person, credits];
}

// ── Genres loaded (for filters) ──

class MoviesGenresLoaded extends MoviesState {
  final List<GenreModel> genres;

  MoviesGenresLoaded(this.genres);

  @override
  List<Object?> get props => [genres];
}
