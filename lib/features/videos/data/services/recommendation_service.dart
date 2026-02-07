import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:streamapp/features/videos/data/models/recommendation_item_model.dart';
import 'package:streamapp/features/videos/data/models/watch_history_item_model.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';
import 'package:streamapp/features/videos/data/models/info_model.dart';

class RecommendationService {
  static const String _recommendationsBoxName = 'recommendations';
  static const String _watchHistoryBoxName = 'watch_history';
  static const int maxRecommendations = 25;

  late Box<RecommendationItemModel> _recommendationsBox;
  late Box<WatchHistoryItemModel> _watchHistoryBox;

  // Initialize Hive boxes
  Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(RecommendationItemModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(RecommendationSourceAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(WatchHistoryItemModelAdapter());
    }

    // Open boxes
    _recommendationsBox = await Hive.openBox<RecommendationItemModel>(
      _recommendationsBoxName,
    );
    _watchHistoryBox = await Hive.openBox<WatchHistoryItemModel>(
      _watchHistoryBoxName,
    );

    print('✅ Recommendation service initialized');
  }

  /// ==================== WATCH HISTORY ====================

  // Add video to watch history
  Future<void> addToWatchHistory(
    String url,
    String? name,
    int watchDurationSeconds,
    int totalDurationSeconds, {
    String? uploaderName,
    String? uploaderUrl,
    List<String> tags = const [],
  }) async {
    final item = WatchHistoryItemModel(
      url: url,
      name: name,
      watchedAt: DateTime.now(),
      watchDurationSeconds: watchDurationSeconds,
      totalDurationSeconds: totalDurationSeconds,
      uploaderName: uploaderName,
      uploaderUrl: uploaderUrl,
      tags: tags,
    );

    await _watchHistoryBox.put(url, item);
    print('✅ Added to watch history: $name');
  }

  // Get recent watch history
  List<WatchHistoryItemModel> getRecentWatchHistory({int limit = 20}) {
    final items = _watchHistoryBox.values.toList();
    items.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    return items.take(limit).toList();
  }

  /// ==================== RECOMMENDATIONS ====================

  // Get current recommendations
  List<RecommendationItemModel> getRecommendations() {
    final items = _recommendationsBox.values.toList();
    
    // Sort by score (descending) and recency
    items.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return b.addedAt.compareTo(a.addedAt);
    });

    return items.take(maxRecommendations).toList();
  }

  // Add recommendation (with deduplication)
  Future<void> addRecommendation(RecommendationItemModel item) async {
    // Check if already exists
    if (_recommendationsBox.containsKey(item.url)) {
      final existing = _recommendationsBox.get(item.url)!;
      
      // Boost score if re-recommended
      final boostedScore = min(existing.score + 5.0, 100.0);
      final updated = RecommendationItemModel(
        url: item.url,
        name: item.name,
        service: item.service,
        thumbnailUrls: item.thumbnailUrls,
        duration: item.duration,
        views: item.views,
        uploaderName: item.uploaderName,
        uploaderUrl: item.uploaderUrl,
        score: boostedScore,
        addedAt: DateTime.now(),
        source: item.source,
      );
      
      await _recommendationsBox.put(item.url, updated);
    } else {
      await _recommendationsBox.put(item.url, item);
    }

    // Keep only top N
    await _pruneRecommendations();
  }

  // Add multiple recommendations in batch
  Future<void> addRecommendations(List<RecommendationItemModel> items) async {
    for (var item in items) {
      await addRecommendation(item);
    }
  }

  // Remove recommendation
  Future<void> removeRecommendation(String url) async {
    await _recommendationsBox.delete(url);
  }

  // Clear all recommendations
  Future<void> clearRecommendations() async {
    await _recommendationsBox.clear();
  }

  // Keep only top N recommendations
  Future<void> _pruneRecommendations() async {
    final items = _recommendationsBox.values.toList();
    
    if (items.length <= maxRecommendations) return;

    // Sort by score
    items.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return b.addedAt.compareTo(a.addedAt);
    });

    // Keep top N, remove rest
    final toKeep = items.take(maxRecommendations).map((e) => e.url).toSet();
    final toRemove = items.skip(maxRecommendations).map((e) => e.url);

    for (var url in toRemove) {
      await _recommendationsBox.delete(url);
    }
  }

  /// ==================== FEED RECOMMENDATIONS ====================

  // Feed from StreamInfo recommendations
  Future<void> feedFromStreamInfo(StreamInfoModel streamInfo) async {
    final recommendations = streamInfo.recommendations
        .where((summary) => summary.type == 'stream')
        .map((summary) {
      final stream = summary.data as StreamSummaryModel;
      return RecommendationItemModel.fromStreamSummary(
        stream,
        score: 70.0, // High score from video detail page
        source: RecommendationSource.streamRecommendations,
      );
    }).take(1).toList(); // Limit to 1 recommendation

    await addRecommendations(recommendations.take(10).toList());
    print('✅ Fed ${recommendations.length} recommendations from StreamInfo');
  }

  // Feed from search results
  Future<void> feedFromSearchResults(List<StreamSummaryModel> results) async {
    final recommendations = results.map((stream) {
      return RecommendationItemModel.fromStreamSummary(
        stream,
        score: 60.0, // Medium score from search
        source: RecommendationSource.searchResults,
      );
    }).toList();

    await addRecommendations(recommendations.take(8).toList());
    print('✅ Fed ${recommendations.length} recommendations from search');
  }

  // Feed from catalog (trending/popular)
  Future<void> feedFromCatalog(
    List<StreamSummaryModel> videos,
    String catalogName,
  ) async {
    // Higher score for trending/live content
    final score = catalogName.toLowerCase().contains('live') ||
            catalogName.toLowerCase().contains('trending')
        ? 80.0
        : 55.0;

    final recommendations = videos.map((stream) {
      return RecommendationItemModel.fromStreamSummary(
        stream,
        score: score,
        source: RecommendationSource.catalog,
      );
    }).toList();

    await addRecommendations(recommendations.take(10).toList());
    print('✅ Fed ${recommendations.length} recommendations from catalog: $catalogName');
  }

  // Feed based on watch history (find similar content)
  Future<void> feedFromWatchHistory() async {
    final history = getRecentWatchHistory(limit: 10);
    
    if (history.isEmpty) {
      print('⚠️ No watch history to feed from');
      return;
    }

    // Extract uploaders user likes
    final favoriteUploaders = <String>{};
    for (var item in history) {
      if (item.isCompleted && item.uploaderUrl != null) {
        favoriteUploaders.add(item.uploaderUrl!);
      }
    }

    print('✅ Found ${favoriteUploaders.length} favorite uploaders from watch history');
    // TODO: In a real system, fetch videos from these uploaders
    // For now, this is a placeholder
  }

  /// ==================== SMART RECOMMENDATION BUILDER ====================

  // Build initial recommendations (call this on app start)
  Future<void> buildInitialRecommendations({
    List<StreamSummaryModel>? trendingVideos,
    List<StreamSummaryModel>? popularVideos,
  }) async {
    print('🔨 Building initial recommendations...');

    // Add trending content
    if (trendingVideos != null && trendingVideos.isNotEmpty) {
      await feedFromCatalog(trendingVideos, 'Trending');
    }

    // Add popular content
    if (popularVideos != null && popularVideos.isNotEmpty) {
      await feedFromCatalog(popularVideos, 'Popular');
    }

    // Feed from watch history
    await feedFromWatchHistory();

    final count = getRecommendations().length;
    print('✅ Initial recommendations built: $count videos');
  }

  // Calculate recommendation score based on user behavior
  double _calculateScore({
    required RecommendationSource source,
    int? views,
    int? duration,
    DateTime? uploadDate,
  }) {
    double score = 50.0;

    // Source-based scoring
    switch (source) {
      case RecommendationSource.watchHistory:
        score += 30.0;
        break;
      case RecommendationSource.streamRecommendations:
        score += 20.0;
        break;
      case RecommendationSource.searchResults:
        score += 10.0;
        break;
      case RecommendationSource.catalog:
        score += 15.0;
        break;
      case RecommendationSource.channelBased:
        score += 25.0;
        break;
      case RecommendationSource.other:
        score += 5.0;
        break;
    }

    // View count boost
    if (views != null) {
      if (views > 1000000) score += 10.0;
      else if (views > 100000) score += 5.0;
    }

    // Recent uploads boost
    if (uploadDate != null) {
      final daysSinceUpload = DateTime.now().difference(uploadDate).inDays;
      if (daysSinceUpload < 7) score += 5.0;
    }

    return score.clamp(0.0, 100.0);
  }

  // Close boxes
  Future<void> dispose() async {
    await _recommendationsBox.close();
    await _watchHistoryBox.close();
  }
}
