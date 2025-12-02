class ChapterModel {
  final String title;
  final int startTimeSeconds;
  final String? channelName;
  final String? previewUrl;

  ChapterModel({
    required this.title,
    required this.startTimeSeconds,
    this.channelName,
    this.previewUrl,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      title: json['title'] ?? '',
      startTimeSeconds: json['startTimeSeconds'] ?? 0,
      channelName: json['channelName'],
      previewUrl: json['previewUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startTimeSeconds': startTimeSeconds,
      'channelName': channelName,
      'previewUrl': previewUrl,
    };
  }
}
