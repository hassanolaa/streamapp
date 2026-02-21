// Create a global instance of GetIt
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:streamapp/core/config/app_config.dart';
import 'package:streamapp/features/movies/data/datasources/movies_remote_data_source.dart';
import 'package:streamapp/features/movies/data/repositories/movies_repository_impl.dart';
import 'package:streamapp/features/series/data/datasources/series_remote_data_source.dart';
import 'package:streamapp/features/series/data/repositories/series_repository_impl.dart';
import 'package:streamapp/features/videos/data/datasources/videos_local_data_source.dart';
import 'package:streamapp/features/videos/data/datasources/videos_remote_data_source.dart';
import 'package:streamapp/features/videos/data/repositories/videos_repository_impl.dart';
import 'package:streamapp/features/videos/data/services/recommendation_service.dart';

final sl = GetIt.instance;

void setupLocator() async{

// Cubits/Blocs


// Repositories

 sl.registerLazySingleton<VideosRepository>(
    () => VideosRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

 sl.registerLazySingleton<MoviesRepository>(
    () => MoviesRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );
 
 sl.registerLazySingleton<SeriesRepository>(
    () => SeriesRepositoryImpl(
      remoteDataSource: sl(),
    ),
 );

// Data Sources
sl.registerLazySingleton<VideosRemoteDataSource>(
  () => VideosRemoteDataSourceImpl(
    tuberPath: AppConfig.getTuberPath(),
  ),
);

 sl.registerLazySingleton<VideosLocalDataSource>(
    () => VideosLocalDataSourceImpl(storage: sl()),
  );

 sl.registerLazySingleton<MoviesRemoteDataSource>(
    () => MoviesRemoteDataSourceImpl(
      apiKey: AppConfig.getTmdbApiKey(),
    ),
  );
  
  sl.registerLazySingleton<SeriesRemoteDataSource>(
    () => SeriesRemoteDataSourceImpl(
      apiKey: AppConfig.getTmdbApiKey(),
    ),
  );

 // --- External ---
   sl.registerLazySingleton(() => GetStorage());
   sl.registerLazySingleton<RecommendationService>(
    () => RecommendationService(),
  );
   await sl<RecommendationService>().initialize();


}