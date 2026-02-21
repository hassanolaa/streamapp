import 'package:streamapp/features/series/data/datasources/series_remote_data_source.dart';
import 'package:streamapp/features/series/data/models/series_model.dart';


abstract class SeriesRepository {
  Future<SeriesResponseModel> getTrending({int page = 1});
  Future<SeriesResponseModel> getPopular({int page = 1});
  Future<SeriesResponseModel> getTopRated({int page = 1});
  Future<SeriesResponseModel> getAiringToday({int page = 1});
  Future<SeriesResponseModel> getOnTheAir({int page = 1});
  Future<SeriesResponseModel> searchSeries(String query, {int page = 1});
  Future<List<SeriesGenreModel>> getGenres();
  Future<SeriesResponseModel> getSeriesByGenre(int genreId, {int page = 1});
  Future<SeriesDetailModel> getSeriesDetails(int seriesId);
  Future<SeriesCreditsModel> getSeriesCredits(int seriesId);
  Future<List<SeriesVideoModel>> getSeriesVideos(int seriesId);
  Future<SeriesResponseModel> getSimilarSeries(int seriesId, {int page = 1});
  Future<SeriesResponseModel> getRecommendedSeries(int seriesId,
      {int page = 1});
  Future<SeasonDetailModel> getSeasonDetails(
      int seriesId, int seasonNumber);
  Future<SeriesResponseModel> discoverSeries({
    int page = 1,
    String? sortBy,
    int? withGenre,
    String? withOriginalLanguage,
    int? firstAirDateYear,
    double? voteAverageGte,
  });
}


class SeriesRepositoryImpl implements SeriesRepository {
  final SeriesRemoteDataSource remoteDataSource;

  SeriesRepositoryImpl({required this.remoteDataSource});

  Future<SeriesResponseModel> getTrending({int page = 1}) =>
      remoteDataSource.getTrending(page: page);

  Future<SeriesResponseModel> getPopular({int page = 1}) =>
      remoteDataSource.getPopular(page: page);

  Future<SeriesResponseModel> getTopRated({int page = 1}) =>
      remoteDataSource.getTopRated(page: page);

  Future<SeriesResponseModel> getAiringToday({int page = 1}) =>
      remoteDataSource.getAiringToday(page: page);

  Future<SeriesResponseModel> getOnTheAir({int page = 1}) =>
      remoteDataSource.getOnTheAir(page: page);

  Future<SeriesResponseModel> searchSeries(String query, {int page = 1}) =>
      remoteDataSource.searchSeries(query, page: page);

  Future<List<SeriesGenreModel>> getGenres() =>
      remoteDataSource.getGenres();

  Future<SeriesResponseModel> getSeriesByGenre(int genreId, {int page = 1}) =>
      remoteDataSource.getSeriesByGenre(genreId, page: page);

  Future<SeriesDetailModel> getSeriesDetails(int seriesId) =>
      remoteDataSource.getSeriesDetails(seriesId);

  Future<SeriesCreditsModel> getSeriesCredits(int seriesId) =>
      remoteDataSource.getSeriesCredits(seriesId);

  Future<List<SeriesVideoModel>> getSeriesVideos(int seriesId) =>
      remoteDataSource.getSeriesVideos(seriesId);

  Future<SeriesResponseModel> getSimilarSeries(int seriesId, {int page = 1}) =>
      remoteDataSource.getSimilarSeries(seriesId, page: page);

  Future<SeriesResponseModel> getRecommendedSeries(int seriesId,
          {int page = 1}) =>
      remoteDataSource.getRecommendedSeries(seriesId, page: page);

  Future<SeasonDetailModel> getSeasonDetails(
          int seriesId, int seasonNumber) =>
      remoteDataSource.getSeasonDetails(seriesId, seasonNumber);

  Future<SeriesResponseModel> discoverSeries({
    int page = 1,
    String? sortBy,
    int? withGenre,
    String? withOriginalLanguage,
    int? firstAirDateYear,
    double? voteAverageGte,
  }) =>
      remoteDataSource.discoverSeries(
        page: page,
        sortBy: sortBy,
        withGenre: withGenre,
        withOriginalLanguage: withOriginalLanguage,
        firstAirDateYear: firstAirDateYear,
        voteAverageGte: voteAverageGte,
      );
}
