import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:moovitainfo/services/busstopclass.dart';
import 'package:moovitainfo/services/notif.dart';

class FavScreen extends StatefulWidget {
  String darkStyle;
  BusStopClass busstop;
  LatLng curpos;
  List<BusStopClass> bslist;
  int currentbusindex;
  int ETA;
  BitmapDescriptor markerbitmap;
  BitmapDescriptor markerbitmap2;

  FavScreen({Key? key,
    required this.darkStyle,
    required this.busstop,
    required this.curpos,
    required this.bslist,
    required this.currentbusindex,
    required this.ETA,
    required this.markerbitmap,
    required this.markerbitmap2})
      : super(key: key);

  @override
  State<FavScreen> createState() => _FavScreenState();
}

class _FavScreenState extends State<FavScreen> {
  late String darkStyle;
  late GoogleMapController mapController;
  late BusStopClass busstop;
  late BitmapDescriptor markerbitmap;
  late BitmapDescriptor markerbitmap2;
  late LatLng curpos;
  late List<BusStopClass> bslist;
  late int currentbusindex;
  late int etaa;
  int currentETA = 0;
  Set<Marker> markers = new Set();

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
      if(newETA != currentETA){
        currentETA = newETA;
        if (currentETA == 0) {// Trigger the alert when ETA reaches 0
          indextimer.cancel();
          NotificationService().showNotification(title: "Bus Alert System", body: "Bus has arrived at ${bslist[index].name}!", enableSound: true);// Stop the timer after the alert
          bslist[index].isAlert = false;
        }
        else{
          NotificationService().showNotification(title: "Bus Alert System", body: "Bus is arriving at ${bslist[index].name} in ${currentETA}min", isSilent: true, enableSound: false);
        }
      }
    });
  }

  updatevalues(){
    setState(() {
      darkStyle = widget.darkStyle;
      busstop = widget.busstop;
      markerbitmap = widget.markerbitmap;
      markerbitmap2 = widget.markerbitmap2;
      curpos = widget.curpos;
      bslist = widget.bslist;
      currentbusindex = widget.currentbusindex;
      etaa = widget.ETA;
    });
  }

  @override
  Widget build(BuildContext context) {
    return markerbitmap == null ? Center(
      child: SpinKitDualRing(
        color: Colors.red,
        size: 20.0,
      ),
    ): Column(
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
    return InkWell(
        onTap: () {
          busstop = bslist[index];
        },
        child: ExpansionTile(
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
                      child: Text('ETA: ${status(int.parse(bslist[index].code))}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications, color: bslist[index].isAlert ? Colors.red : Colors.grey,),
                    onPressed: () {
                      setState(() {
                        bslist[index].isAlert = !bslist[index].isAlert;
                        if(bslist[index].isAlert == true){
                          startTimer(index);
                        }
                        else{
                          indextimer.cancel();
                        }
                      });
                    },
                  ),
                ],
              ),
            )
          ],
        ));
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
