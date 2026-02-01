import 'package:hive/hive.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';
import 'package:streamapp/features/videos/data/models/thumbnail_model.dart';

part 'recommendation_item_model.g.dart';

@HiveType(typeId: 0)
class RecommendationItemModel {
  @HiveField(0)
  final String url;

  @HiveField(1)
  final String? name;

  @HiveField(2)
  final String? service;

  @HiveField(3)
  final List<String> thumbnailUrls; // Store URLs only (lightweight)

  @HiveField(4)
  final int? duration;

  @HiveField(5)
  final int? views;

  @HiveField(6)
  final String? uploaderName;

  @HiveField(7)
  final String? uploaderUrl;

  @HiveField(8)
  final double score; // Recommendation score (0-100)

  @HiveField(9)
  final DateTime addedAt;

  @HiveField(10)
  final RecommendationSource source;

  RecommendationItemModel({
    required this.url,
    this.name,
    this.service,
    required this.thumbnailUrls,
    this.duration,
    this.views,
    this.uploaderName,
    this.uploaderUrl,
    required this.score,
    required this.addedAt,
    required this.source,
  });

  // Create from StreamSummaryModel
  factory RecommendationItemModel.fromStreamSummary(
    StreamSummaryModel stream, {
    double score = 50.0,
    RecommendationSource source = RecommendationSource.catalog,
  }) {
    return RecommendationItemModel(
      url: stream.url ?? '',
      name: stream.name,
      service: stream.service,
      thumbnailUrls: stream.thumbnails
          .map((t) => t.url ?? '')
          .where((url) => url.isNotEmpty)
          .toList(),
      duration: stream.duration,
      views: stream.views,
      uploaderName: stream.uploader?.name,
      uploaderUrl: stream.uploader?.url,
      score: score,
      addedAt: DateTime.now(),
      source: source,
    );
  }

  // Convert back to StreamSummaryModel (for display)
  StreamSummaryModel toStreamSummary() {
    return StreamSummaryModel(
      name: name,
      url: url,
      thumbnails: thumbnailUrls
          .map((url) => ThumbnailModel(url: url, width: 320, height: 180))
          .toList(),
      service: service,
      duration: duration,
      views: views,
      uploader: uploaderName != null
          ? ChannelSummaryModel(
              name: uploaderName,
              url: uploaderUrl,
              thumbnails: [],
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'name': name,
      'service': service,
      'thumbnailUrls': thumbnailUrls,
      'duration': duration,
      'views': views,
      'uploaderName': uploaderName,
      'uploaderUrl': uploaderUrl,
      'score': score,
      'addedAt': addedAt.toIso8601String(),
      'source': source.name,
    };
  }

  factory RecommendationItemModel.fromJson(Map<String, dynamic> json) {
    return RecommendationItemModel(
      url: json['url'],
      name: json['name'],
      service: json['service'],
      thumbnailUrls: List<String>.from(json['thumbnailUrls'] ?? []),
      duration: json['duration'],
      views: json['views'],
      uploaderName: json['uploaderName'],
      uploaderUrl: json['uploaderUrl'],
      score: (json['score'] ?? 50.0).toDouble(),
      addedAt: DateTime.parse(json['addedAt']),
      source: RecommendationSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => RecommendationSource.other,
      ),
    );
  }
}

@HiveType(typeId: 1)
enum RecommendationSource {
  @HiveField(0)
  watchHistory, // From videos user watched

  @HiveField(1)
  streamRecommendations, // From StreamInfo.recommendations

  @HiveField(2)
  searchResults, // From search page

  @HiveField(3)
  catalog, // From trending/popular catalogs

  @HiveField(4)
  channelBased, // From same uploader

  @HiveField(5)
  other, // Generic
}
