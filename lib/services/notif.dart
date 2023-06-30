import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    AndroidInitializationSettings initializationSettingsAndroid =
    const AndroidInitializationSettings('moovita1');


    var initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {},
    );

    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {},
    );
  }

  NotificationDetails notificationDetails({
    bool isSilent = false,
    bool enableSound = true,
  }) {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'channelId',
      'channelName',
      channelDescription: 'channelDescription',
      importance: isSilent ? Importance.min : Importance.max,
      priority: isSilent ? Priority.low : Priority.high,
      playSound: !isSilent && enableSound,
      enableVibration: !isSilent,
    );

    return NotificationDetails(android: androidPlatformChannelSpecifics);
  }


  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
    bool isSilent = false,
    bool enableSound = true,
  }) async {
    final appLifecycleState = await notificationsPlugin
        .getNotificationAppLaunchDetails()
        .then((details) => details?.didNotificationLaunchApp);

    // Check if the app is in the foreground
    if (appLifecycleState != null && appLifecycleState) {
      // App is in the foreground, handle the notification according to your requirement
      return;
    }

    final platformChannelSpecifics =
    notificationDetails(isSilent: isSilent, enableSound: enableSound);

    await notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}