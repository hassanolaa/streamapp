import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:streamapp/features/iptv/data/models/iptv_channel_model.dart';
import 'package:streamapp/features/iptv/data/models/iptv_country_model.dart';
import 'package:streamapp/features/iptv/data/models/iptv_feed_model.dart';
import 'package:streamapp/features/iptv/data/models/iptv_logo_model.dart';
import 'package:streamapp/features/iptv/data/models/iptv_stream_model.dart';

abstract class IptvRemoteDataSource {
  Future<List<IptvChannelModel>> getChannels();
  Future<List<IptvFeedModel>> getFeeds();
  Future<List<IptvLogoModel>> getLogos();
  Future<List<IptvStreamModel>> getStreams();
  Future<List<IptvCountryModel>> getCountries();
}

class IptvRemoteDataSourceImpl implements IptvRemoteDataSource {
  static const String _baseUrl = 'https://iptv-org.github.io/api';

  static const String _channelsUrl = '$_baseUrl/channels.json';
  static const String _feedsUrl = '$_baseUrl/feeds.json';
  static const String _logosUrl = '$_baseUrl/logos.json';
  static const String _streamsUrl = '$_baseUrl/streams.json';
  static const String _countriesUrl = '$_baseUrl/countries.json';

  final http.Client _client;

  IptvRemoteDataSourceImpl({http.Client? client})
      : _client = client ?? http.Client();

  Future<List<T>> _fetchList<T>(
    String url,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'StreamApp/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw IptvException(
            'HTTP ${response.statusCode} when fetching $url');
      }

      final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
      return jsonList
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList();
    } catch (e) {
      if (e is IptvException) rethrow;
      throw IptvException('Failed to fetch from $url: $e');
    }
  }

  @override
  Future<List<IptvChannelModel>> getChannels() async {
    return _fetchList(_channelsUrl, IptvChannelModel.fromJson);
  }

  @override
  Future<List<IptvFeedModel>> getFeeds() async {
    return _fetchList(_feedsUrl, IptvFeedModel.fromJson);
  }

  @override
  Future<List<IptvLogoModel>> getLogos() async {
    return _fetchList(_logosUrl, IptvLogoModel.fromJson);
  }

  @override
  Future<List<IptvStreamModel>> getStreams() async {
    return _fetchList(_streamsUrl, IptvStreamModel.fromJson);
  }

  @override
  Future<List<IptvCountryModel>> getCountries() async {
    return _fetchList(_countriesUrl, IptvCountryModel.fromJson);
  }
}

class IptvException implements Exception {
  final String message;
  const IptvException(this.message);

  @override
  String toString() => 'IptvException: $message';
}
