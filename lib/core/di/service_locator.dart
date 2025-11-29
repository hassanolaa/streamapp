

// Create a global instance of GetIt
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';

final sl = GetIt.instance;

void setupLocator() {

// Cubits/Blocs


// Repositories


// Data Sources


 // --- External ---
   sl.registerLazySingleton(() => GetStorage());

}