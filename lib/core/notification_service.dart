import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    // Xin quyền (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation
    <AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showFocusComplete() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'clarity_timer',
        'Clarity Timer',
        channelDescription: 'Timer notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    await _plugin.show(
      0,
      '🎉 Focus session complete!',
      'Great work! Time for a break.',
      details,
    );
  }

  static Future<void> showBreakComplete() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'clarity_timer',
        'Clarity Timer',
        channelDescription: 'Timer notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    await _plugin.show(
      1,
      '⏰ Break time is over!',
      'Ready to focus again?',
      details,
    );
  }
}