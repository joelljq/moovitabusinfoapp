import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as rootBundle;
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:moovitainfo/busstoplist.dart';
// import 'package:moovitainfo/currentroute.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

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
        // '/third': (context) => ServiceList()
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
  final MqttServerClient client =
      MqttServerClient('test.mosquitto.org', '1883');
  Map BusStop = {
    'BusStopCode': '',
    'name': '',
    'road': '',
    'lat': 0.0,
    'lng': 0.0
  };
  late String _mapStyle;
  String CurrentBusStop = "";
  int mybs = 0;
  String json1 = '';
  String json2 = '';
  String json3 = '';
  String message1 = '';
  String message2 = '';
  String message3 = '';
  String message4 = '';
  String Status = "";
  String CurrentBS = '';
  String CurrentBSS = '';
  late String ETA;
  int etaa = 0;
  int currentbsindex = 0;
  int secbsindex = 0;
  int thirdbsindex = 0;
  bool second = false;
  late BitmapDescriptor markerbitmap;
  late GoogleMapController mapController; //contrller for Google map
  late GoogleMapController mapController2;
  Set<Marker> markers = new Set();
  bool timechecked = false;

  int nearestMinute(String time) {
    Duration duration = Duration(
        minutes: int.parse(time.split(':')[0]),
        seconds: int.parse(time.split(':')[1]));
    return (duration.inSeconds / 60).round();
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

  getBusStatus(String ETAA) {
    int index = 0;
    if (message1.isNotEmpty) {
      mybs = int.parse(CurrentBSS);
    }
    etaa = nearestMinute(ETAA);
    print(etaa);
    int diff = 0;
    index = int.parse(BusStop['BusStopCode']);
    diff = index - mybs;
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
  }

  geteta(int index) {
    int diff = 0;
    int eta = 0;
    if (index != mybs) {
      diff = index - mybs;
      if (diff > 1) {
        eta = eta + (3 * diff);
      } else if (diff < 0) {
        eta = eta + (3 * (11 + diff));
      } else if (diff == 0) {
        eta = 0;
      } else if (diff == 1) {
        eta = eta + 3;
      }
    }
  }

  getdisplayindex(String CBS) {
    CurrentBSS = CBS;
    if (CBS == "0" || CBS.isEmpty) {
      currentbsindex = int.parse(CBS);
    } else if (CBS.contains('\"')) {
      currentbsindex = int.parse(CBS.substring(0, 1)) - 1;
      secbsindex = currentbsindex + 1;
      thirdbsindex = currentbsindex + 2;
    } else {
      currentbsindex = int.parse(CBS) - 1;
      secbsindex = currentbsindex + 1;
      thirdbsindex = currentbsindex + 2;
    }
  }

  Future<bool> timeCheck() async {
    var currentTime = DateTime.now();
    var startTime1 =
        DateTime(currentTime.year, currentTime.month, currentTime.day, 7, 30);
    var endTime1 =
        DateTime(currentTime.year, currentTime.month, currentTime.day, 8, 30);
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
    return timechecked;
  }

  late Timer timer;

  @override
  void initState() {
    timeCheck();
    timer = new Timer.periodic(Duration(seconds: 60), (_) => timeCheck());
    super.initState();
    rootBundle.rootBundle.loadString('jsonfile/darkgoogle.json').then((string) {
      _mapStyle = string;
    });
    connect();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    getmarkericon();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'ClinicaPro',
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red[400],
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Image.asset(
              "jsonfile/Moovita1.png",
              alignment: Alignment.center,
            ),
          ),
          title: Row(
            children: [
              InkWell(
                onTap: () async {
                  dynamic result =
                      await Navigator.pushNamed(context, '/second');
                  setState(() {
                    BusStop = {
                      'BusStopCode': result['code'],
                      'name': result['name'],
                      'road': result['road'],
                      'lat': result['lat'],
                      'lng': result['lng']
                    };
                    Status = '';
                    connect();
                    timeCheck();
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Color(0xff000000)),
                      borderRadius: BorderRadius.all(Radius.circular(5))),
                  height: 50.0,
                  width: 300.0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: BusStop['name'].isEmpty
                        ? Center(
                            child: SpinKitDualRing(
                              color: Colors.purple,
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
        ),
        body: Center(
          child: timechecked == false
              ? Center(
                  child: Card(
                    child: Text("Not Operating ATM"),
                  ),
                )
              : Status.isEmpty
                  ? Center(
                      child: SpinKitDualRing(
                        color: Colors.purple,
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
                                    });
                                  },
                                  initialCameraPosition: CameraPosition(
                                    target:
                                        LatLng(BusStop['lat'], BusStop['lng']),
                                    zoom: 16,
                                  ),
                                  markers: getmarkers(),
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
                          onTap: () {},
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
                          )),
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
    });
    return markers;
  }
}
