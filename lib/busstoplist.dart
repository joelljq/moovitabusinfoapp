import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as rootBundle;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:moovitainfo/services/busstopclass.dart';
import 'package:moovitainfo/services/routesheet.dart';

class MyBS extends StatefulWidget {
  const MyBS({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  State<MyBS> createState() => _MyBSState();
}

class _MyBSState extends State<MyBS> with TickerProviderStateMixin {
  List<BusStopClass> bsstops = [];
  List<BusStopClass> bslist = [];
  late GoogleMapController mapController;
  late GoogleMapController mapController2; //controller for Google map
  Set<Marker> markers = new Set(); //Google map markers
  late BitmapDescriptor markerbitmap;
  late Position _currentPosition;
  late TabController _tabController;
  late String _fromOption;
  late String _toOption;
  late String _darkStyle;
  String officialstyle = '[]';
  String eta = '';
  String mybs = '';
  int _fselectedIndex = 0;
  int _tselectedIndex = 1;
  PolylinePoints polylinePoints = PolylinePoints();
  Map<PolylineId, Polyline> polylines = {};
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  bool isDarkMode = false;
  late Timer geotimer;

  Future<bool> _handleLocationPermission() async {
    bool serviceready;
    LocationPermission perms;
    serviceready = await Geolocator.isLocationServiceEnabled();
    if (!serviceready) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
          Text('Location services are disabled. Please enable locations')));
      return false;
    }
    perms = await Geolocator.checkPermission();
    if (perms == LocationPermission.denied) {
      perms = await Geolocator.requestPermission();
      if (perms == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('There are no locations permission enabled')));
        return false;
      }
    }
    if (perms == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<List<BusStopClass>> ReadBusStopData() async {
    //read json file
    final jsondata =
    await rootBundle.rootBundle.loadString('jsonfile/NPStops.json');
    //decode json data as list
    var busstops = <BusStopClass>[];
    print("Success");

    Map<String, dynamic> productsJson = json.decode(jsondata);
    for (var productJson in productsJson['value']) {
      busstops.add(BusStopClass.fromJson(productJson));
    }
    final arguments = (ModalRoute.of(context)?.settings.arguments ??
        <String, dynamic>{}) as Map;
    isDarkMode = arguments['isDarkMode'];
    eta = arguments['eta'];
    mybs = arguments['mybs'];
    return busstops;
  }

  Future<void> _getCurrentLocation() async {
    await ReadBusStopData();
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    await getMyLocation();
  }

  Future<void> getMyLocation() async {
    bslist = [];
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      distanceCalculation(position);
      setState(() => _currentPosition = position);
    }).catchError((e) {
      debugPrint(e);
    });
    if (_currentPosition != null) {
      print(_currentPosition);
      print('Success');
    } else if (_currentPosition == null) {
      geotimer = Timer(Duration(seconds: 1), _getCurrentLocation);
    }
  }

  distanceCalculation(Position position) async {
    await ReadBusStopData();
    for (var d in bsstops) {
      var m = Geolocator.distanceBetween(
          position.latitude, position.longitude, d.lat, d.lng);
      d.distance = m / 1000;
      bslist.add(d);
      // print(getDistanceFromLatLonInKm(position.latitude,position.longitude, d.lat,d.lng));
    }
    setState(() {
      bslist.sort((a, b) {
        return a.distance.compareTo(b.distance);
      });
    });
  }

  late Timer timer;

  @override
  void initState() {
    ReadBusStopData().then((value) {
      setState(() {
        bsstops.addAll(value);
      });
    });
    _getCurrentLocation();
    timer =
    new Timer.periodic(Duration(seconds: 60), (_) => _getCurrentLocation());
    _tabController = TabController(vsync: this, length: 2);
    super.initState();
    rootBundle.rootBundle.loadString('jsonfile/darkgoogle.json').then((string) {
      _darkStyle = string;
    });
    getmarkericon();
    _fromOption = 'King Albert Park';
    _toOption = 'Main Entrance';
  }

  void updateInfoTime(index) async {
    setState(() {
      BusStopClass instance = bslist[index];
      Navigator.pop(context, {
        'code': instance.code,
        'name': instance.name,
        'road': instance.road,
        'lat': instance.lat,
        'lng': instance.lng
      });
    });
    print(bslist[index].name);
    // navigate to home screen
  }

  _addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      points: polylineCoordinates,
      width: 6,
      color: Colors.red,
    );
    polylines[id] = polyline;
    setState(() {});
  }

  void getPolyPoints() async {
    print("Hello");
    List<LatLng> polylineCoordinates = [];
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyCPOOzOV-23KSBWcTYgw0Jo4WxQQTjoUBM',
      PointLatLng(bslist[_fselectedIndex].lat, bslist[_fselectedIndex].lng),
      PointLatLng(bslist[_tselectedIndex].lat, bslist[_tselectedIndex].lng),
      travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }
    _addPolyLine(polylineCoordinates);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
          key: scaffoldKey,
          appBar: AppBar(
            title: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10)),
                  color: Colors.black38),
              tabs: [
                Tab(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text("BUS STOPS"),
                  ),
                ),
                Tab(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text("ROUTE"),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[400],
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                )),
          ),
          body: TabBarView(
            controller: _tabController,
            physics: NeverScrollableScrollPhysics(),
            children: [
              bslist.isEmpty
                  ? Center(
                child: SpinKitDualRing(
                  color: Colors.red,
                  size: 20.0,
                ),
              )
                  : Align(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 500, // or use fixed size like 200
                      height: 300,
                      child: GoogleMap(
                        onMapCreated: (controller) {
                          //method called when map is created
                          setState(() {
                            mapController = controller;
                            mapController.setMapStyle(_darkStyle);
                          });
                        },
                        myLocationEnabled: true,
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                              1.3324019134469296, 103.7747380910866),
                          zoom: 16,
                        ),
                        markers: getmarkers(),
                        polylines: Set<Polyline>.of(polylines.values),
                      ),
                    ),
                    Expanded(
                        child: Container(
                          child: ListView.builder(
                            itemCount: bslist.length,
                            itemBuilder: (context, index) {
                              return _listitems(index);
                            },
                          ),
                        ))
                  ],
                ),
              ),
              bslist.isEmpty
                  ? Center(
                child: SpinKitDualRing(
                  color: Colors.red,
                  size: 20.0,
                ),
              )
                  : Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: GoogleMap(
                      onMapCreated: (controller) {
                        //method called when map is created
                        setState(() {
                          mapController2 = controller;
                          mapController2.setMapStyle(_darkStyle);
                        });
                      },
                      myLocationEnabled: true,
                      initialCameraPosition: CameraPosition(
                        target:
                        LatLng(1.3324019134469296, 103.7747380910866),
                        zoom: 16,
                      ),
                      markers: getmarkers(),
                      polylines: Set<Polyline>.of(polylines.values),
                      myLocationButtonEnabled: true,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: Container(
                      margin: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.red,
                          width: 2.0,
                        ),
                        color: Colors.red[400],
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      padding: EdgeInsets.all(10),
                      child: Align(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("From",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                            SizedBox.fromSize(
                              size: Size.fromHeight(40.0),
                              child: DropdownButton<String>(
                                value: _fromOption,
                                items: bslist
                                    .map((busStop) =>
                                    DropdownMenuItem<String>(
                                      value: busStop.name,
                                      child: Text(
                                        busStop.name,
                                        style: TextStyle(
                                            fontWeight:
                                            FontWeight.bold),
                                      ),
                                    ))
                                    .toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _fromOption = newValue!;
                                    _fselectedIndex = bslist.indexOf(
                                        bslist.firstWhere((busStop) =>
                                        busStop.name == _fromOption));
                                    mapController2.animateCamera(
                                        CameraUpdate.newLatLngZoom(
                                            LatLng(
                                                bslist[_fselectedIndex]
                                                    .lat,
                                                bslist[_fselectedIndex]
                                                    .lng),
                                            16));
                                    mapController2.showMarkerInfoWindow(
                                        MarkerId(
                                            '${bslist[_fselectedIndex].name} ${bslist[_fselectedIndex].road}'));
                                  });
                                },
                              ),
                            ),
                            // add other widget as child of column
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 90,
                    child: Container(
                      margin: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.red,
                          width: 2.0,
                        ),
                        color: Colors.red[400],
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      padding: EdgeInsets.all(10),
                      child: Align(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("To",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                            SizedBox.fromSize(
                              size: Size.fromHeight(40.0),
                              child: DropdownButton<String>(
                                value: _toOption,
                                items: bslist
                                    .map((busStop) =>
                                    DropdownMenuItem<String>(
                                      value: busStop.name,
                                      child: Text(
                                        busStop.name,
                                        style: TextStyle(
                                            fontWeight:
                                            FontWeight.bold),
                                      ),
                                    ))
                                    .toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _toOption = newValue!;
                                    _tselectedIndex = bslist.indexOf(
                                        bslist.firstWhere((busStop) =>
                                        busStop.name == _toOption));
                                    mapController2.animateCamera(
                                        CameraUpdate.newLatLngZoom(
                                            LatLng(
                                                bslist[_tselectedIndex]
                                                    .lat,
                                                bslist[_tselectedIndex]
                                                    .lng),
                                            16));
                                    mapController2.showMarkerInfoWindow(
                                        MarkerId(
                                            '${bslist[_tselectedIndex].name} ${bslist[_tselectedIndex].road}'));
                                  });
                                },
                              ),
                            ),
                            // add other widget as child of column
                          ],
                        ),
                      ),
                    ),
                  ),
                  Builder(builder: (context) {
                    return Positioned(
                      left: 50,
                      right: 50,
                      top: 200,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.red[400],
                          backgroundColor: Colors.white,
                        ),
                        onPressed: () {
                          if (_fromOption == _toOption) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red,
                                content: Text(
                                  'Please select two different points',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                duration:
                                const Duration(milliseconds: 1500),
                                width: 280.0,
                                // Width of the SnackBar.
                                padding: const EdgeInsets.symmetric(
                                  horizontal:
                                  8.0, // Inner padding for SnackBar content.
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(10.0),
                                ),
                              ),
                            );
                          } else {
                            setState(() {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => BottomSheetWidget(
                                  key: UniqueKey(),
                                  string1: bslist[_fselectedIndex].code,
                                  string2: bslist[_tselectedIndex].code,
                                  string3: eta,
                                  string4: mybs,
                                ),
                              );
                              getPolyPoints();
                              mapController2.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                      LatLng(bslist[_fselectedIndex].lat,
                                          bslist[_fselectedIndex].lng),
                                      16));
                            });
                          }
                        },
                        child: const Text('Enter Route'),
                      ),
                    );
                  })
                ],
              )
            ],
          )),
    );
  }

  getmarkericon() async {
    markerbitmap = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(),
      "jsonfile/transport1.png",
    );
  }

  Set<Marker> getmarkers() {
    setState(() {
      for (var destination in bslist) {
        markers.add(Marker(
            markerId: MarkerId('${destination.name} ${destination.road}'),
            position: LatLng(destination.lat, destination.lng),

            //position of marker
            infoWindow: InfoWindow(
              //popup info
              title: destination.name,
              snippet: "${destination.code} ${destination.road}",
              onTap: () {
                BusStopClass instance = destination;
                Navigator.pop(context, {
                  'code': instance.code,
                  'name': instance.name,
                  'road': instance.road,
                  'lat': instance.lat,
                  'lng': instance.lng
                });
              },
            ),
            icon: markerbitmap,
            onTap: () {
              setState(() {
                mapController.animateCamera(CameraUpdate.newLatLngZoom(
                    LatLng(destination.lat, destination.lng), 17));
              });
            }));
      }
    });
    return markers;
  }

  _listitems(index) {
    return InkWell(
      onTap: () {
        updateInfoTime(index);
      },
      child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5), // if you need this
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bslist[index].name.toString(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        // color: Colors.red[400],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          bslist[index].code.toString(),
                          style: TextStyle(
                            // color: Colors.purpleAccent[200],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          bslist[index].road.toString(),
                          style: TextStyle(
                            // color: Colors.purpleAccent[200],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Expanded(
                  child: SizedBox(),
                ),
                Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          mapController.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                  LatLng(bslist[index].lat, bslist[index].lng),
                                  16));
                        });
                        mapController.showMarkerInfoWindow(MarkerId(
                            '${bslist[index].name} ${bslist[index].road}'));
                      },
                      icon: Icon(Icons.location_on,
                          color: Colors.black, size: 30),
                    ),
                    Text(
                      '${bslist[index].distance.toStringAsFixed(2)}km',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        // color: Colors.purpleAccent[400],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
    );
  }
}
