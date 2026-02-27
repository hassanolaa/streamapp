class IptvStreamModel {
  final String channel;
  final String? feed;
  final String? title;
  final String url;
  final String? referrer;
  final String? userAgent;
  final String? quality;

  const IptvStreamModel({
    required this.channel,
    this.feed,
    this.title,
    required this.url,
    this.referrer,
    this.userAgent,
    this.quality,
  });

  factory IptvStreamModel.fromJson(Map<String, dynamic> json) {
    return IptvStreamModel(
      channel: json['channel'] as String? ?? '',
      feed: json['feed'] as String?,
      title: json['title'] as String?,
      url: json['url'] as String? ?? '',
      referrer: json['referrer'] as String?,
      userAgent: json['user_agent'] as String?,
      quality: json['quality'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channel': channel,
      'feed': feed,
      'title': title,
      'url': url,
      'referrer': referrer,
      'user_agent': userAgent,
      'quality': quality,
    };
  }

  @override
  String toString() => 'IptvStreamModel(channel: $channel, url: $url, quality: $quality)';
}
