import 'package:streamapp/features/iptv/data/datasources/iptv_remote_data_source.dart';
import 'package:streamapp/features/iptv/data/models/iptv_channel_model.dart';
import 'package:streamapp/features/iptv/data/models/iptv_country_model.dart';
import 'package:streamapp/features/iptv/data/models/iptv_enriched_channel.dart';
import 'package:streamapp/features/iptv/data/models/iptv_logo_model.dart';
import 'package:streamapp/features/iptv/data/models/iptv_stream_model.dart';

abstract class IptvRepository {
  /// Fetch enriched channels grouped by country.
  /// Returns a map of [countryCode -> List<IptvEnrichedChannel>].
  Future<Map<String, List<IptvEnrichedChannel>>> getChannelsByCountry();

  /// Fetch all countries.
  Future<List<IptvCountryModel>> getCountries();

  /// Search channels by query across name, alt names, network, etc.
  Future<List<IptvEnrichedChannel>> searchChannels(String query);
}

class IptvRepositoryImpl implements IptvRepository {
  final IptvRemoteDataSource remoteDataSource;

  // Simple in-memory cache so we don't re-fetch on every call.
  List<IptvChannelModel>? _cachedChannels;
  List<IptvLogoModel>? _cachedLogos;
  List<IptvStreamModel>? _cachedStreams;
  List<IptvCountryModel>? _cachedCountries;
  Map<String, List<IptvEnrichedChannel>>? _cachedByCountry;

  IptvRepositoryImpl({required this.remoteDataSource});

  /// Fetch and cache raw data from all endpoints in parallel (only on first call).
  Future<void> _ensureDataLoaded() async {
    if (_cachedChannels != null &&
        _cachedLogos != null &&
        _cachedStreams != null &&
        _cachedCountries != null) {
      return;
    }

    print('📡 [IptvRepository] Fetching data from iptv-org APIs...');

    // Fetch channels, logos, streams, countries in parallel
    final results = await Future.wait([
      remoteDataSource.getChannels().catchError((e) {
        print('⚠️ Failed to fetch channels: $e');
        return <IptvChannelModel>[];
      }),
      remoteDataSource.getLogos().catchError((e) {
        print('⚠️ Failed to fetch logos: $e');
        return <IptvLogoModel>[];
      }),
      remoteDataSource.getStreams().catchError((e) {
        print('⚠️ Failed to fetch streams: $e');
        return <IptvStreamModel>[];
      }),
      remoteDataSource.getCountries().catchError((e) {
        print('⚠️ Failed to fetch countries: $e');
        return <IptvCountryModel>[];
      }),
    ]);

    _cachedChannels = results[0] as List<IptvChannelModel>;
    _cachedLogos = results[1] as List<IptvLogoModel>;
    _cachedStreams = results[2] as List<IptvStreamModel>;
    _cachedCountries = results[3] as List<IptvCountryModel>;

    print(
        '✅ [IptvRepository] Loaded: ${_cachedChannels!.length} channels, '
        '${_cachedLogos!.length} logos, ${_cachedStreams!.length} streams, '
        '${_cachedCountries!.length} countries');
  }

  List<IptvEnrichedChannel> _buildEnrichedChannels() {
    final channels = _cachedChannels ?? [];
    final logos = _cachedLogos ?? [];
    final streams = _cachedStreams ?? [];

    // Build lookup maps for O(1) access
    final logoMap = <String, IptvLogoModel>{};
    for (final logo in logos) {
      // Use the main-feed logo (no specific feed) or fall back to first available
      if (!logoMap.containsKey(logo.channel)) {
        logoMap[logo.channel] = logo;
      } else if (logo.feed == null || logo.feed!.isEmpty) {
        // Prefer logos without a specific feed (channel-level logos)
        logoMap[logo.channel] = logo;
      }
    }

    final streamsMap = <String, List<IptvStreamModel>>{};
    for (final stream in streams) {
      streamsMap.putIfAbsent(stream.channel, () => []).add(stream);
    }

    return channels
        .where((ch) => ch.isActive && !ch.isNsfw)
        .map((ch) => IptvEnrichedChannel(
              channel: ch,
              logo: logoMap[ch.id],
              streams: streamsMap[ch.id] ?? [],
            ))
        .toList();
  }

  @override
  Future<Map<String, List<IptvEnrichedChannel>>> getChannelsByCountry() async {
    if (_cachedByCountry != null) return _cachedByCountry!;

    await _ensureDataLoaded();

    final enriched = _buildEnrichedChannels();

    final result = <String, List<IptvEnrichedChannel>>{};
    for (final ch in enriched) {
      final countryCode = ch.country ?? 'UNKNOWN';
      result.putIfAbsent(countryCode, () => []).add(ch);
    }

    // Sort countries by channel count (descending) for a better UX
    final sortedEntries = result.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    _cachedByCountry = Map.fromEntries(sortedEntries);
    return _cachedByCountry!;
  }

  @override
  Future<List<IptvCountryModel>> getCountries() async {
    await _ensureDataLoaded();
    return _cachedCountries ?? [];
  }

  @override
  Future<List<IptvEnrichedChannel>> searchChannels(String query) async {
    await _ensureDataLoaded();

    final enriched = _buildEnrichedChannels();
    final queryLower = query.toLowerCase().trim();

    if (queryLower.isEmpty) return enriched;

    return enriched.where((ch) {
      final name = ch.name.toLowerCase();
      final altNames = ch.channel.altNames.map((n) => n.toLowerCase());
      final network = ch.network?.toLowerCase() ?? '';
      final country = ch.country?.toLowerCase() ?? '';
      final categories = ch.categories.map((c) => c.toLowerCase());

      return name.contains(queryLower) ||
          altNames.any((n) => n.contains(queryLower)) ||
          network.contains(queryLower) ||
          country.contains(queryLower) ||
          categories.any((c) => c.contains(queryLower));
    }).toList();
  }

  /// Clears the in-memory cache (e.g., when user wants a fresh load).
  void clearCache() {
    _cachedChannels = null;
    _cachedLogos = null;
    _cachedStreams = null;
    _cachedCountries = null;
    _cachedByCountry = null;
  }
}
