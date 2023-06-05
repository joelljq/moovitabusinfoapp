// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'busstopclass.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BusStopClassAdapter extends TypeAdapter<BusStopClass> {
  @override
  final int typeId = 0;

  @override
  BusStopClass read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BusStopClass(
      code: fields[0] as String,
      name: fields[1] as String,
      road: fields[2] as String,
      isFavorite: fields[6] as bool,
      isAlert: fields[7] as bool,
    )
      ..lat = fields[3] as double
      ..lng = fields[4] as double
      ..distance = fields[5] as double;
  }

  @override
  void write(BinaryWriter writer, BusStopClass obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.code)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.road)
      ..writeByte(3)
      ..write(obj.lat)
      ..writeByte(4)
      ..write(obj.lng)
      ..writeByte(5)
      ..write(obj.distance)
      ..writeByte(6)
      ..write(obj.isFavorite)
      ..writeByte(7)
      ..write(obj.isAlert);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusStopClassAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
