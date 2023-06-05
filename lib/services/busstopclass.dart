import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'busstopclass.g.dart';

@HiveType(typeId: 0)
class BusStopClass extends HiveObject {
  @HiveField(0)
  late String code;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String road;

  @HiveField(3)
  late double lat;

  @HiveField(4)
  late double lng;

  @HiveField(5)
  late double distance;

  @HiveField(6)
  late bool isFavorite;

  @HiveField(7)
  late bool isAlert;

  BusStopClass({
    required this.code,
    required this.name,
    required this.road,
    this.isFavorite = false,
    this.isAlert = false,
  });

  BusStopClass.fromJson(Map<String, dynamic> json) {
    code = json['BusStopCode'];
    name = json['Description'];
    road = json['RoadName'];
    lat = json['Latitude'];
    lng = json['Longitude'];
    isFavorite = false;
    isAlert = false;
  }
}

