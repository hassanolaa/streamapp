import 'package:streamapp/features/videos/data/models/chapter_model.dart';
import 'package:streamapp/features/videos/data/models/formatted_text_model.dart';
import 'package:streamapp/features/videos/data/models/items_model.dart';
import 'package:streamapp/features/videos/data/models/preview_frames_model.dart';
import 'package:streamapp/features/videos/data/models/stream_model.dart';
import 'package:streamapp/features/videos/data/models/summary_model.dart';
import 'package:streamapp/features/videos/data/models/thumbnail_model.dart';

class StreamInfoModel {
  final String? id;
  final String? name;
  final String? url;
  final String? originalUrl;
  final String? service;
  final String? type; // "AUDIO", "VIDEO", etc.
  final List<ThumbnailModel> thumbnails;
  final int? uploadTimeStamp;
  final int? duration;
  final int? ageLimit;
  final FormattedTextModel? description;
  final int? viewCount;
  final int? likeCount;
  final int? dislikeCount;
  final ChannelSummaryModel? uploader;
  final ChannelSummaryModel? subUploader;
  final List<SummaryModel> recommendations;
  final int? startPosition;
  final String? category;
  final String? license;
  final String? supportInfo;
  final String? language;
  final bool? short;
  final List<String> tags;
  final List<ChapterModel> chapters;
  final List<PreviewFramesModel> previewFrames;
  final List<VideoStreamModel> videoStreams;
  final List<AudioStreamModel> audioStreams;
  final List<VideoStreamModel> videoOnlyStreams;
  final List<SubtitlesStreamModel> subtitles;

  StreamInfoModel({
    this.id,
    this.name,
    this.url,
    this.originalUrl,
    this.service,
    this.type,
    required this.thumbnails,
    this.uploadTimeStamp,
    this.duration,
    this.ageLimit,
    this.description,
    this.viewCount,
    this.likeCount,
    this.dislikeCount,
    this.uploader,
    this.subUploader,
    required this.recommendations,
    this.startPosition,
    this.category,
    this.license,
    this.supportInfo,
    this.language,
    this.short,
    required this.tags,
    required this.chapters,
    required this.previewFrames,
    required this.videoStreams,
    required this.audioStreams,
    required this.videoOnlyStreams,
    required this.subtitles,
  });

  factory StreamInfoModel.fromJson(Map<String, dynamic> json) {
    return StreamInfoModel(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      originalUrl: json['originalUrl'],
      service: json['service'],
      type: json['type'],
      thumbnails: (json['thumbnails'] as List?)
              ?.map((e) => ThumbnailModel.fromJson(e))
              .toList() ??
          [],
      uploadTimeStamp: json['uploadTimeStamp'],
      duration: json['duration'],
      ageLimit: json['ageLimit'],
      description: json['description'] != null
          ? FormattedTextModel.fromJson(json['description'])
          : null,
      viewCount: json['viewCount'],
      likeCount: json['likeCount'],
      dislikeCount: json['dislikeCount'],
      uploader: json['uploader'] != null
          ? ChannelSummaryModel.fromJson(json['uploader'])
          : null,
      subUploader: json['subUploader'] != null
          ? ChannelSummaryModel.fromJson(json['subUploader'])
          : null,
      recommendations: (json['recommendations'] as List?)
              ?.map((e) => SummaryModel.fromJson(e))
              .toList() ??
          [],
      startPosition: json['startPosition'],
      category: json['category'],
      license: json['license'],
      supportInfo: json['supportInfo'],
      language: json['language'],
      short: json['short'],
      tags: List<String>.from(json['tags'] ?? []),
      chapters: (json['chapters'] as List?)
              ?.map((e) => ChapterModel.fromJson(e))
              .toList() ??
          [],
      previewFrames: (json['previewFrames'] as List?)
              ?.map((e) => PreviewFramesModel.fromJson(e))
              .toList() ??
          [],
      videoStreams: (json['videoStreams'] as List?)
              ?.map((e) => VideoStreamModel.fromJson(e))
              .toList() ??
          [],
      audioStreams: (json['audioStreams'] as List?)
              ?.map((e) => AudioStreamModel.fromJson(e))
              .toList() ??
          [],
      videoOnlyStreams: (json['videoOnlyStreams'] as List?)
              ?.map((e) => VideoStreamModel.fromJson(e))
              .toList() ??
          [],
      subtitles: (json['subtitles'] as List?)
              ?.map((e) => SubtitlesStreamModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'originalUrl': originalUrl,
      'service': service,
      'type': type,
      'thumbnails': thumbnails.map((e) => e.toJson()).toList(),
      'uploadTimeStamp': uploadTimeStamp,
      'duration': duration,
      'ageLimit': ageLimit,
      'description': description?.toJson(),
      'viewCount': viewCount,
      'likeCount': likeCount,
      'dislikeCount': dislikeCount,
      'uploader': uploader?.toJson(),
      'subUploader': subUploader?.toJson(),
      'recommendations': recommendations.map((e) => e.toJson()).toList(),
      'startPosition': startPosition,
      'category': category,
      'license': license,
      'supportInfo': supportInfo,
      'language': language,
      'short': short,
      'tags': tags,
      'chapters': chapters.map((e) => e.toJson()).toList(),
      'previewFrames': previewFrames.map((e) => e.toJson()).toList(),
      'videoStreams': videoStreams.map((e) => e.toJson()).toList(),
      'audioStreams': audioStreams.map((e) => e.toJson()).toList(),
      'videoOnlyStreams': videoOnlyStreams.map((e) => e.toJson()).toList(),
      'subtitles': subtitles.map((e) => e.toJson()).toList(),
    };
  }
}










class PlaylistInfoModel {
  final String? id;
  final String? name;
  final String? url;
  final String? originalUrl;
  final String? service;
  final FormattedTextModel? description;
  final ItemsModel? items;
  final ChannelSummaryModel? uploader;
  final ChannelSummaryModel? subUploader;
  final List<ThumbnailModel> thumbnails;
  final List<ThumbnailModel> banners;
  final String? playlistType;

  PlaylistInfoModel({
    this.id,
    this.name,
    this.url,
    this.originalUrl,
    this.service,
    this.description,
    this.items,
    this.uploader,
    this.subUploader,
    required this.thumbnails,
    required this.banners,
    this.playlistType,
  });

  factory PlaylistInfoModel.fromJson(Map<String, dynamic> json) {
    return PlaylistInfoModel(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      originalUrl: json['originalUrl'],
      service: json['service'],
      description: json['description'] != null
          ? FormattedTextModel.fromJson(json['description'])
          : null,
      items: json['items'] != null ? ItemsModel.fromJson(json['items']) : null,
      uploader: json['uploader'] != null
          ? ChannelSummaryModel.fromJson(json['uploader'])
          : null,
      subUploader: json['subUploader'] != null
          ? ChannelSummaryModel.fromJson(json['subUploader'])
          : null,
      thumbnails: (json['thumbnails'] as List?)
              ?.map((e) => ThumbnailModel.fromJson(e))
              .toList() ??
          [],
      banners: (json['banners'] as List?)
              ?.map((e) => ThumbnailModel.fromJson(e))
              .toList() ??
          [],
      playlistType: json['playlistType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'originalUrl': originalUrl,
      'service': service,
      'description': description?.toJson(),
      'items': items?.toJson(),
      'uploader': uploader?.toJson(),
      'subUploader': subUploader?.toJson(),
      'thumbnails': thumbnails.map((e) => e.toJson()).toList(),
      'banners': banners.map((e) => e.toJson()).toList(),
      'playlistType': playlistType,
    };
  }
}




class ChannelInfoModel {
  final String? id;
  final String? name;
  final String? url;
  final String? originalUrl;
  final String? service;
  final ChannelSummaryModel? parentChannel;
  final List<ThumbnailModel> avatars;
  final bool? verified;
  final FormattedTextModel? description;
  final int? subscriberCount;
  final int? streamCount;
  final List<ThumbnailModel> banners;
  final List<String> donationLinks;
  final List<String> tags;
  final String? feedUrl;
  final List<PlaylistInfoModel> tabs;

  ChannelInfoModel({
    this.id,
    this.name,
    this.url,
    this.originalUrl,
    this.service,
    this.parentChannel,
    required this.avatars,
    this.verified,
    this.description,
    this.subscriberCount,
    this.streamCount,
    required this.banners,
    required this.donationLinks,
    required this.tags,
    this.feedUrl,
    required this.tabs,
  });

  factory ChannelInfoModel.fromJson(Map<String, dynamic> json) {
    return ChannelInfoModel(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      originalUrl: json['originalUrl'],
      service: json['service'],
      parentChannel: json['parentChannel'] != null
          ? ChannelSummaryModel.fromJson(json['parentChannel'])
          : null,
      avatars: (json['avatars'] as List?)
              ?.map((e) => ThumbnailModel.fromJson(e))
              .toList() ??
          [],
      verified: json['verified'],
      description: json['description'] != null
          ? FormattedTextModel.fromJson(json['description'])
          : null,
      subscriberCount: json['subscriberCount'],
      streamCount: json['streamCount'],
      banners: (json['banners'] as List?)
              ?.map((e) => ThumbnailModel.fromJson(e))
              .toList() ??
          [],
      donationLinks: List<String>.from(json['donationLinks'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      feedUrl: json['feedUrl'],
      tabs: (json['tabs'] as List?)
              ?.map((e) => PlaylistInfoModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'originalUrl': originalUrl,
      'service': service,
      'parentChannel': parentChannel?.toJson(),
      'avatars': avatars.map((e) => e.toJson()).toList(),
      'verified': verified,
      'description': description?.toJson(),
      'subscriberCount': subscriberCount,
      'streamCount': streamCount,
      'banners': banners.map((e) => e.toJson()).toList(),
      'donationLinks': donationLinks,
      'tags': tags,
      'feedUrl': feedUrl,
      'tabs': tabs.map((e) => e.toJson()).toList(),
    };
  }
}
