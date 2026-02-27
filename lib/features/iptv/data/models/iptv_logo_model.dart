class IptvLogoModel {
  final String channel;
  final String? feed;
  final List<String> tags;
  final int? width;
  final int? height;
  final String? format;
  final String url;

  const IptvLogoModel({
    required this.channel,
    this.feed,
    this.tags = const [],
    this.width,
    this.height,
    this.format,
    required this.url,
  });

  factory IptvLogoModel.fromJson(Map<String, dynamic> json) {
    return IptvLogoModel(
      channel: json['channel'] as String? ?? '',
      feed: json['feed'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      width: json['width'] as int?,
      height: json['height'] as int?,
      format: json['format'] as String?,
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channel': channel,
      'feed': feed,
      'tags': tags,
      'width': width,
      'height': height,
      'format': format,
      'url': url,
    };
  }

  @override
  String toString() => 'IptvLogoModel(channel: $channel, url: $url)';
}
