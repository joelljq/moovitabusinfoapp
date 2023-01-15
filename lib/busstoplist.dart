import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:moovitainfo/services/busstopclass.dart';

class MyBS extends StatefulWidget {
  const MyBS({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  State<MyBS> createState() => _MyBSState();
}

class _MyBSState extends State<MyBS> {
  List<BusStopClass> bslist = [];
  late GoogleMapController mapController; //controller for Google map
  Set<Marker> markers = new Set(); //Google map markers
  late BitmapDescriptor markerbitmap;

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

  @override
  void initState() {
    ReadBusStopData().then((value) {
      setState(() {
        bslist.addAll(value);
      });
    });
    super.initState();
    getmarkericon();
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            "Moovita Bus Stops",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
          ),
          centerTitle: true,
          backgroundColor: Colors.red[400],
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          )),
        ),
        body: Align(
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
                    });
                  },
                  myLocationEnabled: true,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(1.3324019134469296, 103.7747380910866),
                    zoom: 16,
                  ),
                  markers: getmarkers(),
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
      ),
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
            padding: const EdgeInsets.all(16.0),
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
              ],
            ),
          )),
    );
  }
}
