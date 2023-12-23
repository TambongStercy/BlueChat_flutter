// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageModelAdapter extends TypeAdapter<MessageModel> {
  @override
  final int typeId = 1;

  @override
  MessageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageModel(
      id: fields[10] as String,
      sender: fields[0] as String,
      message: fields[1] as String,
      time: fields[2] as String,
      date: fields[3] as DateTime,
      isMe: fields[4] as bool,
      type: fields[5] as MessageType,
      status: fields[12] as MessageStatus,
      chatID: fields[14] as String,
      size: fields[13] as int?,
      index: fields[8] as int?,
      initOffset: fields[15] as int?,
      decibels: (fields[9] as List?)?.cast<double>(),
      filePath: fields[7] as String?,
      repliedToId: fields[11] as String?,
    )..read = fields[6] as bool;
  }

  @override
  void write(BinaryWriter writer, MessageModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.sender)
      ..writeByte(1)
      ..write(obj.message)
      ..writeByte(2)
      ..write(obj.time)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.isMe)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.read)
      ..writeByte(7)
      ..write(obj.filePath)
      ..writeByte(8)
      ..write(obj.index)
      ..writeByte(9)
      ..write(obj.decibels)
      ..writeByte(10)
      ..write(obj.id)
      ..writeByte(11)
      ..write(obj.repliedToId)
      ..writeByte(12)
      ..write(obj.status)
      ..writeByte(13)
      ..write(obj.size)
      ..writeByte(14)
      ..write(obj.chatID)
      ..writeByte(15)
      ..write(obj.initOffset);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MessageTypeAdapter extends TypeAdapter<MessageType> {
  @override
  final int typeId = 2;

  @override
  MessageType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MessageType.text;
      case 1:
        return MessageType.image;
      case 2:
        return MessageType.video;
      case 3:
        return MessageType.audio;
      case 4:
        return MessageType.voice;
      case 5:
        return MessageType.files;
      default:
        return MessageType.text;
    }
  }

  @override
  void write(BinaryWriter writer, MessageType obj) {
    switch (obj) {
      case MessageType.text:
        writer.writeByte(0);
        break;
      case MessageType.image:
        writer.writeByte(1);
        break;
      case MessageType.video:
        writer.writeByte(2);
        break;
      case MessageType.audio:
        writer.writeByte(3);
        break;
      case MessageType.voice:
        writer.writeByte(4);
        break;
      case MessageType.files:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MessageStatusAdapter extends TypeAdapter<MessageStatus> {
  @override
  final int typeId = 3;

  @override
  MessageStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MessageStatus.sending;
      case 1:
        return MessageStatus.sent;
      case 2:
        return MessageStatus.received;
      case 3:
        return MessageStatus.seen;
      default:
        return MessageStatus.sending;
    }
  }

  @override
  void write(BinaryWriter writer, MessageStatus obj) {
    switch (obj) {
      case MessageStatus.sending:
        writer.writeByte(0);
        break;
      case MessageStatus.sent:
        writer.writeByte(1);
        break;
      case MessageStatus.received:
        writer.writeByte(2);
        break;
      case MessageStatus.seen:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
