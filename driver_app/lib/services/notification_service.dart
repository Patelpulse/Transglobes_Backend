import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import '../core/config.dart';
import '../core/network_logger.dart';

final notificationServiceProvider = Provider((ref) => NotificationService(ref));

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this._ref);

  Future<void> init() async {
    // Request permission for iOS
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click
        print('Notification clicked: ${details.payload}');
      },
    );

    // Get FCM Token
    String? token = await _fcm.getToken();
    if (token != null) {
      print('FCM Token: $token');
      await _updateTokenOnBackend(token);
    }

    // Listen for token refreshes
    _fcm.onTokenRefresh.listen(_updateTokenOnBackend);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message received in foreground: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Background/Terminated click handling
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked from background: ${message.data}');
    });
  }

  Future<void> _updateTokenOnBackend(String token) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      final idToken = await user.getIdToken();
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/driver/fcm-token');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };
      final requestBody = jsonEncode({
        'uid': user.uid,
        'fcmToken': token,
      });
      NetworkLogger.logRequest(
        method: 'POST',
        url: url,
        headers: headers,
        body: requestBody,
      );
      final response = await http.post(
        url,
        headers: headers,
        body: requestBody,
      );
      NetworkLogger.logResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        print('FCM Token updated on backend');
      } else {
        print('Failed to update FCM Token: ${response.body}');
      }
    } catch (e) {
      print('Error updating FCM Token on backend: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }
}
