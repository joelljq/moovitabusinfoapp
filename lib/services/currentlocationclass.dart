class CurrentLocationClass {
  late String Route;
  late double lat;
  late double lng;
// constructor
  CurrentLocationClass({
    required this.Route,
    required this.lat,
    required this.lng
  });
  //method that assign values to respective datatype variables
  CurrentLocationClass.fromJson(Map<String, dynamic> json) {
    Route = json['Route'];
    lat = double.parse(json['Latitude'].toString());
    lng = double.parse(json['Longitude'].toString());
  }
}