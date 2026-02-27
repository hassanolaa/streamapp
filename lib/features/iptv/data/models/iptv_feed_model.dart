class IptvFeedModel {
  final String channel;
  final String id;
  final String name;
  final List<String> altNames;
  final bool isMain;
  final List<String> broadcastArea;
  final List<String> timezones;
  final List<String> languages;
  final String? format;

  const IptvFeedModel({
    required this.channel,
    required this.id,
    required this.name,
    this.altNames = const [],
    this.isMain = false,
    this.broadcastArea = const [],
    this.timezones = const [],
    this.languages = const [],
    this.format,
  });

  factory IptvFeedModel.fromJson(Map<String, dynamic> json) {
    return IptvFeedModel(
      channel: json['channel'] as String? ?? '',
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      altNames: (json['alt_names'] as List<dynamic>?)?.cast<String>() ?? [],
      isMain: json['is_main'] as bool? ?? false,
      broadcastArea: (json['broadcast_area'] as List<dynamic>?)?.cast<String>() ?? [],
      timezones: (json['timezones'] as List<dynamic>?)?.cast<String>() ?? [],
      languages: (json['languages'] as List<dynamic>?)?.cast<String>() ?? [],
      format: json['format'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channel': channel,
      'id': id,
      'name': name,
      'alt_names': altNames,
      'is_main': isMain,
      'broadcast_area': broadcastArea,
      'timezones': timezones,
      'languages': languages,
      'format': format,
    };
  }

  @override
  String toString() => 'IptvFeedModel(channel: $channel, id: $id, name: $name)';
}
