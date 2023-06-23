import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final Function(int) screenOption;
  final Function(int) refreshtime;
  final int refresh;
  final bool style;
  final int selectedindex;

  SettingsPage(
      {Key? key,
        required this.selectedindex,
      required this.screenOption,
      required this.refreshtime,
      required this.refresh,
      required this.style})
      : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _refreshInterval = 5; // Default refresh interval in seconds
  bool _disableNotifications = false;
  late int selectedindex = widget.selectedindex;
  late Color background;
  late Color primary;
  late String _selectedOption;
  List<String> _options = ['Bus Stops', 'Favourites', 'Route'];

  style(bool style) {
    if (style == true) {
      background = Colors.black;
      primary = Colors.white;
    } else {
      background = Colors.white;
      primary = Colors.black;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    style(widget.style);
    _refreshInterval = widget.refresh;
    _selectedOption = _options[selectedindex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Auto Refresh',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: primary),
              ),
              Text(
                'Higher refresh rate consumes more data',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildRefreshOption(5),
                  _buildRefreshOption(10),
                  _buildRefreshOption(20),
                ],
              ),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preferred Option:',
                    style: TextStyle(fontSize: 18, color: primary, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: background,
                    ),
                    child: DropdownButton<String>(
                      dropdownColor: background,
                      value: _selectedOption,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedOption = newValue!;
                          selectedindex = _options.indexWhere((option) => option == _selectedOption);
                          widget.screenOption(selectedindex);
                        });
                      },
                      items: _options.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: TextStyle(color: primary)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              // Text(
              //   'Disable Notifications',
              //   style: TextStyle(
              //       fontSize: 18, fontWeight: FontWeight.bold, color: primary),
              // ),
              // SwitchListTile(
              //   tileColor: background,
              //   title: Text(
              //     'Disable Notifications',
              //     style: TextStyle(color: primary),
              //   ),
              //   value: _disableNotifications,
              //   onChanged: (value) {
              //     setState(() {
              //       _disableNotifications = value;
              //       widget.isNotificationDisabled(value);
              //     });
              //   },
              // ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Handle button press
                  Navigator.pop(context);

                },
                child: Text('Return to Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: background,
                  foregroundColor: primary,
                  side: BorderSide(color: primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshOption(int interval) {
    return ChoiceChip(
      label: Text('$interval'),
      selected: _refreshInterval == interval,
      onSelected: (selected) {
        setState(() {
          _refreshInterval = selected ? interval : 0;
          widget.refreshtime(_refreshInterval);
        });
      },
    );
  }
}
