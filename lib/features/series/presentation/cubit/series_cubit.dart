import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamapp/features/series/data/models/series_model.dart';
import 'package:streamapp/features/series/data/repositories/series_repository_impl.dart';
import 'package:streamapp/features/series/presentation/cubit/series_state.dart';

class SeriesCubit extends Cubit<SeriesState> {
  final SeriesRepository repository;

  List<SeriesModel> _searchResults = [];
  int _currentSearchPage = 1;
  int _totalSearchPages = 1;
  String _lastQuery = '';

  List<SeriesModel> _discoverResults = [];
  int _currentDiscoverPage = 1;
  int _totalDiscoverPages = 1;
  String? _lastSortBy;
  int? _lastGenreId;
  String? _lastLanguage;
  int? _lastYear;
  double? _lastMinRating;

  SeriesCubit({required this.repository}) : super(SeriesInitial());

  /// Load all series catalogs (Trending, Popular, Top Rated, Airing Today, On The Air)
  Future<void> loadCatalogs() async {
    try {
      emit(SeriesLoading());

      final results = await Future.wait([
        repository.getTrending(),
        repository.getPopular(),
        repository.getTopRated(),
        repository.getAiringToday(),
        repository.getOnTheAir(),
      ]);

      final catalogs = <String, List<SeriesModel>>{};

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
        catalogs['📺 Airing Today'] = results[3].results;
      }
      if (results[4].results.isNotEmpty) {
        catalogs['🗓️ On The Air'] = results[4].results;
      }

      emit(SeriesCatalogsLoaded(catalogs));
    } catch (e) {
      emit(SeriesError(e.toString()));
    }
  }

  /// Search TV series
  Future<void> searchSeries(String query) async {
    if (query.trim().isEmpty) return;

    try {
      emit(SeriesLoading());
      _lastQuery = query;
      _currentSearchPage = 1;

      final response = await repository.searchSeries(query, page: 1);
      _searchResults = response.results;
      _totalSearchPages = response.totalPages;

      emit(SeriesSearchSuccess(
        series: _searchResults,
        currentPage: response.page,
        hasMore: response.hasMore,
        totalResults: response.totalResults,
      ));
    } catch (e) {
      emit(SeriesError(e.toString()));
    }
  }

  /// Load more search results
  Future<void> loadMoreSearchResults() async {
    if (_currentSearchPage >= _totalSearchPages) return;

    try {
      emit(SeriesLoadingMore(_searchResults));
      _currentSearchPage++;
      final response =
          await repository.searchSeries(_lastQuery, page: _currentSearchPage);
      _searchResults = [..._searchResults, ...response.results];

      emit(SeriesSearchSuccess(
        series: _searchResults,
        currentPage: response.page,
        hasMore: response.hasMore,
        totalResults: response.totalResults,
      ));
    } catch (e) {
      emit(SeriesError(e.toString()));
    }
  }

  /// Discover series with filters
  Future<void> discoverSeries({
    String? sortBy,
    int? genreId,
    String? language,
    int? year,
    double? minRating,
  }) async {
    try {
      emit(SeriesLoading());
      _currentDiscoverPage = 1;
      _lastSortBy = sortBy;
      _lastGenreId = genreId;
      _lastLanguage = language;
      _lastYear = year;
      _lastMinRating = minRating;

      final response = await repository.discoverSeries(
        page: 1,
        sortBy: sortBy,
        withGenre: genreId,
        withOriginalLanguage: language,
        firstAirDateYear: year,
        voteAverageGte: minRating,
      );

      _discoverResults = response.results;
      _totalDiscoverPages = response.totalPages;

      emit(SeriesSearchSuccess(
        series: _discoverResults,
        currentPage: response.page,
        hasMore: response.hasMore,
        totalResults: response.totalResults,
      ));
    } catch (e) {
      emit(SeriesError(e.toString()));
    }
  }

  /// Load more discover results
  Future<void> loadMoreDiscoverResults() async {
    if (_currentDiscoverPage >= _totalDiscoverPages) return;

    try {
      emit(SeriesLoadingMore(_discoverResults));
      _currentDiscoverPage++;

      final response = await repository.discoverSeries(
        page: _currentDiscoverPage,
        sortBy: _lastSortBy,
        withGenre: _lastGenreId,
        withOriginalLanguage: _lastLanguage,
        firstAirDateYear: _lastYear,
        voteAverageGte: _lastMinRating,
      );

      _discoverResults = [..._discoverResults, ...response.results];

      emit(SeriesSearchSuccess(
        series: _discoverResults,
        currentPage: response.page,
        hasMore: response.hasMore,
        totalResults: response.totalResults,
      ));
    } catch (e) {
      emit(SeriesError(e.toString()));
    }
  }

  /// Load full series details with credits, videos, similar & recommended
  Future<void> loadSeriesDetails(int seriesId) async {
    try {
      emit(SeriesLoading());

      final results = await Future.wait([
        repository.getSeriesDetails(seriesId),
        repository.getSeriesCredits(seriesId),
        repository.getSeriesVideos(seriesId),
        repository.getSimilarSeries(seriesId),
        repository.getRecommendedSeries(seriesId),
      ]);

      emit(SeriesDetailLoaded(
        detail: results[0] as SeriesDetailModel,
        credits: results[1] as SeriesCreditsModel,
        videos: results[2] as List<SeriesVideoModel>,
        similarSeries: (results[3] as SeriesResponseModel).results,
        recommendedSeries: (results[4] as SeriesResponseModel).results,
      ));
    } catch (e) {
      emit(SeriesError(e.toString()));
    }
  }

  /// Load season details
  Future<void> loadSeasonDetails(int seriesId, int seasonNumber) async {
    try {
      emit(SeriesLoading());
      final season = await repository.getSeasonDetails(seriesId, seasonNumber);
      emit(SeasonDetailLoaded(season));
    } catch (e) {
      emit(SeriesError(e.toString()));
    }
  }

  /// Load genres for filter UI
  Future<void> loadGenres() async {
    try {
      final genres = await repository.getGenres();
      emit(SeriesGenresLoaded(genres));
    } catch (e) {
      emit(SeriesError(e.toString()));
    }
  }
}
