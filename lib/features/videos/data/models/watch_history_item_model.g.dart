// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_history_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WatchHistoryItemModelAdapter extends TypeAdapter<WatchHistoryItemModel> {
  @override
  final int typeId = 2;

  @override
  WatchHistoryItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WatchHistoryItemModel(
      url: fields[0] as String,
      name: fields[1] as String?,
      watchedAt: fields[2] as DateTime,
      watchDurationSeconds: fields[3] as int,
      totalDurationSeconds: fields[4] as int,
      uploaderName: fields[5] as String?,
      uploaderUrl: fields[6] as String?,
      tags: (fields[7] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, WatchHistoryItemModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.watchedAt)
      ..writeByte(3)
      ..write(obj.watchDurationSeconds)
      ..writeByte(4)
      ..write(obj.totalDurationSeconds)
      ..writeByte(5)
      ..write(obj.uploaderName)
      ..writeByte(6)
      ..write(obj.uploaderUrl)
      ..writeByte(7)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchHistoryItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
