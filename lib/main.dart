import 'dart:async';
import 'dart:convert';
import 'package:moovitainfo/services/currentlocationclass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as rootBundle;
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:moovitainfo/busstoplist.dart';
import 'package:moovitainfo/settings.dart';
import 'package:moovitainfo/survey.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyMain());
}

class MyMain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      routes: {
        '/': (context) => MyApp(),
        '/second': (context) => MyBS(),
        '/settings': (context) => MyIP(),
        '/survey': (context) => SurveyPage()
      },
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String> bslist = [
    'KAP',
    'Main Entrance',
    'Blk 23',
    'Sports Hall',
    'SIT',
    'Blk 44',
    'Blk 37',
    'Makan Place',
    'Health Science',
    'LSCT',
    'Blk 72'
  ];
  List<LatLng> coordinates = [
    LatLng(1.3365156413692888, 103.78278794804254),
    LatLng(1.3327930713846318, 103.77771893587253),
    LatLng(1.3339219201675242, 103.77574132061896),
    LatLng(1.3350826567868576, 103.7754223503998),
    LatLng(1.3343686930989717, 103.77435631203087),
    LatLng(1.3329522845882348, 103.77145520892851),
    LatLng(1.3327697559194817, 103.77323977064727),
    LatLng(1.3324019134469306, 103.7747380910866),
    LatLng(1.3298012679376835, 103.77465550100018),
    LatLng(1.3311533369747423, 103.77490110804173),
    LatLng(1.3312394356934057, 103.77644173403719)
  ];
  final MqttServerClient client =
      MqttServerClient('test.mosquitto.org', '1883');
  Map BusStop = {
    'BusStopCode': '1',
    'name': 'King Albert Park',
    'road': 'S10202778B',
    'lat': 1.3365156413692878,
    'lng': 103.78278794804254
  };
  late String _darkStyle;
  late String _lightStyle;
  String officialstyle = '';
  String choice = 'API';
  String CurrentBusStop = "";
  int mybs = 0;
  int mapbs = 0;
  String IP = '192.168.2.105:5332';
  String json1 = '';
  String json2 = '';
  String json3 = '';
  String message1 = '';
  String message2 = '';
  String message3 = '';
  String message4 = '';
  String Status = "";
  String busstatus = '';
  String CurrentBS = '';
  String CurrentBSS = '';
  String _HC = '';
  String HC = '0';
  late String ETA;
  int etaa = 0;
  int etaaa = 0;
  int currentbsindex = 0;
  int secbsindex = 0;
  int thirdbsindex = 0;
  String RTC = '';
  PolylinePoints polylinePoints = PolylinePoints();
  Map<PolylineId, Polyline> polylines = {};
  bool second = false;
  late BitmapDescriptor markerbitmap;
  late BitmapDescriptor markerbitmap2;
  late GoogleMapController mapController; //contrller for Google map
  Set<Marker> markers = new Set();
  bool timechecked = false;
  bool _isDark = false;

  double percentage = 0.0;
  Color cap = Colors.green;

  Future<List<CurrentLocationClass>> ReadCurrentLocation() async {
    //read json file
    final jsondata =
    await rootBundle.rootBundle.loadString('jsonfile/tracking.json');
    //decode json data as list
    var currentloc = <CurrentLocationClass>[];
    print("Success");

    Map<String, dynamic> productsJson = json.decode(jsondata);
    for (var productJson in productsJson['value']) {
      currentloc.add(CurrentLocationClass.fromJson(productJson));
    }
    return currentloc;
  }

  percentaged() {
    int Heads = int.parse(HC);
    if (Heads < 6) {
      percentage = 0.2;
      cap = Colors.green;
    } else if (Heads < 10) {
      percentage = 0.6;
      cap = Colors.yellow;
    } else if (Heads > 9) {
      percentage = 0.9;
      cap = Colors.red;
    }
  }

  int nearestMinute(String time) {
    Duration duration = Duration(
        minutes: int.parse(time.split(':')[0]),
        seconds: int.parse(time.split(':')[1]));
    return (duration.inSeconds / 60).round();
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
    List<LatLng> polylineCoordinates = [];
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyCPOOzOV-23KSBWcTYgw0Jo4WxQQTjoUBM',
      PointLatLng(BusStop['lat'], BusStop['lng']),
      PointLatLng(
          coordinates[mapbs - 1].latitude, coordinates[mapbs - 1].longitude),
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

  Future<String> getCurrentBS() async {
    try {
      var link = Uri.parse('http://$IP/CurrentBusStop');
      var currentbusdata = await http.get(link);
      // final bsdata = await rootBundle.loadString('jsonfile/currentbs.json');
      setState(() {
        Map<String, dynamic> busstopjson = json.decode(currentbusdata.body);
        CurrentBS = busstopjson["Name"];
        getdisplayindex(CurrentBS);
      });
    } catch (e) {
      CurrentBS = '';
    }
    return CurrentBS;
  }

  Future<String> getCurrentETA() async {
    try {
      var link = Uri.parse('http://$IP/ETA');
      var ETAdata = await http.get(link);
      // final etadata = await rootBundle.loadString('jsonfile/ETA.json');
      setState(() {
        Map<String, dynamic> etajson = json.decode(ETAdata.body);
        ETA = etajson["ETA"];
        getBusStatus(ETA);
      });
    } catch (e) {
      ETA = '';
    }
    return ETA;
  }

  Future<String> getHeadCount() async {
    try {
      var link = Uri.parse('http://$IP/Headcount');
      var HCdata = await http.get(link);
      // final rtcdata = await rootBundle.loadString('jsonfile/RTC.json');
      setState(() {
        Map<String, dynamic> HCjson = json.decode(HCdata.body);
        _HC = (HCjson["Headcount"]).toString();
        if (_HC == "-1") {
          _HC = "--";
          getHC(_HC);
        } else {
          getHC(_HC);
        }
      });
    } catch (e) {
      // Return empty string if API call fails
      _HC = '';
    }
    return _HC;
  }

  getHC(String HCC) {
    HC = HCC;
    percentaged();
  }

  void connect() async {
    try {
      await client.connect();
      print('MQTT client connected');
      client.subscribe('/CurrentBusStop', MqttQos.exactlyOnce);
      client.subscribe('/ETA', MqttQos.exactlyOnce);
      client.subscribe('/RTC', MqttQos.exactlyOnce);
      client.subscribe('/HC', MqttQos.exactlyOnce);
      client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttMessage recMess = c[0].payload;
        final String topic = c[0].topic;
        final MqttPublishMessage publishMessage = recMess as MqttPublishMessage;
        final String message = utf8.decode(publishMessage.payload.message);
        if (topic == '/CurrentBusStop') {
          setState(() {
            json1 = message;
            Map<String, dynamic> jsonBS = jsonDecode(message);
            message1 = jsonBS["Name"];
            print(message1);
            getdisplayindex(jsonBS["Name"]);
          });
        } else if (topic == '/ETA') {
          setState(() {
            json2 = message;
            Map<String, dynamic> jsoneta = jsonDecode(message);
            message2 = jsoneta["ETA"];
            getBusStatus(jsoneta["ETA"]);
            ETA = message2;
          });
        }
      });
    } catch (e) {
      print('MQTT client connection failed: $e');
    }
  }

  getBusStatus(String ETAA) async {
    int index = 0;
    etaa = nearestMinute(ETAA);
    etaaa = etaa;
    if (message1.isNotEmpty || CurrentBS.isNotEmpty) {
      if (etaa != 0) {
        if (mybs > 1) {
          mybs = currentbsindex - 1;
        } else if (mybs < 1) {
          mybs = currentbsindex;
        }
      } else if (etaa == 0) {
        mybs = currentbsindex;
      }
    }

    int diff = 0;
    index = int.parse(BusStop['BusStopCode']);
    diff = index - currentbsindex;
    if (diff > 1) {
      etaa = etaa + (3 * diff);
      Status = "${etaa.toString()} mins";
      getcurrentbusindex(etaa);
    } else if (diff < 0) {
      etaa = etaa + (3 * (11 + diff));
      Status = "${etaa.toString()} mins";
      getcurrentbusindex(etaa);
    } else if (diff == 0) {
      if (etaa > 0) {
        Status = "${etaa.toString()} mins";
        getcurrentbusindex(etaa);
      } else {
        Status = "Arrived";
        getcurrentbusindex(etaa);
      }
    } else if (diff == 1) {
      etaa = etaa + 3;
      Status = "${etaa.toString()} mins";
      getcurrentbusindex(etaa);
    }
  }

  getdisplayindex(String CBS) {
    CurrentBSS = CBS;
    if (CBS == "0" || CBS.isEmpty) {
      currentbsindex = int.parse(CBS);
    } else if (CBS.contains('\"')) {
      currentbsindex = int.parse(CBS.substring(0, 1));
    } else {
      currentbsindex = int.parse(CBS);
    }
  }

  Future<bool> timeCheck() async {
    var currentTime = DateTime.now();
    var startTime1 =
        DateTime(currentTime.year, currentTime.month, currentTime.day, 7, 30);
    var endTime1 =
        DateTime(currentTime.year, currentTime.month, currentTime.day, 9, 30);
    var startTime2 =
        DateTime(currentTime.year, currentTime.month, currentTime.day, 11, 30);
    var endTime2 =
        DateTime(currentTime.year, currentTime.month, currentTime.day, 14, 30);
    if (currentTime.isAfter(startTime1) && currentTime.isBefore(endTime1)) {
      setState(() {
        timechecked = true;
      });
    } else if (currentTime.isAfter(startTime2) &&
        currentTime.isBefore(endTime2)) {
      setState(() {
        timechecked = true;
      });
    } else {
      setState(() {
        timechecked = false;
      });
    }
    RTC = DateFormat.Hm().format(currentTime);
    return timechecked;
  }

  getcurrentbusindex(int ETA) {
    if (ETA > 0) {
      if (mybs != 1){
        mapbs = mybs - 1;
        busstatus = 'Bus is coming from ${bslist[mapbs]} in ${ETA} mins';
      }
      else{
        mapbs = mybs;
        busstatus = 'Bus is coming from ${bslist[mapbs]} in ${ETA} mins';
      }
      getPolyPoints();
    } else {
      mapbs = mybs;
      busstatus = 'Bus has arrived at ${bslist[mapbs - 1]}';
      getPolyPoints();
    }
  }

  void API() {
    getCurrentBS();
    getCurrentETA();
    getHeadCount();
    bstimer = new Timer.periodic(Duration(seconds: 1), (_) {
      getCurrentBS();
    });
    etatimer = new Timer.periodic(Duration(seconds: 1), (_) {
      getCurrentETA();
    });
    hctimer = new Timer.periodic(Duration(seconds: 1), (_) {
      getHeadCount();
    });
  }

  void _showPopupMenu() {
    showMenu(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      context: context,
      position: RelativeRect.fromLTRB(0, 80, 0, 0),
      items: [
        PopupMenuItem(
          child: Text('Settings'),
          value: 1,
        ),
        PopupMenuItem(
          child: Text('Survey'),
          value: 2,
        ),
      ],
      elevation: 8.0,
    ).then((value) async {
      if (value == 1) {
        dynamic settings = await Navigator.pushNamed(context, "/settings");
        setState(() {
          if (settings[0] != '') {
            IP = settings[0];
            choice = settings[1];
            _saveIPAddress(IP);
          } else {
            choice = settings[1];
          }
          if (choice == "API") {
            API();
          } else if (choice == "MQTT") {
            connect();
          }
        });
      } else if (value == 2) {
        Navigator.pushNamed(context, '/survey');
      }
    });
  }

  _loadIPAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      IP = (prefs.getString('ip_address') ?? '');
    });
  }

  // Save the IP address to persistent storage
  _saveIPAddress(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('ip_address', value);
    setState(() {
      IP = (prefs.getString('ip_address') ?? '');
    });
  }

  late Timer timer;
  late Timer bstimer;
  late Timer etatimer;
  late Timer hctimer;
  late Timer rtctimer;

  @override
  void initState() {
    timeCheck();
    timer = new Timer.periodic(Duration(seconds: 60), (_) => timeCheck());
    super.initState();
    rootBundle.rootBundle.loadString('jsonfile/darkgoogle.json').then((string) {
      _darkStyle = string;
    });
    if (choice == "API") {
      setState(() {
        API();
      });
    } else if (choice == "MQTT") {
      setState(() {
        connect();
      });
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    getmarkericon();
    _loadIPAddress();
  }

  @override
  void dispose() {
    connect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDark ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red[400],
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.all(10.0),
            child: InkWell(
              onTap: () => _showPopupMenu(),
              child: Image.asset(
                "jsonfile/Moovita1.png",
                alignment: Alignment.center,
              ),
            ),
          ),
          title: Row(
            children: [
              InkWell(
                onTap: () async {
                  dynamic result = await Navigator.pushNamed(
                    context,
                    '/second',
                    arguments: {
                      'eta': etaaa.toString(),
                      'mybs': mybs.toString(),
                      'isDarkMode': _isDark
                    },
                  );
                  setState(() {
                    BusStop = {
                      'BusStopCode': result['code'],
                      'name': result['name'],
                      'road': result['road'],
                      'lat': result['lat'],
                      'lng': result['lng']
                    };
                    Status = '';
                    busstatus = '';
                    timeCheck();
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Color(0xff000000)),
                      borderRadius: BorderRadius.all(Radius.circular(5))),
                  height: 50.0,
                  width: 240.0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: BusStop['name'].isEmpty
                        ? Center(
                            child: SpinKitDualRing(
                              color: Colors.red,
                              size: 20.0,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                BusStop['name'],
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.black),
                                textAlign: TextAlign.start,
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    BusStop['BusStopCode'],
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.black),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    BusStop['road'],
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.black),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          )),
          actions: <Widget>[
            Checkbox(
              value: _isDark,
              onChanged: (value) {
                setState(() {
                  _isDark = value!;
                });
              },
            )
          ],
        ),
        body: Center(
          child: timechecked == false
              ? Center(
                  child: Card(
                    child: Text(
                      "Not Operating ATM",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                )
              : Status.isEmpty
                  ? Center(
                      child: SpinKitDualRing(
                        color: Colors.red,
                        size: 20.0,
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Stack(
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
                                  initialCameraPosition: CameraPosition(
                                    target:
                                        LatLng(BusStop['lat'], BusStop['lng']),
                                    zoom: 16,
                                  ),
                                  markers: getmarkers(),
                                  polylines: Set<Polyline>.of(polylines.values),
                                  myLocationButtonEnabled: true,
                                  myLocationEnabled: true,
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomLeft,
                                // add your floating action button
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: FloatingActionButton(
                                    backgroundColor: Colors.grey,
                                    mini: true,
                                    onPressed: () {
                                      setState(() {
                                        mapController.animateCamera(
                                            CameraUpdate.newLatLngZoom(
                                                LatLng(BusStop['lat'],
                                                    BusStop['lng']),
                                                16));
                                      });
                                    },
                                    child: Icon(
                                      Icons.map,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              mapController.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                      coordinates[mapbs - 1], 18));
                            });
                            mapController.showMarkerInfoWindow(
                                MarkerId(bslist[mapbs - 1]));
                          },
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text("CURRENT ETA IS:",
                                      style: TextStyle(fontSize: 40)),
                                  Text(
                                    Status,
                                    style: TextStyle(
                                        fontSize: 50,
                                        fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        LinearPercentIndicator(
                          alignment: MainAxisAlignment.center,
                          width: 300.0,
                          lineHeight: 20.0,
                          percent: percentage,
                          backgroundColor: Colors.white,
                          progressColor: cap,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          RTC,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 40),
                        )
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
    markerbitmap2 = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(),
      "jsonfile/bus.png",
    );
  }

  Set<Marker> getmarkers() {
    markers = new Set();
    setState(() {
      markers = new Set();
      markers.add(Marker(
          markerId: MarkerId(BusStop['name']),
          position: LatLng(BusStop['lat'], BusStop['lng']),
          //position of marker
          infoWindow: InfoWindow(
              //popup info
              title: BusStop['name'],
              snippet: "${BusStop['BusStopCode']} ${BusStop['road']}"),
          icon: markerbitmap,
          onTap: () {
            setState(() {
              mapController.animateCamera(CameraUpdate.newLatLngZoom(
                  LatLng(BusStop['lat'], BusStop['lng']), 18));
            });
          }));
      markers.add(Marker(
          markerId: MarkerId(bslist[mapbs - 1]),
          position: coordinates[mapbs - 1],
          //position of marker
          infoWindow: InfoWindow(
              //popup info
              title: "Current Bus Location",
              snippet: "${busstatus}"),
          icon: markerbitmap2,
          onTap: () {
            setState(() {
              mapController.animateCamera(
                  CameraUpdate.newLatLngZoom(coordinates[mapbs - 1], 14));
            });
          }));
    });
    return markers;
  }
}
