import 'dart:async';
import 'dart:convert';
import 'package:flutter/scheduler.dart';
import 'package:moovitainfo/settings.dart';
import 'package:moovitainfo/survey.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as rootBundle;
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:moovitainfo/screens/bsscreen.dart';
import 'package:moovitainfo/screens/favscreen.dart';
import 'package:moovitainfo/screens/routescreen.dart';
import 'package:moovitainfo/services/busstopclass.dart';
import 'package:moovitainfo/services/currentlocationclass.dart';
import 'package:moovitainfo/services/notif.dart';
import 'package:is_first_run/is_first_run.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/src/typed_buffer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService().initNotification();
  await Hive.initFlutter();
  Hive.registerAdapter(BusStopClassAdapter());
  await Hive.openBox<BusStopClass>('favorites');

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Box<BusStopClass> favoritesBox = Hive.box<BusStopClass>('favorites');
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
  int etaa = -1;
  int etaaa = 0;
  int cureta = -1;
  int currentbsindex = 0;
  int secbsindex = 0;
  int thirdbsindex = 0;
  String RTC = '';
  bool second = false;
  bool timechecked = false;
  bool style = false;
  double curlat = 0.0;
  double curlng = 0.0;
  double percentage = 0.0;
  Color cap = Colors.green;
  List<CurrentLocationClass> buspos = [];
  List<BusStopClass> favoritesList = [];
  late Color background;
  late Color primary;
  int refresh = 5;
  late int _screenIndex;

  final client = MqttServerClient('test.mosquitto.org', '1883');

  final TextStyle customTextStyle = TextStyle(fontFamily: 'OpenSans');

  Future<void> saveStyleOption(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('styleOption', value);
  }

  Future<bool> getStyleOption() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('styleOption') ?? false;
  }

  Future<int> getScreenOption() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('screenOption') ?? 0;
  }

  Future<int> getRefreshOption() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('getRefreshOption') ?? 5;
  }

  Future<void> setScreenOption(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('screenOption', value);
  }

  Future<void> setRefreshOption(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('getRefreshOption', value);
  }

  Color hcstatus(String HeadCount) {
    int HeadC = int.parse(HeadCount);
    if (HeadC < 4) {
      return Colors.green;
    } else if (HeadC < 8) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

  void setstyle() {
    setState(() {
      style = !style;
      saveStyleOption(style);
      updatescreen();
      background = style == false ? Colors.white : Colors.black;
      primary = style == true ? Colors.white : Colors.black;
    });
  }

  void loadFavorites() {
    setState(() {
      favoritesList =
          favoritesBox.values.toList(); // Retrieve favorites from Hive box
      updateFavoriteStatus();
      updatescreen();
    });
  }

  void addToFavorites(BusStopClass busStop) {
    favoritesBox.add(busStop); // Add a bus stop to favorites
    loadFavorites(); // Reload the favorites list
  }

  void removeFromFavorites(BusStopClass busStop) {
    for (BusStopClass favbs in favoritesList) {
      if (busStop.code == favbs.code) {
        favoritesBox.delete(favbs.key); // Remove a bus stop from favorites
      }
    }
    loadFavorites(); // Reload the favorites list
  }

  void updateFavoriteStatus() {
    for (BusStopClass busStop in bslist) {
      bool isFavorite = false;

      for (BusStopClass favoriteBusStop in favoritesList) {
        if (favoriteBusStop.code == busStop.code) {
          isFavorite = true;
          break;
        }
      }

      busStop.isFavorite = isFavorite;
    }
  }

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
    setState(() {
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
    });
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
    if (ETAA == "") {
      Status = "Not Avail";
    } else {
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
  }

  getdisplayindex(String CBS) {
    setState(() {
      CurrentBSS = CBS;
      if (CBS == "0" || CBS.isEmpty) {
        currentbsindex = int.parse(CBS);
      } else if (CBS.contains('\"')) {
        currentbsindex = int.parse(CBS.substring(0, 1));
      } else {
        currentbsindex = int.parse(CBS);
      }
    });
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

  void _sendMessage(String busstop, String status) async {
    await client.connect();
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      String topicname = '/bsstatus/${busstop}';
      // print("Success, ${topicname}");
      Map<String, dynamic> jsonMessage = {
        'id': 600,
        'Status': '${status}',
      };
      String messageString = jsonEncode(jsonMessage);
      client.publishMessage(
        topicname,
        MqttQos.atLeastOnce,
        Uint8Buffer()..addAll(messageString.codeUnits),
      );
      client.disconnect();
    }
  }

  getcurrentbusindex(int ETA) {
    setState(() {
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
    });
  }

  getbusposition() async {
    await ReadCurrentLocation();
    setState(() {
      int index = buspos.indexWhere((buspos) =>
          buspos.Route == "${currentbsindex.toString()}.${cureta.toString()}");
      curlat = buspos[index].lat;
      curlng = buspos[index].lng;
    });
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
      // print(_currentPosition);
      // print('Success');
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
      loadFavorites();
    });
  }

  getmarkericon() async {
    bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIOS) {
      markerbitmap = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(),
        "jsonfile/transport1_ios.png",
      );
      markerbitmap2 = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(),
        "jsonfile/bus_ios.png",
      );
    } else {
      markerbitmap = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(),
        "jsonfile/transport1.png",
      );
      markerbitmap2 = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(),
        "jsonfile/bus.png",
      );
    }
  }

  initStyle() async {
    bool firstRun = await IsFirstRun.isFirstRun();
    if (firstRun == true) {
      var brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      bool isDarkMode = brightness == Brightness.dark;
      style = isDarkMode;
      saveStyleOption(style);
      background = style == false ? Colors.white : Colors.black;
      primary = style == true ? Colors.white : Colors.black;
    } else {
      getStyleOption().then((value) {
        setState(() {
          style = value;
          background = style == false ? Colors.white : Colors.black;
          primary = style == true ? Colors.white : Colors.black;
        });
      });
    }
  }

  int _currentIndex = 0;
  late Timer timer;
  late Timer bstimer;
  late Timer etatimer;
  late Timer hctimer;
  late Timer rtctimer;
  late Timer screentimer;

  List<Widget> _screens = [];

  updatescreen() async {
    await loadmapstyle();
    setState(() {
      _screens = [
        BSScreen(
          cancelNotif: cancelnotif,
          startNotif: startTimer,
          sendMessage: _sendMessage,
          scaffoldkey: _scaffoldKey,
          busstatus: hcstatus(HC),
          setstyle: setstyle,
          style: style,
          darkStyle: _darkStyle,
          busstop: bslist[0],
          curpos: LatLng(curlat, curlng),
          bslist: bslist,
          currentbusindex: currentbsindex,
          ETA: cureta,
          markerbitmap2: markerbitmap2,
          markerbitmap: markerbitmap,
          addtoFavorites: addToFavorites,
          removeFromFavorites: removeFromFavorites,
        ),
        FavScreen(
          cancelNotif: cancelnotif,
          startNotif: startTimer,
          sendMessage: _sendMessage,
          scaffoldkey: _scaffoldKey,
          busstatus: hcstatus(HC),
          setstyle: setstyle,
          style: style,
          darkStyle: _darkStyle,
          curpos: LatLng(curlat, curlng),
          bslist: favoritesList,
          currentbusindex: currentbsindex,
          ETA: cureta,
          markerbitmap2: markerbitmap2,
          markerbitmap: markerbitmap,
          removeFromFavorites: removeFromFavorites,
        ),
        RouteScreen(
          scaffoldkey: _scaffoldKey,
          setstyle: setstyle,
          style: style,
          darkStyle: _darkStyle,
          busstop: bsstops[0],
          curpos: LatLng(curlat, curlng),
          bslist: bsstops,
          currentbusindex: currentbsindex,
          ETA: cureta,
          addtoFavorites: addToFavorites,
          removeFromFavorites: removeFromFavorites,
        ),
      ];
    });
  }

  API() {
    getCurrentBS();
    getCurrentETA();
    getHeadCount();
    updatescreen();
  }

  List<Timer> timers = List<Timer>.filled(11, Timer(Duration.zero, () {}));

  void startTimer(String code) {
    int index = bslist.indexWhere((bs) => bs.code == code);
    int favindex = 0;
    if (favoritesList.any((favorite) => favorite.code == bslist[index].code)){
      favindex = favoritesList.indexWhere((fbs) => fbs.code == code);
      favoritesList[favindex].isAlert = true;
    }
    bslist[index].isAlert = true;
    List<int> newETAList = List<int>.filled(11, 0);
    List<int> currentETAList = List<int>.filled(11, 0);
    timers[index] = Timer.periodic(Duration(seconds: 1), (_) {
      newETAList[index] = indexeta(int.parse(bslist[index].code));
      if (newETAList[index] != currentETAList[index]) {
        currentETAList[index] = newETAList[index];
        if (currentETAList[index] == 0) {
          NotificationService().showNotification(
            title: "Bus Alert System",
            body: "Bus has arrived at ${bslist[index].name}!",
            enableSound: true,
            isSilent: false,
          );
          bslist[index].isAlert = false;
          if (favoritesList.contains(code)){
            favoritesList[favindex].isAlert = false;
          }
          timers[index].cancel();
        } else {
          NotificationService().showNotification(
            title: "Bus Alert System",
            body:
                "Bus is arriving at ${bslist[index].name} in ${currentETAList[index]}min",
            enableSound: false,
            isSilent: true,
          );
        }
      } else {
        if (newETAList[index] == 0) {
          NotificationService().showNotification(
            title: "Bus Alert System",
            body: "Bus has arrived at ${bslist[index].name}!",
            enableSound: true,
            isSilent: false,
          );
          bslist[index].isAlert = false;
          if (favoritesList.contains(code)){
            favoritesList[favindex].isAlert = false;
          }
          timers[index].cancel();
        }
      }
    });
  }

  cancelnotif(String code) {
    int index = bslist.indexWhere((bs) => bs.code == code);
    int favindex = favoritesList.indexWhere((fbs) => fbs.code == code);
    bslist[index].isAlert = false;
    favoritesList[favindex].isAlert = false;
    timers[index].cancel();
  }

  int indexeta(int currentcode) {
    int index = 0;
    int diff = 0;
    index = currentcode;
    diff = index - currentbsindex;
    etaa = cureta;
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

  @override
  void initState() {
    super.initState();
    getCurrentBS();
    getCurrentETA();
    getHeadCount();
    updatescreen();
    initStyle();
    getScreenOption().then((value) {
      setState(() {
        _screenIndex = value;
      });
    });
    getRefreshOption().then((value) {
      setState(() {
        refresh = value;
      });
    });
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
    bstimer = new Timer.periodic(Duration(seconds: 5), (_) {
      API();
    });
    getmarkericon();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // @override
  // void dispose(){
  //   super.dispose();
  //   timer.cancel();
  //   bstimer.cancel();
  // }

  loadmapstyle() {
    rootBundle.rootBundle.loadString('jsonfile/darkgoogle.json').then((string) {
      _darkStyle = string;
    });
  }

  refreshintervals(int interval) {
    refresh = interval;
    setRefreshOption(interval);
  }

  screenOption(int selectedoption) {
    setScreenOption(selectedoption);
    _screenIndex = selectedoption;
  }

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          textTheme: TextTheme(
              bodyLarge: customTextStyle, bodyMedium: customTextStyle)),
      home: bslist.isEmpty && _screens.isEmpty
          ? Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SpinKitDualRing(
                    color: Color(0xFF671919),
                    size: 80,
                    lineWidth: 4,
                  ),
                  Image.asset(
                    'jsonfile/Moovita1.png', // Replace with your logo asset path
                    width: 60,
                    height: 60,
                  ),
                ],
              ),
            )
          : Scaffold(
              backgroundColor: background,
              key: _scaffoldKey,
              body: _screens[_screenIndex],
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _screenIndex,
                onTap: (index) {
                  setState(() {
                    _screenIndex = index;
                  });
                },
                selectedItemColor: primary,
                unselectedItemColor: primary.withOpacity(0.6),
                backgroundColor: Color(0xFF671919),
                items: [
                  BottomNavigationBarItem(
                    icon: IconTheme(
                      data: IconThemeData(
                        color: primary,
                        size: 24.0,
                      ),
                      child: Icon(Icons.directions_bus_outlined),
                    ),
                    label: 'Bus Stops',
                  ),
                  BottomNavigationBarItem(
                    icon: IconTheme(
                      data: IconThemeData(
                        color: primary,
                        size: 24.0,
                      ),
                      child: Icon(Icons.favorite_border),
                    ),
                    label: 'Favourite',
                  ),
                  BottomNavigationBarItem(
                    icon: IconTheme(
                      data: IconThemeData(
                        color: primary,
                        size: 24.0,
                      ),
                      child: Icon(Icons.map_outlined),
                    ),
                    label: 'Route',
                  ),
                ],
                selectedLabelStyle: TextStyle(color: primary),
                unselectedLabelStyle: TextStyle(color: primary.withOpacity(0.6)),
              ),
              drawer: Drawer(
                backgroundColor: background,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(color: Color(0xFF671919)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'jsonfile/Moovita1.png',
                            // Replace with your logo image path
                            width: 80,
                            height: 80,
                          ),
                          Text(
                            'Moovita\nMenu',
                            style: TextStyle(
                              color: primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Builder(builder: (context) {
                      return ListTile(
                        leading: Icon(
                          Icons.settings,
                          color: primary,
                        ),
                        title: Text(
                          'Settings',
                          style: TextStyle(color: primary),
                        ),
                        onTap: () async {
                          await getScreenOption().then((value) {
                            setState(() {
                              _screenIndex = value;
                            });
                          });
                          print(_screenIndex);
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SettingsPage(
                                      style: style,
                                      screenOption: screenOption,
                                      selectedindex: _screenIndex,
                                      refreshtime: refreshintervals,
                                      refresh: refresh,
                                    )),
                          );
                        },
                      );
                    }),
                    Builder(builder: (context) {
                      return ListTile(
                        leading: Icon(
                          Icons.assignment,
                          color: primary,
                        ),
                        title: Text('Survey', style: TextStyle(color: primary)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SurveyPage()),
                          );
                        },
                      );
                    }),
                    ListTile(
                      leading: Icon(
                        Icons.brightness_4,
                        color: primary,
                      ),
                      title:
                          Text('Dark Mode', style: TextStyle(color: primary)),
                      onTap: () {
                        setstyle();
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
