import 'package:hive/hive.dart';

part 'watch_history_item_model.g.dart';

@HiveType(typeId: 2)
class WatchHistoryItemModel {
  @HiveField(0)
  final String url;

  @HiveField(1)
  final String? name;

  @HiveField(2)
  final DateTime watchedAt;

  @HiveField(3)
  final int watchDurationSeconds; // How long they watched

  @HiveField(4)
  final int totalDurationSeconds; // Total video duration

  @HiveField(5)
  final String? uploaderName;

  @HiveField(6)
  final String? uploaderUrl;

  @HiveField(7)
  final List<String> tags;

  WatchHistoryItemModel({
    required this.url,
    this.name,
    required this.watchedAt,
    required this.watchDurationSeconds,
    required this.totalDurationSeconds,
    this.uploaderName,
    this.uploaderUrl,
    required this.tags,
  });

  // Calculate completion percentage
  double get completionRate {
    if (totalDurationSeconds == 0) return 0;
    return (watchDurationSeconds / totalDurationSeconds).clamp(0.0, 1.0);
  }

  // Check if user finished watching
  bool get isCompleted => completionRate >= 0.8;
}
