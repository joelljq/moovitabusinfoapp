import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final Function(bool) isNotificationDisabled;
  final Function(int) refreshtime;
  final int refresh;
  final bool isNotifDisabled;
  final bool style;

  SettingsPage(
      {Key? key,
      required this.isNotificationDisabled,
      required this.refreshtime,
      required this.refresh,
      required this.isNotifDisabled,
      required this.style})
      : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _refreshInterval = 5; // Default refresh interval in seconds
  bool _disableNotifications = false;
  late Color background;
  late Color primary;

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
    _disableNotifications = widget.isNotifDisabled;
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
              Text(
                'Disable Notifications',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: primary),
              ),
              SwitchListTile(
                tileColor: background,
                title: Text(
                  'Disable Notifications',
                  style: TextStyle(color: primary),
                ),
                value: _disableNotifications,
                onChanged: (value) {
                  setState(() {
                    _disableNotifications = value;
                    widget.isNotificationDisabled(value);
                  });
                },
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: primary,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Handle button press
                    Navigator.pop(context);

                  },
                  child: Text('Return to Home'),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(background),
                    foregroundColor: MaterialStateProperty.all(primary),
                  ),
                ),
              )
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
