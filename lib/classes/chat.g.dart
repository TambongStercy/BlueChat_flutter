// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatAdapter extends TypeAdapter<Chat> {
  @override
  final int typeId = 0;

  @override
  Chat read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Chat(
      id: fields[0] as String,
      name: fields[1] as String,
      avatar: fields[3] as String,
      email: fields[2] as String,
      status: fields[5] as String,
      lastSeen: fields[6] as DateTime?,
      messages: (fields[7] as List).cast<MessageModel>(),
      isGroup: fields[4] as bool,
      isClosed: fields[8] as bool?,
      participants: (fields[9] as List?)?.cast<String>(),
      description: fields[10] as String?,
      onlyAdmins: fields[11] as bool?,
      adminsId: (fields[12] as List?)?.cast<String>(),
      isAsearch: fields[13] as bool?,
    )..isTyping = fields[14] as bool?;
  }

  @override
  void write(BinaryWriter writer, Chat obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.avatar)
      ..writeByte(4)
      ..write(obj.isGroup)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.lastSeen)
      ..writeByte(7)
      ..write(obj.messages)
      ..writeByte(8)
      ..write(obj.isClosed)
      ..writeByte(9)
      ..write(obj.participants)
      ..writeByte(10)
      ..write(obj.description)
      ..writeByte(11)
      ..write(obj.onlyAdmins)
      ..writeByte(12)
      ..write(obj.adminsId)
      ..writeByte(13)
      ..write(obj.isAsearch)
      ..writeByte(14)
      ..write(obj.isTyping);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
