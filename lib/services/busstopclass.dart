class BusStopClass {
  late String code;
  late String name;
  late String road;
  late double lat;
  late double lng;
  late double distance;
// constructor
  BusStopClass({
    required this.code,
    required this.name,
    required this.road,
  });
  //method that assign values to respective datatype variables
  BusStopClass.fromJson(Map<String, dynamic> json) {
    code = json['BusStopCode'];
    name = json['Description'];
    road = json['RoadName'];
    lat = json['Latitude'];
    lng = json['Longitude'];
  }
}
