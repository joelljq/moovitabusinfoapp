import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:moovitainfo/services/busstopclass.dart';

class BSScreen extends StatefulWidget {
  final String darkStyle;
  final BusStopClass busstop;
  final LatLng curpos;
  final List<BusStopClass> bslist;
  final int currentbusindex;
  final int ETA;
  final BitmapDescriptor markerbitmap;
  final BitmapDescriptor markerbitmap2;

  const BSScreen({Key? key,
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
  State<BSScreen> createState() => _BSScreenState();
}

class _BSScreenState extends State<BSScreen> {
  late String darkStyle;
  late GoogleMapController mapController;
  late BusStopClass busstop;
  late BitmapDescriptor markerbitmap;
  late BitmapDescriptor markerbitmap2;
  late LatLng curpos;
  late List<BusStopClass> bslist;
  late int currentbusindex;
  late int etaa;
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
  late Timer updatetimer;
  @override
  void initState() {
    super.initState();
    updatetimer = new Timer.periodic(Duration(seconds: 1), (_) {
      updatevalues();
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
          title: Text(
            bslist[index].name.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
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
                    width: 5,
                    color: Colors.blue,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('ETA: ${status(int.parse(bslist[index].code))}'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () {},
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
              title: "Current Bus Location",
              snippet: "${status(int.parse(busstop.code))}"),
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
