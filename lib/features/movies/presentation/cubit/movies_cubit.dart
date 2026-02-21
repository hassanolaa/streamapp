import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamapp/features/movies/data/models/movie_model.dart';
import 'package:streamapp/features/movies/data/repositories/movies_repository_impl.dart';
import 'package:streamapp/features/movies/presentation/cubit/movies_state.dart';

class MoviesCubit extends Cubit<MoviesState> {
  final MoviesRepository repository;

  List<MovieModel> _searchResults = [];
  int _currentSearchPage = 1;
  int _totalSearchPages = 1;
  String _lastQuery = '';

  // Discover state
  List<MovieModel> _discoverResults = [];
  int _currentDiscoverPage = 1;
  int _totalDiscoverPages = 1;
  String? _lastSortBy;
  int? _lastGenreId;
  String? _lastLanguage;
  int? _lastYear;
  double? _lastMinRating;

  MoviesCubit({required this.repository}) : super(MoviesInitial());

  /// Load all movie catalogs (Trending, Popular, Top Rated, Now Playing, Upcoming)
  Future<void> loadCatalogs() async {
    try {
      emit(MoviesLoading());

      final results = await Future.wait([
        repository.getTrending(),
        repository.getPopular(),
        repository.getTopRated(),
        repository.getNowPlaying(),
        repository.getUpcoming(),
      ]);

      final catalogs = <String, List<MovieModel>>{};

      if (results[0].results.isNotEmpty) {
        catalogs['🔥 Trending This Week'] = results[0].results;
      }
      if (results[1].results.isNotEmpty) {
        catalogs['⭐ Popular'] = results[1].results;
      }
      if (results[2].results.isNotEmpty) {
        catalogs['🏆 Top Rated'] = results[2].results;
      }
      if (results[3].results.isNotEmpty) {
        catalogs['🎬 Now Playing'] = results[3].results;
      }
      if (results[4].results.isNotEmpty) {
        catalogs['📅 Upcoming'] = results[4].results;
      }

      emit(MoviesCatalogsLoaded(catalogs));
    } catch (e) {
      emit(MoviesError(e.toString()));
    }
  }

  /// Search movies
  Future<void> searchMovies(String query) async {
    if (query.trim().isEmpty) return;

    try {
      emit(MoviesLoading());
      _lastQuery = query;
      _currentSearchPage = 1;

      final response = await repository.searchMovies(query, page: 1);

      _searchResults = response.results;
      _totalSearchPages = response.totalPages;

      emit(MoviesSearchSuccess(
        movies: _searchResults,
        currentPage: response.page,
        hasMore: response.hasMore,
        totalResults: response.totalResults,
      ));
    } catch (e) {
      emit(MoviesError(e.toString()));
    }
  }

  /// Load more search results
  Future<void> loadMoreSearchResults() async {
    if (_currentSearchPage >= _totalSearchPages) return;

    try {
      emit(MoviesLoadingMore(_searchResults));

      _currentSearchPage++;
      final response = await repository.searchMovies(
        _lastQuery,
        page: _currentSearchPage,
      );

      _searchResults = [..._searchResults, ...response.results];

      emit(MoviesSearchSuccess(
        movies: _searchResults,
        currentPage: response.page,
        hasMore: response.hasMore,
        totalResults: response.totalResults,
      ));
    } catch (e) {
      emit(MoviesError(e.toString()));
    }
  }

  /// Discover movies with filters and sort
  Future<void> discoverMovies({
    String? sortBy,
    int? genreId,
    String? language,
    int? year,
    double? minRating,
  }) async {
    try {
      emit(MoviesLoading());
      _currentDiscoverPage = 1;
      _lastSortBy = sortBy;
      _lastGenreId = genreId;
      _lastLanguage = language;
      _lastYear = year;
      _lastMinRating = minRating;

      final response = await repository.discoverMovies(
        page: 1,
        sortBy: sortBy,
        withGenre: genreId,
        withOriginalLanguage: language,
        primaryReleaseYear: year,
        voteAverageGte: minRating,
      );

      _discoverResults = response.results;
      _totalDiscoverPages = response.totalPages;

      emit(MoviesSearchSuccess(
        movies: _discoverResults,
        currentPage: response.page,
        hasMore: response.hasMore,
        totalResults: response.totalResults,
      ));
    } catch (e) {
      emit(MoviesError(e.toString()));
    }
  }

  /// Load more discover results
  Future<void> loadMoreDiscoverResults() async {
    if (_currentDiscoverPage >= _totalDiscoverPages) return;

    try {
      emit(MoviesLoadingMore(_discoverResults));

      _currentDiscoverPage++;
      final response = await repository.discoverMovies(
        page: _currentDiscoverPage,
        sortBy: _lastSortBy,
        withGenre: _lastGenreId,
        withOriginalLanguage: _lastLanguage,
        primaryReleaseYear: _lastYear,
        voteAverageGte: _lastMinRating,
      );

      _discoverResults = [..._discoverResults, ...response.results];

      emit(MoviesSearchSuccess(
        movies: _discoverResults,
        currentPage: response.page,
        hasMore: response.hasMore,
        totalResults: response.totalResults,
      ));
    } catch (e) {
      emit(MoviesError(e.toString()));
    }
  }

  /// Load full movie details with credits, videos, similar & recommended
  Future<void> loadMovieDetails(int movieId) async {
    try {
      emit(MoviesLoading());

      final results = await Future.wait([
        repository.getMovieDetails(movieId),
        repository.getMovieCredits(movieId),
        repository.getMovieVideos(movieId),
        repository.getSimilarMovies(movieId),
        repository.getRecommendedMovies(movieId),
      ]);

      emit(MovieDetailLoaded(
        detail: results[0] as MovieDetailModel,
        credits: results[1] as CreditsModel,
        videos: results[2] as List<MovieVideoModel>,
        similarMovies: (results[3] as MoviesResponseModel).results,
        recommendedMovies: (results[4] as MoviesResponseModel).results,
      ));
    } catch (e) {
      emit(MoviesError(e.toString()));
    }
  }

  /// Load person details with their movie credits
  Future<void> loadPersonDetails(int personId) async {
    try {
      emit(MoviesLoading());

      final results = await Future.wait([
        repository.getPersonDetails(personId),
        repository.getPersonMovieCredits(personId),
      ]);

      emit(PersonDetailLoaded(
        person: results[0] as PersonDetailModel,
        credits: results[1] as PersonCreditsModel,
      ));
    } catch (e) {
      emit(MoviesError(e.toString()));
    }
  }

  /// Load genres for filter UI
  Future<void> loadGenres() async {
    try {
      final genres = await repository.getGenres();
      emit(MoviesGenresLoaded(genres));
    } catch (e) {
      emit(MoviesError(e.toString()));
    }
  }
}
