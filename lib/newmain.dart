import 'package:flutter/services.dart' as rootBundle;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:moovitainfo/services/busstopclass.dart';
import 'package:moovitainfo/services/currentlocationclass.dart';
import 'package:moovitainfo/screens/bsscreen.dart';

void main() {
  runApp(NewMain());
}

class NewMain extends StatefulWidget {
  const NewMain({Key? key}) : super(key: key);

  @override
  State<NewMain> createState() => _NewMainState();
}

class _NewMainState extends State<NewMain> {
  late Position _currentPosition;
  List<BusStopClass> bsstops = [];
  List<BusStopClass> bslist = [];
  late Timer geotimer;
  List<String> bstoplist = [
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
  late String _darkStyle;
  late String _lightStyle;
  String officialstyle = '';
  String choice = 'API';
  String CurrentBusStop = "";
  int mybs = 0;
  int mapbs = 0;
  String IP = '172.17.26.222:5332';
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
  late BitmapDescriptor markerbitmap;
  late BitmapDescriptor markerbitmap2;
  String _HC = '';
  String HC = '0';
  late String ETA;
  int etaa = 0;
  int etaaa = 0;
  int cureta = 0;
  int currentbsindex = 0;
  int secbsindex = 0;
  int thirdbsindex = 0;
  String RTC = '';
  bool second = false;
  bool timechecked = false;
  bool _isDark = false;
  double curlat = 0.0;
  double curlng = 0.0;
  double percentage = 0.0;
  Color cap = Colors.green;
  List<CurrentLocationClass> buspos = [];

  Future<List<CurrentLocationClass>> ReadCurrentLocation() async {
    //read json file
    final jsondata =
        await rootBundle.rootBundle.loadString('jsonfile/tracking.json');
    //decode json data as list
    var currentloc = <CurrentLocationClass>[];
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

  getBusStatus(String ETAA) async {
    int index = 0;
    etaa = nearestMinute(ETAA);
    cureta = nearestMinute(ETAA);
    if (cureta > 2) {
      cureta = 2;
    } else {
      cureta = cureta;
    }
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
    index = int.parse(bslist[0].code);
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
    print("Current Bus Stop Is: ${currentbsindex.toString()}");
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
      if (mybs != 1) {
        mapbs = mybs - 1;
        busstatus = 'Bus is coming from ${bstoplist[mapbs]} in ${ETA} mins';
      } else {
        mapbs = mybs;
        busstatus = 'Bus is coming from ${bstoplist[mapbs]} in ${ETA} mins';
      }
      getbusposition();
    } else {
      mapbs = mybs;
      busstatus = 'Bus has arrived at ${bstoplist[mapbs - 1]}';
      getbusposition();
    }
  }

  getbusposition() async {
    await ReadCurrentLocation();
    int index = buspos.indexWhere((buspos) =>
        buspos.Route == "${currentbsindex.toString()}.${cureta.toString()}");
    curlat = buspos[index].lat;
    curlng = buspos[index].lng;
    print(curlat.toString());
  }

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
    return busstops;
  }

  Future<void> _getCurrentLocation() async {
    await ReadBusStopData();
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    await getMyLocation();
  }

  Future<void> getMyLocation() async {
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
    bslist = [];
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

  int _currentIndex = 0;
  late Timer timer;
  late Timer bstimer;
  late Timer etatimer;
  late Timer hctimer;
  late Timer rtctimer;

  void API() {


  }

  @override
  void initState() {
    getCurrentBS();
    getCurrentETA();
    getHeadCount();
    ReadBusStopData().then((value) {
      setState(() {
        bsstops.addAll(value);
      });
    });
    _getCurrentLocation();
    timer =
    new Timer.periodic(Duration(seconds: 60), (_) => _getCurrentLocation());
    ReadCurrentLocation().then((value) {
      setState(() {
        buspos.addAll(value);
      });
    });
    timeCheck();
    API();
    timer = new Timer.periodic(Duration(seconds: 60), (_) => timeCheck());
    bstimer = new Timer.periodic(Duration(seconds: 1), (_) {
      getCurrentBS();
    });
    etatimer = new Timer.periodic(Duration(seconds: 1), (_) {
      getCurrentETA();
    });
    hctimer = new Timer.periodic(Duration(seconds: 1), (_) {
      getHeadCount();
    });
    super.initState();
    rootBundle.rootBundle.loadString('jsonfile/darkgoogle.json').then((string) {
      _darkStyle = string;
    });
    getmarkericon();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  late List<Widget> _screens = [
    BSScreen(
      darkStyle: _darkStyle,
      busstop: bslist[0],
      curpos: LatLng(curlat, curlng),
      bslist: bslist,
      currentbusindex: currentbsindex,
      ETA: cureta,
      markerbitmap2: markerbitmap2,
      markerbitmap: markerbitmap,
    ),
    FavoriteScreen(),
    RouteScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: bslist.isEmpty
            ? Center(
                child: SpinKitDualRing(
                  color: Colors.red,
                  size: 20.0,
                ),
              )
            : Scaffold(
                body: _screens[_currentIndex],
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  selectedItemColor: Colors.white,
                  unselectedItemColor: Colors.white.withOpacity(0.6),
                  backgroundColor: Color(0xFF671919),
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.directions_bus),
                      label: 'Bus',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.favorite),
                      label: 'Favorite',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.map),
                      label: 'Route',
                    ),
                  ],
                ),
              ));
  }
}

class BusScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Bus Screen'),
    );
  }
}

class FavoriteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Favorite Screen'),
    );
  }
}

class RouteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Route Screen'),
    );
  }
}
