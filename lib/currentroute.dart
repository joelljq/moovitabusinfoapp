import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as rootBundle;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:moovitainfo/services/busstopclass.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ServiceList extends StatefulWidget {
  const ServiceList({Key? key}) : super(key: key);

  @override
  _ServiceListState createState() => _ServiceListState();
}

class _ServiceListState extends State<ServiceList> {
  List<BusStopClass> _products = <BusStopClass>[];
  List<BusStopClass> finalroute2 = <BusStopClass>[];
  var finalroute = [];
  Map busnumber = {};
  int count = 0;
  late final int currentbs;
  ItemScrollController _scrollController = ItemScrollController();
  late GoogleMapController mapController; //contrller for Google map
  late String _mapStyle;
  final Set<Marker> markers = new Set();
  late BitmapDescriptor markerbitmap;
  final Set<Polyline> _polyline = {};
  List<LatLng> latlng = [];

  Future<List<BusStopClass>> ReadBusStopData() async {
    //read json file
    final jsondata =
        await rootBundle.rootBundle.loadString('jsonfile/NPStops.json');
    //decode json data as list
    var busstops = <BusStopClass>[];

    Map<String, dynamic> productsJson = json.decode(jsondata);
    for (var productJson in productsJson['value']) {
      busstops.add(BusStopClass.fromJson(productJson));
    }
    return busstops;
  }

  GetList() async {
    ReadBusStopData().then((value) {
      setState(() {
        _products.addAll(value);

        });
  }

  //

  late Timer timer;

  @override
  void initState() {
    super.initState();
    getmarkericon();
  }

  void scrollToIndex(int index) => _scrollController.scrollTo(
        index: index,
        duration: Duration(milliseconds: 900),
      );

  void updateInfoTime(index) async {
    BusStopClass instance = finalroute2[index];

    print(finalroute2[index].name);
    // navigate to home screen
    Navigator.pop(context, {
      'code': instance.code,
      'name': instance.name,
      'road': instance.road,
      'lat': instance.lat,
      'lng': instance.lng
    });
  }

  @override
  Widget build(BuildContext context) {
    busnumber = ModalRoute.of(context)!.settings.arguments as Map;
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      home: Scaffold(
        appBar: AppBar(
            centerTitle: true,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30),
            )),
            title: (finalroute2.isEmpty)
                ? Center(
                    child: SpinKitDualRing(
                      color: Colors.purple,
                      size: 10.0,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                        color: Color(0xff212121),
                        border: Border.all(color: Color(0xff000000)),
                        borderRadius: BorderRadius.all(Radius.circular(5))),
                    height: 50.0,
                    width: 300.0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: Column(
                        children: [
                          Text(
                            busnumber['ServiceNo'],
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${finalroute2.first.name} ==> ${finalroute2.last.name}',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  )),
        body: Center(
          child: finalroute2.isEmpty
              ? Center(
                  child: SpinKitDualRing(
                    color: Colors.purple,
                    size: 30.0,
                  ),
                )
              : Column(
                  children: [
                    SizedBox(
                      width: 500, // or use fixed size like 200
                      height: 300,
                      child: GoogleMap(
                        onMapCreated: (controller) {
                          //method called when map is created
                          setState(() {
                            mapController = controller;
                            mapController.setMapStyle(_mapStyle);
                          });
                        },
                        initialCameraPosition: CameraPosition(
                          target: LatLng(busnumber['lat'], busnumber['lng']),
                          zoom: 16,
                        ),
                        zoomGesturesEnabled: true,
                        markers: getmarkers(),
                        polylines: _polyline,
                      ),
                    ),
                    Expanded(
                      child: ScrollablePositionedList.builder(
                        itemCount: finalroute2.length,
                        itemScrollController: _scrollController,
                        itemBuilder: (context, index) {
                          return _listitems(index);
                        },
                      ),
                    ),
                  ],
                ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.black26,
          child: Icon(Icons.arrow_downward),
          onPressed: () => scrollToIndex(currentbs),
        ),
      ),
      // body: RefreshIndicator(
      //   onRefresh: () {
      //     return _getCurrentLocation();
      //   },
      //   child: ListView.builder(
      //     // itemCount: locations.length,
      //     itemBuilder: (context, index) {
      //       return index == 0 ? _searchBar() : _listitems(index - 1);
      //     },
      //     itemCount: _productsforDisplay.length + 1,
      //   ),
      // ),
    );
  }

  getmarkericon() async {
    markerbitmap = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(),
      "jsonfile/transport2.png",
    );
  }

  Set<Marker> getmarkers() {
    setState(() {
      for (var destination in finalroute2) {
        latlng.add(LatLng(destination.lat, destination.lng));
      }
      for (var destination in finalroute2) {
        markers.add(Marker(
            markerId: MarkerId(destination.name),
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
                    LatLng(destination.lat, destination.lng), 18));
              });
            }));
        _polyline.add(Polyline(
            polylineId: PolylineId('1'),
            points: latlng,
            color: Colors.white,
            width: 4));
      }
    });
    return markers;
  }

  _listitems(index) {
    return InkWell(
      onTap: () {
        updateInfoTime(index);
      },
      child: index == currentbs
          ? Padding(
              padding: const EdgeInsets.all(3.0),
              child: Card(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(5), // if you need this
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          height: 60.0,
                          width: 300.0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                finalroute2[index].name.toString(),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    finalroute2[index].code.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    finalroute2[index].road.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              mapController.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                      LatLng(finalroute2[index].lat,
                                          finalroute2[index].lng),
                                      18));
                            });
                            mapController.showMarkerInfoWindow(
                                MarkerId(finalroute2[index].name));
                          },
                          icon: Icon(Icons.location_on,
                              color: Colors.white, size: 30),
                        ),
                      ],
                    ),
                  )),
            )
          : Padding(
              padding: const EdgeInsets.all(3.0),
              child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5), // if you need this
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          height: 60.0,
                          width: 300.0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                finalroute2[index].name.toString(),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    finalroute2[index].code.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    finalroute2[index].road.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              mapController.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                      LatLng(finalroute2[index].lat,
                                          finalroute2[index].lng),
                                      18));
                            });
                            mapController.showMarkerInfoWindow(
                                MarkerId(finalroute2[index].name));
                          },
                          icon: Icon(Icons.location_on,
                              color: Colors.white, size: 30),
                        ),
                      ],
                    ),
                  )),
            ),
    );
  }
}
