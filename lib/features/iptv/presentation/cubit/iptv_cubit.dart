import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streamapp/features/iptv/data/repositories/iptv_repository_impl.dart';
import 'package:streamapp/features/iptv/presentation/cubit/iptv_state.dart';

class IptvCubit extends Cubit<IptvState> {
  final IptvRepository repository;

  IptvCubit({required this.repository}) : super(IptvInitial());

  /// Load all channels grouped by country and all countries metadata.
  Future<void> loadCatalogs() async {
    try {
      emit(IptvLoading());
      print('📡 [IptvCubit] Loading IPTV catalogs...');

      final results = await Future.wait([
        repository.getChannelsByCountry(),
        repository.getCountries(),
      ]);

      final channelsByCountry = results[0] as dynamic;
      final countries = results[1] as dynamic;

      print(
          '✅ [IptvCubit] Loaded ${channelsByCountry.length} countries with channels');

      emit(IptvCatalogsLoaded(
        channelsByCountry: channelsByCountry,
        countries: countries,
      ));
    } catch (e) {
      print('❌ [IptvCubit] Error loading IPTV catalogs: $e');
      emit(IptvError(e.toString()));
    }
  }

  /// Search channels by a text query.
  Future<void> searchChannels(String query) async {
    try {
      emit(IptvLoading());
      print('🔍 [IptvCubit] Searching IPTV channels: "$query"');

      final results = await repository.searchChannels(query);

      print('✅ [IptvCubit] Found ${results.length} channels for "$query"');

      emit(IptvSearchSuccess(results: results, query: query));
    } catch (e) {
      print('❌ [IptvCubit] Error searching IPTV channels: $e');
      emit(IptvError(e.toString()));
    }
  }

  /// Refresh by clearing cache and reloading.
  Future<void> refresh() async {
    if (repository is IptvRepositoryImpl) {
      (repository as IptvRepositoryImpl).clearCache();
    }
    await loadCatalogs();
  }
}
