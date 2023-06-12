import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BottomSheetWidget extends StatefulWidget {
  final String string1;
  final String string2;
  final String string3;
  final String string4;

  BottomSheetWidget(
      {required Key key,
      required this.string1,
      required this.string2,
      required this.string3,
      required this.string4})
      : super(key: key);

  @override
  _BottomSheetWidgetState createState() => _BottomSheetWidgetState();
}

class _BottomSheetWidgetState extends State<BottomSheetWidget> {
  int fromindex = 0;
  int toindex = 0;
  int mybs = 0;
  int etaa = 0;
  int duration = 0;
  String departure = '';
  String arrival = '';
  List<String> bstoplist = [
    'King Albert Park',
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

  getBusStatus() {
    fromindex = int.parse(widget.string1);
    toindex = int.parse(widget.string2);
    etaa = int.parse(widget.string3);
    mybs = int.parse(widget.string4);
    if (etaa != 0) {
      if (mybs > 1) {
        mybs = mybs - 1;
      } else if (mybs < 1) {
        mybs = mybs;
      }
    } else if (etaa == 0) {
      mybs = mybs;
    }

    int diff = 0;
    int diff2 = 0;
    diff = fromindex - mybs;
    diff2 = toindex - fromindex;
    if (diff > 1) {
      etaa = etaa + (3 * diff);
    } else if (diff < 0) {
      etaa = etaa + (3 * (11 + diff));
    } else if (diff == 0) {
      if (etaa > 0) {}
    } else if (diff == 1) {
      etaa = etaa + 3;
    }
    DateTime now = DateTime.now();
    DateTime depart = now.add(Duration(minutes: etaa));
    departure = DateFormat.Hm().format(depart);
    if (diff2 < 0) {
      diff2 = 11 + diff2;
    }
    duration = diff2 * 3;
    DateTime arrive = depart.add(Duration(minutes: duration));
    arrival = DateFormat.Hm().format(arrive);
  }

  @override
  void initState() {
    super.initState();
    getBusStatus();
  }

  @override
  Widget build(BuildContext context) {
    // return Container(
    //   decoration: BoxDecoration(
    //     color: Colors.red[400],
    //     border: Border.all(color: Colors.red, width: 2),
    //     borderRadius: BorderRadius.only(
    //       topLeft: Radius.circular(30),
    //       topRight: Radius.circular(30),
    //     ),
    //   ),
    //   child: Column(
    //     children: <Widget>[
    //       Container(
    //         margin: EdgeInsets.all(20),
    //         child: Text(
    //           "Estimated Departure",
    //           style: TextStyle(
    //               fontSize: 25,
    //               color: Colors.white,
    //               fontWeight: FontWeight.bold),
    //         ),
    //       ),
    //       Container(
    //         margin: EdgeInsets.all(20),
    //         child: Text(
    //           departure,
    //           style: TextStyle(
    //               fontSize: 25,
    //               color: Colors.white,
    //               fontWeight: FontWeight.bold),
    //         ),
    //       ),
    //       Container(
    //         margin: EdgeInsets.all(20),
    //         child: Text(
    //           "Estimated Arrival",
    //           style: TextStyle(
    //               fontSize: 25,
    //               color: Colors.white,
    //               fontWeight: FontWeight.bold),
    //         ),
    //       ),
    //       Container(
    //         margin: EdgeInsets.all(20),
    //         child: Text(
    //           arrival,
    //           style: TextStyle(
    //               fontSize: 25,
    //               color: Colors.white,
    //               fontWeight: FontWeight.bold),
    //         ),
    //       ),
    //     ],
    //   ),
    // );
    return Container(
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
                color: Colors.white,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("From",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600])),
                              SizedBox.fromSize(
                                  size: Size.fromHeight(40.0),
                                  child: Text(bstoplist[fromindex - 1], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
                              // add other widget as child of column
                            ],
                          ),
                          SizedBox(height: 10),
                          Align(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("To",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600])),
                                SizedBox.fromSize(
                                    size: Size.fromHeight(40.0),
                                    child: Text(bstoplist[toindex - 1], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),),
                                // add other widget as child of column
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10,),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text("${departure} - ${arrival}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),),
                    Text("${duration.toString()} Mins Duration", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),)
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
