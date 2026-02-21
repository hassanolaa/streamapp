import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:streamapp/features/movies/data/models/movie_model.dart';

abstract class MoviesRemoteDataSource {
  Future<MoviesResponseModel> getTrending({int page = 1});
  Future<MoviesResponseModel> getPopular({int page = 1});
  Future<MoviesResponseModel> getTopRated({int page = 1});
  Future<MoviesResponseModel> getNowPlaying({int page = 1});
  Future<MoviesResponseModel> getUpcoming({int page = 1});
  Future<MoviesResponseModel> searchMovies(String query, {int page = 1});
  Future<List<GenreModel>> getGenres();
  Future<MoviesResponseModel> getMoviesByGenre(int genreId, {int page = 1});

  // New endpoints
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

class MoviesRemoteDataSourceImpl implements MoviesRemoteDataSource {
  final String apiKey;
  final http.Client client;
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  MoviesRemoteDataSourceImpl({
    required this.apiKey,
    http.Client? client,
  }) : client = client ?? http.Client();

  Future<Map<String, dynamic>> _get(String endpoint,
      {Map<String, String>? queryParams}) async {
    final params = {
      'api_key': apiKey,
      'language': 'en-US',
      ...?queryParams,
    };

    final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: params);

    final response = await client.get(uri);

    if (response.statusCode != 200) {
      throw MoviesApiException(
        'TMDB API error: ${response.statusCode} - ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<MoviesResponseModel> getTrending({int page = 1}) async {
    final json = await _get('/trending/movie/week', queryParams: {
      'page': page.toString(),
    });
    return MoviesResponseModel.fromJson(json);
  }

  @override
  Future<MoviesResponseModel> getPopular({int page = 1}) async {
    final json = await _get('/movie/popular', queryParams: {
      'page': page.toString(),
    });
    return MoviesResponseModel.fromJson(json);
  }

  @override
  Future<MoviesResponseModel> getTopRated({int page = 1}) async {
    final json = await _get('/movie/top_rated', queryParams: {
      'page': page.toString(),
    });
    return MoviesResponseModel.fromJson(json);
  }

  @override
  Future<MoviesResponseModel> getNowPlaying({int page = 1}) async {
    final json = await _get('/movie/now_playing', queryParams: {
      'page': page.toString(),
    });
    return MoviesResponseModel.fromJson(json);
  }

  @override
  Future<MoviesResponseModel> getUpcoming({int page = 1}) async {
    final json = await _get('/movie/upcoming', queryParams: {
      'page': page.toString(),
    });
    return MoviesResponseModel.fromJson(json);
  }

  @override
  Future<MoviesResponseModel> searchMovies(String query,
      {int page = 1}) async {
    final json = await _get('/search/movie', queryParams: {
      'query': query,
      'page': page.toString(),
      'include_adult': 'false',
    });
    return MoviesResponseModel.fromJson(json);
  }

  @override
  Future<List<GenreModel>> getGenres() async {
    final json = await _get('/genre/movie/list');
    final genres = (json['genres'] as List?)
            ?.map((e) => GenreModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return genres;
  }

  @override
  Future<MoviesResponseModel> getMoviesByGenre(int genreId,
      {int page = 1}) async {
    final json = await _get('/discover/movie', queryParams: {
      'with_genres': genreId.toString(),
      'sort_by': 'popularity.desc',
      'page': page.toString(),
    });
    return MoviesResponseModel.fromJson(json);
  }

  @override
  Future<MovieDetailModel> getMovieDetails(int movieId) async {
    final json = await _get('/movie/$movieId');
    return MovieDetailModel.fromJson(json);
  }

  @override
  Future<CreditsModel> getMovieCredits(int movieId) async {
    final json = await _get('/movie/$movieId/credits');
    return CreditsModel.fromJson(json);
  }

  @override
  Future<List<MovieVideoModel>> getMovieVideos(int movieId) async {
    final json = await _get('/movie/$movieId/videos');
    return (json['results'] as List?)
            ?.map((e) => MovieVideoModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
  }

  @override
  Future<MoviesResponseModel> getSimilarMovies(int movieId,
      {int page = 1}) async {
    final json = await _get('/movie/$movieId/similar', queryParams: {
      'page': page.toString(),
    });
    return MoviesResponseModel.fromJson(json);
  }

  @override
  Future<MoviesResponseModel> getRecommendedMovies(int movieId,
      {int page = 1}) async {
    final json = await _get('/movie/$movieId/recommendations', queryParams: {
      'page': page.toString(),
    });
    return MoviesResponseModel.fromJson(json);
  }

  @override
  Future<PersonDetailModel> getPersonDetails(int personId) async {
    final json = await _get('/person/$personId');
    return PersonDetailModel.fromJson(json);
  }

  @override
  Future<PersonCreditsModel> getPersonMovieCredits(int personId) async {
    final json = await _get('/person/$personId/movie_credits');
    return PersonCreditsModel.fromJson(json);
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
    final params = <String, String>{
      'page': page.toString(),
    };
    if (sortBy != null) params['sort_by'] = sortBy;
    if (withGenre != null) params['with_genres'] = withGenre.toString();
    if (withOriginalLanguage != null) {
      params['with_original_language'] = withOriginalLanguage;
    }
    if (primaryReleaseYear != null) {
      params['primary_release_year'] = primaryReleaseYear.toString();
    }
    if (voteAverageGte != null) {
      params['vote_average.gte'] = voteAverageGte.toString();
    }

    final json = await _get('/discover/movie', queryParams: params);
    return MoviesResponseModel.fromJson(json);
  }
}

class MoviesApiException implements Exception {
  final String message;
  MoviesApiException(this.message);

  @override
  String toString() => 'MoviesApiException: $message';
}
