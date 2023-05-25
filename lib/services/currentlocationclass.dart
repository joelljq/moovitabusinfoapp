class CurrentLocationClass {
  late String route;
  late double lat;
  late double lng;
// constructor
  CurrentLocationClass({
    required this.route,
    required this.lat,
    required this.lng,
  });
  //method that assign values to respective datatype variables
  CurrentLocationClass.fromJson(Map<String, dynamic> json) {
    route = json['Route'];
    lat = json['Latitude'];
    lng = json['Longitude'];
  }
}