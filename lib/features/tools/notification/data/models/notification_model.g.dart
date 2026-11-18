// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

class NotificationModelAdapter extends TypeAdapter<NotificationModel> {
  @override
  final int typeId = 0;

  @override
  NotificationModel read(BinaryReader reader) {
    return NotificationModel(
      title: reader.readString(),
      body: reader.readString(),
      date: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, NotificationModel obj) {
    writer.writeString(obj.title);
    writer.writeString(obj.body);
    writer.writeString(obj.date.toIso8601String());
  }
}
