import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:streamapp/features/series/data/models/series_model.dart';

abstract class SeriesRemoteDataSource {
  Future<SeriesResponseModel> getTrending({int page = 1});
  Future<SeriesResponseModel> getPopular({int page = 1});
  Future<SeriesResponseModel> getTopRated({int page = 1});
  Future<SeriesResponseModel> getAiringToday({int page = 1});
  Future<SeriesResponseModel> getOnTheAir({int page = 1});
  Future<SeriesResponseModel> searchSeries(String query, {int page = 1});
  Future<List<SeriesGenreModel>> getGenres();
  Future<SeriesResponseModel> getSeriesByGenre(int genreId, {int page = 1});

  // Detail endpoints
  Future<SeriesDetailModel> getSeriesDetails(int seriesId);
  Future<SeriesCreditsModel> getSeriesCredits(int seriesId);
  Future<List<SeriesVideoModel>> getSeriesVideos(int seriesId);
  Future<SeriesResponseModel> getSimilarSeries(int seriesId, {int page = 1});
  Future<SeriesResponseModel> getRecommendedSeries(int seriesId, {int page = 1});
  Future<SeasonDetailModel> getSeasonDetails(int seriesId, int seasonNumber);
  Future<SeriesResponseModel> discoverSeries({
    int page = 1,
    String? sortBy,
    int? withGenre,
    String? withOriginalLanguage,
    int? firstAirDateYear,
    double? voteAverageGte,
  });
}

class SeriesRemoteDataSourceImpl implements SeriesRemoteDataSource {
  final String apiKey;
  final http.Client client;
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  SeriesRemoteDataSourceImpl({
    required this.apiKey,
    http.Client? client,
  }) : client = client ?? http.Client();

  Future<Map<String, dynamic>> _get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final params = {
      'api_key': apiKey,
      'language': 'en-US',
      ...?queryParams,
    };
    final uri =
        Uri.parse('$_baseUrl$endpoint').replace(queryParameters: params);
    final response = await client.get(uri);
    if (response.statusCode != 200) {
      throw SeriesApiException(
          'TMDB API error: ${response.statusCode} - ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<SeriesResponseModel> getTrending({int page = 1}) async {
    final json =
        await _get('/trending/tv/week', queryParams: {'page': page.toString()});
    return SeriesResponseModel.fromJson(json);
  }

  @override
  Future<SeriesResponseModel> getPopular({int page = 1}) async {
    final json =
        await _get('/tv/popular', queryParams: {'page': page.toString()});
    return SeriesResponseModel.fromJson(json);
  }

  @override
  Future<SeriesResponseModel> getTopRated({int page = 1}) async {
    final json =
        await _get('/tv/top_rated', queryParams: {'page': page.toString()});
    return SeriesResponseModel.fromJson(json);
  }

  @override
  Future<SeriesResponseModel> getAiringToday({int page = 1}) async {
    final json =
        await _get('/tv/airing_today', queryParams: {'page': page.toString()});
    return SeriesResponseModel.fromJson(json);
  }

  @override
  Future<SeriesResponseModel> getOnTheAir({int page = 1}) async {
    final json =
        await _get('/tv/on_the_air', queryParams: {'page': page.toString()});
    return SeriesResponseModel.fromJson(json);
  }

  @override
  Future<SeriesResponseModel> searchSeries(String query,
      {int page = 1}) async {
    final json = await _get('/search/tv', queryParams: {
      'query': query,
      'page': page.toString(),
      'include_adult': 'false',
    });
    return SeriesResponseModel.fromJson(json);
  }

  @override
  Future<List<SeriesGenreModel>> getGenres() async {
    final json = await _get('/genre/tv/list');
    return (json['genres'] as List?)
            ?.map((e) =>
                SeriesGenreModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
  }

  @override
  Future<SeriesResponseModel> getSeriesByGenre(int genreId,
      {int page = 1}) async {
    final json = await _get('/discover/tv', queryParams: {
      'with_genres': genreId.toString(),
      'sort_by': 'popularity.desc',
      'page': page.toString(),
    });
    return SeriesResponseModel.fromJson(json);
  }

  @override
  Future<SeriesDetailModel> getSeriesDetails(int seriesId) async {
    final json = await _get('/tv/$seriesId');
    return SeriesDetailModel.fromJson(json);
  }

  @override
  Future<SeriesCreditsModel> getSeriesCredits(int seriesId) async {
    final json = await _get('/tv/$seriesId/credits');
    return SeriesCreditsModel.fromJson(json);
  }

  @override
  Future<List<SeriesVideoModel>> getSeriesVideos(int seriesId) async {
    final json = await _get('/tv/$seriesId/videos');
    return (json['results'] as List?)
            ?.map((e) =>
                SeriesVideoModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
  }

  @override
  Future<SeriesResponseModel> getSimilarSeries(int seriesId,
      {int page = 1}) async {
    final json = await _get('/tv/$seriesId/similar',
        queryParams: {'page': page.toString()});
    return SeriesResponseModel.fromJson(json);
  }

  @override
  Future<SeriesResponseModel> getRecommendedSeries(int seriesId,
      {int page = 1}) async {
    final json = await _get('/tv/$seriesId/recommendations',
        queryParams: {'page': page.toString()});
    return SeriesResponseModel.fromJson(json);
  }

  @override
  Future<SeasonDetailModel> getSeasonDetails(
      int seriesId, int seasonNumber) async {
    final json = await _get('/tv/$seriesId/season/$seasonNumber');
    return SeasonDetailModel.fromJson(json);
  }

  @override
  Future<SeriesResponseModel> discoverSeries({
    int page = 1,
    String? sortBy,
    int? withGenre,
    String? withOriginalLanguage,
    int? firstAirDateYear,
    double? voteAverageGte,
  }) async {
    final params = <String, String>{'page': page.toString()};
    if (sortBy != null) params['sort_by'] = sortBy;
    if (withGenre != null) params['with_genres'] = withGenre.toString();
    if (withOriginalLanguage != null) {
      params['with_original_language'] = withOriginalLanguage;
    }
    if (firstAirDateYear != null) {
      params['first_air_date_year'] = firstAirDateYear.toString();
    }
    if (voteAverageGte != null) {
      params['vote_average.gte'] = voteAverageGte.toString();
    }
    final json = await _get('/discover/tv', queryParams: params);
    return SeriesResponseModel.fromJson(json);
  }
}

class SeriesApiException implements Exception {
  final String message;
  SeriesApiException(this.message);

  @override
  String toString() => 'SeriesApiException: $message';
}
