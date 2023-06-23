import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:moovitainfo/services/busstopclass.dart';
import 'package:moovitainfo/services/notif.dart';

class BSScreen extends StatefulWidget {
  Function(String, String) sendMessage;
  bool style;
  String darkStyle;
  BusStopClass busstop;
  LatLng curpos;
  List<BusStopClass> bslist;
  int currentbusindex;
  int ETA;
  Color busstatus;
  BitmapDescriptor markerbitmap;
  BitmapDescriptor markerbitmap2;
  Function(BusStopClass) addtoFavorites;
  Function(BusStopClass) removeFromFavorites;
  final VoidCallback setstyle;
  Function(String) startNotif;
  Function(String) cancelNotif;
  GlobalKey<ScaffoldState> scaffoldkey;

  BSScreen(
      {Key? key,
        required this.startNotif,
        required this.cancelNotif,
        required this.sendMessage,
      required this.scaffoldkey,
      required this.busstatus,
      required this.setstyle,
      required this.style,
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
  State<BSScreen> createState() => _BSScreenState();
}

class _BSScreenState extends State<BSScreen> {
  late String darkStyle = widget.darkStyle;
  late GoogleMapController mapController;
  late BusStopClass busstop = widget.busstop;
  late BitmapDescriptor markerbitmap = widget.markerbitmap;
  late BitmapDescriptor markerbitmap2 = widget.markerbitmap2;
  late LatLng curpos;
  late List<BusStopClass> bslist;
  late int currentbusindex;
  late int etaa;
  late bool style;
  late Color background;
  late Color primary;
  late Color busstatus;
  late GlobalKey<ScaffoldState> _scaffoldKey = widget.scaffoldkey;
  int currentETA = 0;
  Set<Marker> markers = new Set();


  String mapstyle() {
    String mapstyle;
    if (style == false) {
      mapstyle = "[]";
    } else {
      mapstyle = darkStyle;
    }
    return mapstyle;
  }

  String status(int currentcode) {
    int index = 0;
    int diff = 0;
    index = currentcode;
    String Status = '';
    diff = index - currentbusindex;

    etaa = widget.ETA;
    if (etaa == -1) {
      Status = "Not Operating";
    } else if (diff > 1) {
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
    inputvalues();
    updatetimer = new Timer.periodic(Duration(seconds: 1), (_) {
      updatevalues();
    });
  }

  @override
  void dispose() {
    super.dispose();
    updatetimer.cancel();
  }

  late Timer indextimer;

  List<Timer> timers = List<Timer>.filled(11, Timer(Duration.zero, () {}));

  // void startTimer(int index) {// Declare the timer variable outside the function
  //   List<int> newETAList = List<int>.filled(11, 0);
  //   List<int> currentETAList = List<int>.filled(11, 0);
  //   timers[index] = Timer.periodic(Duration(seconds: 1), (_){
  //     newETAList[index] = indexeta(int.parse(bslist[index].code));
  //     if (newETAList[index] != currentETAList[index]) {
  //       currentETAList[index] = newETAList[index];
  //       if (currentETAList[index] == 0) {
  //         NotificationService().showNotification(
  //           title: "Bus Alert System",
  //           body: "Bus has arrived at ${bslist[index].name}!",
  //           enableSound: true,
  //           isSilent: false,
  //         );
  //         bslist[index].isAlert = false;
  //         timers[index].cancel();
  //       } else {
  //         NotificationService().showNotification(
  //           title: "Bus Alert System",
  //           body: "Bus is arriving at ${bslist[index].name} in ${currentETAList[index]}min",
  //           enableSound: false,
  //           isSilent: true,
  //         );
  //       }
  //     }
  //     else{
  //       if (newETAList[index] == 0) {
  //         NotificationService().showNotification(
  //           title: "Bus Alert System",
  //           body: "Bus has arrived at ${bslist[index].name}!",
  //           enableSound: true,
  //           isSilent: false,
  //         );
  //         bslist[index].isAlert = false;
  //         timers[index].cancel();
  //       }
  //     }
  //   });
  // }


  updatevalues() {
    setState(() {
      busstatus = widget.busstatus;
      curpos = widget.curpos;
      bslist = widget.bslist;
      currentbusindex = widget.currentbusindex;
      etaa = widget.ETA;
      style = widget.style;
      mapController.setMapStyle(mapstyle());
      background = style == false ? Colors.white : Colors.black;
      primary = style == true ? Colors.white : Colors.black;
    });
  }

  inputvalues() {
    setState(() {
      busstatus = widget.busstatus;
      curpos = widget.curpos;
      bslist = widget.bslist;
      currentbusindex = widget.currentbusindex;
      etaa = widget.ETA;
      style = widget.style;
      background = style == false ? Colors.white : Colors.black;
      primary = style == true ? Colors.white : Colors.black;
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
                    height: 400,
                    child: GoogleMap(
                      onMapCreated: (controller) {
                        //method called when map is created
                        setState(() {
                          mapController = controller;
                          mapController.setMapStyle(mapstyle());
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
                    child: SafeArea(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            "${busstop.name}",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 30,
                    left: 10,
                    child: SafeArea(
                      child: InkWell(
                        onTap: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: background,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'jsonfile/moovita2.png', // Replace with your image path
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
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
    return Theme(
      data: style ? ThemeData.dark() : ThemeData.light(),
      child: InkWell(
        onTap: () {
          mapController.animateCamera(CameraUpdate.newLatLngZoom(curpos, 16));
        },
        child: ExpansionTile(
          collapsedBackgroundColor: background,
          // Set the background color of the collapsed tile
          backgroundColor: background,
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
                    if (bslist[index].isFavorite == true) {
                      widget.addtoFavorites(bslist[index]);
                    } else if (bslist[index].isFavorite == false) {
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
                    height: 50,
                    decoration: BoxDecoration(
                      color: busstatus,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'ETA: ${status(int.parse(bslist[index].code))}',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
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
                        if (bslist[index].isAlert == false){
                          widget.sendMessage(bslist[index].code, "Yes");
                        }
                        else{
                          widget.sendMessage(bslist[index].code, "No");
                        }
                        bslist[index].isAlert = !bslist[index].isAlert;
                        if (bslist[index].isAlert == true) {
                          widget.startNotif(bslist[index].code);
                        } else {
                          widget.cancelNotif(bslist[index].code);
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
              mapController.animateCamera(CameraUpdate.newLatLngZoom(
                  LatLng(busstop.lat, busstop.lng), 16));
            }
          },
        ),
      ),
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
