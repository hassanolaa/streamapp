import 'package:streamapp/features/movies/data/datasources/movies_remote_data_source.dart';
import 'package:streamapp/features/movies/data/models/movie_model.dart';

abstract class MoviesRepository {
  Future<MoviesResponseModel> getTrending({int page = 1});
  Future<MoviesResponseModel> getPopular({int page = 1});
  Future<MoviesResponseModel> getTopRated({int page = 1});
  Future<MoviesResponseModel> getNowPlaying({int page = 1});
  Future<MoviesResponseModel> getUpcoming({int page = 1});
  Future<MoviesResponseModel> searchMovies(String query, {int page = 1});
  Future<List<GenreModel>> getGenres();
  Future<MoviesResponseModel> getMoviesByGenre(int genreId, {int page = 1});

  // New
  Future<MovieDetailModel> getMovieDetails(int movieId);
  Future<CreditsModel> getMovieCredits(int movieId);
  Future<List<MovieVideoModel>> getMovieVideos(int movieId);
  Future<MoviesResponseModel> getSimilarMovies(int movieId, {int page = 1});
  Future<MoviesResponseModel> getRecommendedMovies(int movieId, {int page = 1});
  Future<PersonDetailModel> getPersonDetails(int personId);
  Future<PersonCreditsModel> getPersonMovieCredits(int personId);
  Future<MoviesResponseModel> discoverMovies({
    int page = 1,
    String? sortBy,
    int? withGenre,
    String? withOriginalLanguage,
    int? primaryReleaseYear,
    double? voteAverageGte,
  });
}

class MoviesRepositoryImpl implements MoviesRepository {
  final MoviesRemoteDataSource remoteDataSource;

  MoviesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<MoviesResponseModel> getTrending({int page = 1}) async {
    try {
      return await remoteDataSource.getTrending(page: page);
    } catch (e) {
      throw MoviesRepositoryException('Failed to get trending movies: $e');
    }
  }

  @override
  Future<MoviesResponseModel> getPopular({int page = 1}) async {
    try {
      return await remoteDataSource.getPopular(page: page);
    } catch (e) {
      throw MoviesRepositoryException('Failed to get popular movies: $e');
    }
  }

  @override
  Future<MoviesResponseModel> getTopRated({int page = 1}) async {
    try {
      return await remoteDataSource.getTopRated(page: page);
    } catch (e) {
      throw MoviesRepositoryException('Failed to get top rated movies: $e');
    }
  }

  @override
  Future<MoviesResponseModel> getNowPlaying({int page = 1}) async {
    try {
      return await remoteDataSource.getNowPlaying(page: page);
    } catch (e) {
      throw MoviesRepositoryException('Failed to get now playing movies: $e');
    }
  }

  @override
  Future<MoviesResponseModel> getUpcoming({int page = 1}) async {
    try {
      return await remoteDataSource.getUpcoming(page: page);
    } catch (e) {
      throw MoviesRepositoryException('Failed to get upcoming movies: $e');
    }
  }

  @override
  Future<MoviesResponseModel> searchMovies(String query,
      {int page = 1}) async {
    try {
      return await remoteDataSource.searchMovies(query, page: page);
    } catch (e) {
      throw MoviesRepositoryException('Failed to search movies: $e');
    }
  }

  @override
  Future<List<GenreModel>> getGenres() async {
    try {
      return await remoteDataSource.getGenres();
    } catch (e) {
      throw MoviesRepositoryException('Failed to get genres: $e');
    }
  }

  @override
  Future<MoviesResponseModel> getMoviesByGenre(int genreId,
      {int page = 1}) async {
    try {
      return await remoteDataSource.getMoviesByGenre(genreId, page: page);
    } catch (e) {
      throw MoviesRepositoryException('Failed to get movies by genre: $e');
    }
  }

  @override
  Future<MovieDetailModel> getMovieDetails(int movieId) async {
    try {
      return await remoteDataSource.getMovieDetails(movieId);
    } catch (e) {
      throw MoviesRepositoryException('Failed to get movie details: $e');
    }
  }

  @override
  Future<CreditsModel> getMovieCredits(int movieId) async {
    try {
      return await remoteDataSource.getMovieCredits(movieId);
    } catch (e) {
      throw MoviesRepositoryException('Failed to get movie credits: $e');
    }
  }

  @override
  Future<List<MovieVideoModel>> getMovieVideos(int movieId) async {
    try {
      return await remoteDataSource.getMovieVideos(movieId);
    } catch (e) {
      throw MoviesRepositoryException('Failed to get movie videos: $e');
    }
  }

  @override
  Future<MoviesResponseModel> getSimilarMovies(int movieId,
      {int page = 1}) async {
    try {
      return await remoteDataSource.getSimilarMovies(movieId, page: page);
    } catch (e) {
      throw MoviesRepositoryException('Failed to get similar movies: $e');
    }
  }

  @override
  Future<MoviesResponseModel> getRecommendedMovies(int movieId,
      {int page = 1}) async {
    try {
      return await remoteDataSource.getRecommendedMovies(movieId, page: page);
    } catch (e) {
      throw MoviesRepositoryException('Failed to get recommended movies: $e');
    }
  }

  @override
  Future<PersonDetailModel> getPersonDetails(int personId) async {
    try {
      return await remoteDataSource.getPersonDetails(personId);
    } catch (e) {
      throw MoviesRepositoryException('Failed to get person details: $e');
    }
  }

  @override
  Future<PersonCreditsModel> getPersonMovieCredits(int personId) async {
    try {
      return await remoteDataSource.getPersonMovieCredits(personId);
    } catch (e) {
      throw MoviesRepositoryException('Failed to get person credits: $e');
    }
  }

  @override
  Future<MoviesResponseModel> discoverMovies({
    int page = 1,
    String? sortBy,
    int? withGenre,
    String? withOriginalLanguage,
    int? primaryReleaseYear,
    double? voteAverageGte,
  }) async {
    try {
      return await remoteDataSource.discoverMovies(
        page: page,
        sortBy: sortBy,
        withGenre: withGenre,
        withOriginalLanguage: withOriginalLanguage,
        primaryReleaseYear: primaryReleaseYear,
        voteAverageGte: voteAverageGte,
      );
    } catch (e) {
      throw MoviesRepositoryException('Failed to discover movies: $e');
    }
  }
}

class MoviesRepositoryException implements Exception {
  final String message;
  MoviesRepositoryException(this.message);

  @override
  String toString() => 'MoviesRepositoryException: $message';
}
