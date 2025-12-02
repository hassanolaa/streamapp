import 'package:streamapp/features/videos/data/models/formatted_text_model.dart';
import 'package:streamapp/features/videos/data/models/thumbnail_model.dart';

class ChannelSummaryModel {
  final String? name;
  final String? url;
  final List<ThumbnailModel> thumbnails;
  final String? service;
  final bool? verified;
  final FormattedTextModel? description;
  final int? subscriberCount;
  final int? streamCount;

  ChannelSummaryModel({
    this.name,
    this.url,
    required this.thumbnails,
    this.service,
    this.verified,
    this.description,
    this.subscriberCount,
    this.streamCount,
  });

  factory ChannelSummaryModel.fromJson(Map<String, dynamic> json) {
    return ChannelSummaryModel(
      name: json['name'],
      url: json['url'],
      thumbnails: (json['thumbnails'] as List?)
              ?.map((e) => ThumbnailModel.fromJson(e))
              .toList() ??
          [],
      service: json['service'],
      verified: json['verified'],
      description: json['description'] != null
          ? FormattedTextModel.fromJson(json['description'])
          : null,
      subscriberCount: json['subscriberCount'],
      streamCount: json['streamCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'thumbnails': thumbnails.map((e) => e.toJson()).toList(),
      'service': service,
      'verified': verified,
      'description': description?.toJson(),
      'subscriberCount': subscriberCount,
      'streamCount': streamCount,
    };
  }
}

class StreamSummaryModel {
  final String? name;
  final String? url;
  final List<ThumbnailModel> thumbnails;
  final String? service;
  final String? streamType; // "AUDIO", "VIDEO", "AUDIO_LIVE", "VIDEO_LIVE", etc.
  final int? duration;
  final int? views;
  final int? uploadDateUnixEpoch;
  final FormattedTextModel? description;
  final ChannelSummaryModel? uploader;

  StreamSummaryModel({
    this.name,
    this.url,
    required this.thumbnails,
    this.service,
    this.streamType,
    this.duration,
    this.views,
    this.uploadDateUnixEpoch,
    this.description,
    this.uploader,
  });

  factory StreamSummaryModel.fromJson(Map<String, dynamic> json) {
    return StreamSummaryModel(
      name: json['name'],
      url: json['url'],
      thumbnails: (json['thumbnails'] as List?)
              ?.map((e) => ThumbnailModel.fromJson(e))
              .toList() ??
          [],
      service: json['service'],
      streamType: json['streamType'],
      duration: json['duration'],
      views: json['views'],
      uploadDateUnixEpoch: json['uploadDateUnixEpoch'],
      description: json['description'] != null
          ? FormattedTextModel.fromJson(json['description'])
          : null,
      uploader: json['uploader'] != null
          ? ChannelSummaryModel.fromJson(json['uploader'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'thumbnails': thumbnails.map((e) => e.toJson()).toList(),
      'service': service,
      'streamType': streamType,
      'duration': duration,
      'views': views,
      'uploadDateUnixEpoch': uploadDateUnixEpoch,
      'description': description?.toJson(),
      'uploader': uploader?.toJson(),
    };
  }
}

class PlaylistSummaryModel {
  final String? name;
  final String? url;
  final List<ThumbnailModel> thumbnails;
  final String? service;
  final ChannelSummaryModel? uploader;
  final int? streamCount;
  final FormattedTextModel? description;
  final String? playlistType; // "NORMAL", "MIX_VIDEO", "MIX_MUSIC", "MIX_MUSIC_GENRE"

  PlaylistSummaryModel({
    this.name,
    this.url,
    required this.thumbnails,
    this.service,
    this.uploader,
    this.streamCount,
    this.description,
    this.playlistType,
  });

  factory PlaylistSummaryModel.fromJson(Map<String, dynamic> json) {
    return PlaylistSummaryModel(
      name: json['name'],
      url: json['url'],
      thumbnails: (json['thumbnails'] as List?)
              ?.map((e) => ThumbnailModel.fromJson(e))
              .toList() ??
          [],
      service: json['service'],
      uploader: json['uploader'] != null
          ? ChannelSummaryModel.fromJson(json['uploader'])
          : null,
      streamCount: json['streamCount'],
      description: json['description'] != null
          ? FormattedTextModel.fromJson(json['description'])
          : null,
      playlistType: json['playlistType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'thumbnails': thumbnails.map((e) => e.toJson()).toList(),
      'service': service,
      'uploader': uploader?.toJson(),
      'streamCount': streamCount,
      'description': description?.toJson(),
      'playlistType': playlistType,
    };
  }
}

// Union type handler for polymorphic Summary types
class SummaryModel {
  final String type; // "stream", "playlist", "channel"
  final dynamic data; // StreamSummaryModel, PlaylistSummaryModel, or ChannelSummaryModel

  SummaryModel({required this.type, required this.data});

  factory SummaryModel.fromJson(Map<String, dynamic> json) {
    // Handle Kotlin sealed class serialization format
    if (json.containsKey('stream')) {
      return SummaryModel(
        type: 'stream',
        data: StreamSummaryModel.fromJson(json['stream']),
      );
    } else if (json.containsKey('playlist')) {
      return SummaryModel(
        type: 'playlist',
        data: PlaylistSummaryModel.fromJson(json['playlist']),
      );
    } else if (json.containsKey('channel')) {
      return SummaryModel(
        type: 'channel',
        data: ChannelSummaryModel.fromJson(json['channel']),
      );
    }
    
    // Fallback: try to detect type from fields
    if (json.containsKey('streamType') || json.containsKey('duration')) {
      return SummaryModel(
        type: 'stream',
        data: StreamSummaryModel.fromJson(json),
      );
    } else if (json.containsKey('playlistType')) {
      return SummaryModel(
        type: 'playlist',
        data: PlaylistSummaryModel.fromJson(json),
      );
    } else if (json.containsKey('subscriberCount')) {
      return SummaryModel(
        type: 'channel',
        data: ChannelSummaryModel.fromJson(json),
      );
    }

    // Default to stream
    return SummaryModel(
      type: 'stream',
      data: StreamSummaryModel.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data.toJson(),
    };
  }
}
