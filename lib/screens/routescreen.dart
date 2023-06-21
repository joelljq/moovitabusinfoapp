import 'dart:async';

// import 'package:flutter_google_places_web/flutter_google_places_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:moovitainfo/services/busstopclass.dart';
import 'package:moovitainfo/services/notif.dart';
import 'package:moovitainfo/services/routesheet.dart';

class RouteScreen extends StatefulWidget {
  GlobalKey<ScaffoldState> scaffoldkey;
  String darkStyle;
  BusStopClass busstop;
  LatLng curpos;
  List<BusStopClass> bslist;
  int currentbusindex;
  int ETA;
  // BitmapDescriptor markerbitmap;
  // BitmapDescriptor markerbitmap2;
  Function(BusStopClass) addtoFavorites;
  Function(BusStopClass) removeFromFavorites;
  bool style;
  final VoidCallback setstyle;

  RouteScreen(
      {Key? key,
        required this.scaffoldkey,
      required this.setstyle,
      required this.style,
      required this.darkStyle,
      required this.busstop,
      required this.curpos,
      required this.bslist,
      required this.currentbusindex,
      required this.ETA,
      required this.addtoFavorites,
      required this.removeFromFavorites})
      : super(key: key);

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  late GlobalKey<ScaffoldState> _scaffoldKey = widget.scaffoldkey;
  late String darkStyle = widget.darkStyle;
  late GoogleMapController mapController;
  late BusStopClass busstop = widget.busstop;
  late LatLng curpos;
  late List<BusStopClass> bslist;
  late int currentbusindex;
  late int etaa;
  int currentETA = 0;
  int _fselectedIndex = 0;
  int _tselectedIndex = 1;
  PolylinePoints polylinePoints = PolylinePoints();
  Map<PolylineId, Polyline> polylines = {};
  Set<Marker> markers = new Set();
  late String _fromOption;
  late String _toOption;
  late Color background;
  late Color primary;
  late bool style;

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

  late Timer updatetimer;

  @override
  void initState() {
    super.initState();
    _fromOption = 'King Albert Park';
    _toOption = 'Main Entrance';
    updatevalues();
    updatetimer = new Timer.periodic(Duration(seconds: 1), (_) {
      updatevalues();
    });
  }

  @override
  void dispose(){
    super.dispose();
    updatetimer.cancel();
  }

  updatevalues() {
    setState(() {
      style = widget.style;
      curpos = widget.curpos;
      bslist = widget.bslist;
      currentbusindex = widget.currentbusindex;
      etaa = widget.ETA;
      background = style == false ? Colors.white : Colors.black;
      primary = style == true ? Colors.white : Colors.black;
    });
  }

  void swapValues() {
    setState(() {
      String newFrom = '';
      String newTo = '';
      newFrom = _toOption;
      newTo = _fromOption;
      _fromOption = newFrom;
      _fselectedIndex = bslist
          .indexOf(bslist.firstWhere((busStop) => busStop.name == _fromOption));
      _toOption = newTo;
      _tselectedIndex = bslist
          .indexOf(bslist.firstWhere((busStop) => busStop.name == _toOption));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    color: background,
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Where do you want \n to go today?",
                        style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: primary),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 30,
                    left: 10,
                    child: InkWell(
                      onTap: (){
                        _scaffoldKey.currentState?.openDrawer();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: background,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'jsonfile/Moovita1.png',
                          // Replace with your image path
                          width: 40,
                          height: 40,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: Color(0xFF671919),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("From",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[600])),
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
                                                              FontWeight.bold,
                                                          color: primary),
                                                    ),
                                                  ))
                                              .toList(),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              _fromOption = newValue!;
                                              _fselectedIndex = bslist.indexOf(
                                                  bslist.firstWhere((busStop) =>
                                                      busStop.name ==
                                                      _fromOption));
                                            });
                                          },
                                        ),
                                      ),
                                      // add other widget as child of column
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Align(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("To",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[600])),
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
                                                                FontWeight.bold,
                                                            color: primary),
                                                      ),
                                                    ))
                                                .toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                _toOption = newValue!;
                                                _tselectedIndex = bslist
                                                    .indexOf(bslist.firstWhere(
                                                        (busStop) =>
                                                            busStop.name ==
                                                            _toOption));
                                              });
                                            },
                                          ),
                                        ),
                                        // add other widget as child of column
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            GestureDetector(
                              onTap: swapValues,
                              child: Transform.rotate(
                                angle: 90 * 3.141592653589793238 / 180,
                                child: Icon(
                                  Icons.swap_horiz,
                                  color: primary,
                                  size: 40,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              Color(0xFF671919)),
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.white),
                          shape: MaterialStateProperty.all<OutlinedBorder>(
                            RoundedRectangleBorder(
                              side: BorderSide(color: background),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        onPressed: () {
                          if (_fromOption == _toOption) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red,
                                content: Text(
                                  'Please select two different points',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                duration: const Duration(milliseconds: 1500),
                                width: 280.0,
                                // Width of the SnackBar.
                                padding: const EdgeInsets.symmetric(
                                  horizontal:
                                      8.0, // Inner padding for SnackBar content.
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                            );
                          } else {
                            setState(() {
                              showModalBottomSheet(
                                backgroundColor: Colors.transparent,
                                context: context,
                                builder: (context) => BottomSheetWidget(
                                  key: UniqueKey(),
                                  style: style,
                                  string1: bslist[_fselectedIndex].code,
                                  string2: bslist[_tselectedIndex].code,
                                  string3: (widget.ETA).toString(),
                                  string4: (currentbusindex).toString(),
                                ),
                              );
                              // getPolyPoints();
                              // mapController.animateCamera(
                              //     CameraUpdate.newLatLngZoom(
                              //         LatLng(bslist[_fselectedIndex].lat,
                              //             bslist[_fselectedIndex].lng),
                              //         16));
                            });
                          }
                        },
                        child: Text("Enter Search", style: TextStyle(color: background),),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
