// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecommendationItemModelAdapter
    extends TypeAdapter<RecommendationItemModel> {
  @override
  final int typeId = 0;

  @override
  RecommendationItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecommendationItemModel(
      url: fields[0] as String,
      name: fields[1] as String?,
      service: fields[2] as String?,
      thumbnailUrls: (fields[3] as List).cast<String>(),
      duration: fields[4] as int?,
      views: fields[5] as int?,
      uploaderName: fields[6] as String?,
      uploaderUrl: fields[7] as String?,
      score: fields[8] as double,
      addedAt: fields[9] as DateTime,
      source: fields[10] as RecommendationSource,
    );
  }

  @override
  void write(BinaryWriter writer, RecommendationItemModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.service)
      ..writeByte(3)
      ..write(obj.thumbnailUrls)
      ..writeByte(4)
      ..write(obj.duration)
      ..writeByte(5)
      ..write(obj.views)
      ..writeByte(6)
      ..write(obj.uploaderName)
      ..writeByte(7)
      ..write(obj.uploaderUrl)
      ..writeByte(8)
      ..write(obj.score)
      ..writeByte(9)
      ..write(obj.addedAt)
      ..writeByte(10)
      ..write(obj.source);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecommendationSourceAdapter extends TypeAdapter<RecommendationSource> {
  @override
  final int typeId = 1;

  @override
  RecommendationSource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecommendationSource.watchHistory;
      case 1:
        return RecommendationSource.streamRecommendations;
      case 2:
        return RecommendationSource.searchResults;
      case 3:
        return RecommendationSource.catalog;
      case 4:
        return RecommendationSource.channelBased;
      case 5:
        return RecommendationSource.other;
      default:
        return RecommendationSource.watchHistory;
    }
  }

  @override
  void write(BinaryWriter writer, RecommendationSource obj) {
    switch (obj) {
      case RecommendationSource.watchHistory:
        writer.writeByte(0);
        break;
      case RecommendationSource.streamRecommendations:
        writer.writeByte(1);
        break;
      case RecommendationSource.searchResults:
        writer.writeByte(2);
        break;
      case RecommendationSource.catalog:
        writer.writeByte(3);
        break;
      case RecommendationSource.channelBased:
        writer.writeByte(4);
        break;
      case RecommendationSource.other:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
