import 'dart:async';
import 'package:flutter_google_places_web/flutter_google_places_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:moovitainfo/services/busstopclass.dart';
import 'package:moovitainfo/services/notif.dart';

class RouteScreen extends StatefulWidget {
  String darkStyle;
  BusStopClass busstop;
  LatLng curpos;
  List<BusStopClass> bslist;
  int currentbusindex;
  int ETA;
  BitmapDescriptor markerbitmap;
  BitmapDescriptor markerbitmap2;
  Function(BusStopClass) addtoFavorites;
  Function(BusStopClass) removeFromFavorites;

  RouteScreen(
      {Key? key,
        required this.darkStyle,
        required this.busstop,
        required this.curpos,
        required this.bslist,
        required this.currentbusindex,
        required this.ETA,
        required this.markerbitmap,
        required this.markerbitmap2,
        required this.addtoFavorites,
        required this.removeFromFavorites})
      : super(key: key);

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  late String darkStyle = widget.darkStyle;
  late GoogleMapController mapController;
  late BusStopClass busstop = widget.busstop;
  late BitmapDescriptor markerbitmap = widget.markerbitmap;
  late BitmapDescriptor markerbitmap2 = widget.markerbitmap2;
  late LatLng curpos;
  late List<BusStopClass> bslist;
  late int currentbusindex;
  late int etaa;
  int currentETA = 0;
  Set<Marker> markers = new Set();

  Future<void> _showAutocomplete(TextEditingController controller) async {
    Prediction? prediction = await PlacesAutocomplete.show(
      context: context,
      apiKey: 'YOUR_GOOGLE_MAPS_API_KEY',
      mode: Mode.overlay,
      language: "en",
      components: [Component(Component.country, "sg")],
      locationRestriction: LocationRestriction(
        radius: 10000, // Set the desired radius in meters
        lat: 1.3424, // Latitude of a central point
        lng: 103.6810, // Longitude of a central point
      ),
    );

    if (prediction != null) {
      controller.text = prediction.description!;
    }
  }

  String status(int currentcode) {
    int index = 0;
    int diff = 0;
    index = currentcode;
    String Status = '';
    diff = index - currentbusindex;

    etaa = widget.ETA;
    if (diff > 1) {
      etaa = etaa + (3 * diff);
      Status = "${etaa.toString()} mins";
    } else if (diff < 0) {
      etaa = etaa + (3 * (11 + diff));
      Status = "${etaa.toString()} mins";
    } else if (diff == 0) {
      if (etaa > 0) {
        Status = "${etaa.toString()} mins";
      } else {
        Status = "Arrived";
      }
    } else if (diff == 1) {
      etaa = etaa + 3;
      Status = "${etaa.toString()} mins";
    }
    return Status;
  }

  int indexeta(int currentcode) {
    int index = 0;
    int diff = 0;
    index = currentcode;
    diff = index - currentbusindex;
    etaa = widget.ETA;
    if (diff > 1) {
      etaa = etaa + (3 * diff);
    } else if (diff < 0) {
      etaa = etaa + (3 * (11 + diff));
    } else if (diff == 0) {
      if (etaa > 0) {
      } else {
        etaa = 0;
      }
    } else if (diff == 1) {
      etaa = etaa + 3;
    }
    return etaa;
  }

  late Timer updatetimer;

  @override
  void initState() {
    super.initState();
    updatevalues();
    updatetimer = new Timer.periodic(Duration(seconds: 1), (_) {
      updatevalues();
    });
  }

  late Timer indextimer;

  void startTimer(int index) {
    indextimer = Timer.periodic(Duration(seconds: 1), (_) {
      // Fetch the current ETA for the selected bus stop
      final newETA = indexeta(int.parse(bslist[index].code));
      if (newETA != currentETA) {
        currentETA = newETA;
        if (currentETA == 0) {
          // Trigger the alert when ETA reaches 0
          indextimer.cancel();
          NotificationService().showNotification(
              title: "Bus Alert System",
              body: "Bus has arrived at ${bslist[index].name}!",
              enableSound: true); // Stop the timer after the alert
          bslist[index].isAlert = false;
        } else {
          NotificationService().showNotification(
              title: "Bus Alert System",
              body:
              "Bus is arriving at ${bslist[index].name} in ${currentETA}min",
              isSilent: true,
              enableSound: false);
        }
      }
    });
  }

  updatevalues() {
    setState(() {
      curpos = widget.curpos;
      bslist = widget.bslist;
      currentbusindex = widget.currentbusindex;
      etaa = widget.ETA;
    });
  }

  @override
  Widget build(BuildContext context) {
    return markerbitmap == null
        ? Center(
      child: SpinKitDualRing(
        color: Colors.red,
        size: 20.0,
      ),
    )
        : Column(
      children: [
        Stack(
          children: [
            SizedBox(
              width: 500, // or use fixed size like 200
              height: 350,
              child: GoogleMap(
                onMapCreated: (controller) {
                  //method called when map is created
                  setState(() {
                    mapController = controller;
                    mapController.setMapStyle(darkStyle);
                  });
                },
                initialCameraPosition: CameraPosition(
                  target: LatLng(busstop.lat, busstop.lng),
                  zoom: 16,
                ),
                markers: getmarkers(),
                myLocationButtonEnabled: true,
                myLocationEnabled: true,
              ),
            ),
            Positioned(
              top: 30,
              left: 100,
              right: 100,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "${busstop.name}",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Positioned(
              top:30,
              left:10,
              child: InkWell(
                onTap: () {
                  // Handle the onTap event
                  // Add your desired functionality here
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'jsonfile/Moovita1.png', // Replace with your image path
                    width: 40,
                    height: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: Container(
            child: ListView.builder(
              itemCount: bslist.length,
              itemBuilder: (context, index) {
                return _listitems(index);
              },
            ),
          ),
        ),
      ],
    );
  }

  _listitems(index) {
    return ExpansionTile(
      collapsedBackgroundColor: Colors.white,
      // Set the background color of the collapsed tile
      backgroundColor: Colors.white,
      // Set the background color of the expanded tile
      title: Row(
        children: [
          Text(
            bslist[index].name.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.favorite,
              color: bslist[index].isFavorite ? Colors.red : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                bslist[index].isFavorite = !bslist[index].isFavorite;
                if(bslist[index].isFavorite == true){
                  widget.addtoFavorites(bslist[index]);
                }
                else if(bslist[index].isFavorite == false){
                  widget.removeFromFavorites(bslist[index]);
                }
              });
            },
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Text(
            bslist[index].code.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 10),
          Text(
            bslist[index].road.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      children: [
        Card(
          child: Row(
            children: [
              Container(
                width: 10,
                color: Colors.blue,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'ETA: ${status(int.parse(bslist[index].code))}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.notifications,
                  color: bslist[index].isAlert ? Colors.red : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    bslist[index].isAlert = !bslist[index].isAlert;
                    if (bslist[index].isAlert == true) {
                      startTimer(index);
                    } else {
                      indextimer.cancel();
                    }
                  });
                },
              ),
            ],
          ),
        )
      ],
      onExpansionChanged: (isExpanded) {
        // Handle the onExpansionChanged event here
        if (isExpanded) {
          busstop = bslist[index];
          mapController.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(busstop.lat, busstop.lng), 16));
        }
      },
    );
  }

  Set<Marker> getmarkers() {
    markers = new Set();
    setState(() {
      markers = new Set();
      markers.add(Marker(
          markerId: MarkerId(busstop.name),
          position: LatLng(busstop.lat, busstop.lng),
          //position of marker
          infoWindow: InfoWindow(
            //popup info
              title: busstop.name,
              snippet: "${busstop.code} ${busstop.road}"),
          icon: markerbitmap,
          onTap: () {
            setState(() {
              mapController.animateCamera(CameraUpdate.newLatLngZoom(
                  LatLng(busstop.lat, busstop.lng), 18));
            });
          }));
      markers.add(Marker(
          markerId: MarkerId("CurrentBusPos"),
          position: curpos,
          //position of marker
          infoWindow: InfoWindow(
            //popup info
              title: "Current Bus Location ${currentbusindex}",
              snippet: "${widget.ETA}"),
          icon: markerbitmap2,
          onTap: () {
            setState(() {
              mapController
                  .animateCamera(CameraUpdate.newLatLngZoom(curpos, 14));
            });
          }));
    });
    return markers;
  }
}
