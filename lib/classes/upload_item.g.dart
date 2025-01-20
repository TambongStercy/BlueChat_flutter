// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UploadItemAdapter extends TypeAdapter<UploadItem> {
  @override
  final int typeId = 1;

  @override
  UploadItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UploadItem(
      selectedFilePath: fields[0] as String?,
    )
      ..uploadProgress = fields[1] as double
      ..uploadStatus = fields[2] as String
      ..uploadPaused = fields[3] as bool
      ..initOffset = fields[4] as int
      ..fileId = fields[5] as String
      ..name = fields[6] as String
      ..file = fields[7] as File;
  }

  @override
  void write(BinaryWriter writer, UploadItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.selectedFilePath)
      ..writeByte(1)
      ..write(obj.uploadProgress)
      ..writeByte(2)
      ..write(obj.uploadStatus)
      ..writeByte(3)
      ..write(obj.uploadPaused)
      ..writeByte(4)
      ..write(obj.initOffset)
      ..writeByte(5)
      ..write(obj.fileId)
      ..writeByte(6)
      ..write(obj.name)
      ..writeByte(7)
      ..write(obj.file);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UploadItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
