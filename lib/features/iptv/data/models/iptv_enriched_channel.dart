import 'package:streamapp/features/iptv/data/models/iptv_channel_model.dart';
import 'package:streamapp/features/iptv/data/models/iptv_logo_model.dart';
import 'package:streamapp/features/iptv/data/models/iptv_stream_model.dart';

/// An enriched IPTV channel that combines data from channels, logos, and streams APIs.
class IptvEnrichedChannel {
  final IptvChannelModel channel;
  final IptvLogoModel? logo;
  final List<IptvStreamModel> streams;

  const IptvEnrichedChannel({
    required this.channel,
    this.logo,
    this.streams = const [],
  });

  String get id => channel.id;
  String get name => channel.name;
  String? get country => channel.country;
  List<String> get categories => channel.categories;
  bool get isNsfw => channel.isNsfw;
  bool get isActive => channel.isActive;
  String? get logoUrl => logo?.url;
  String? get streamUrl => streams.isNotEmpty ? streams.first.url : null;
  String? get quality => streams.isNotEmpty ? streams.first.quality : null;
  String? get website => channel.website;
  String? get network => channel.network;

  @override
  String toString() =>
      'IptvEnrichedChannel(id: $id, name: $name, country: $country, hasStream: ${streamUrl != null})';
}
