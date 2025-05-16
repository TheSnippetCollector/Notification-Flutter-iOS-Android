import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';

// Plug and Play
// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

class FCMService {
  // Singleton pattern
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  // Stream controllers to expose message events
  final StreamController<RemoteMessage> _onMessageStreamController = 
      StreamController<RemoteMessage>.broadcast();
  final StreamController<RemoteMessage> _onMessageOpenedAppStreamController = 
      StreamController<RemoteMessage>.broadcast();
  
  // Expose streams
  Stream<RemoteMessage> get onMessage => _onMessageStreamController.stream;
  Stream<RemoteMessage> get onMessageOpenedApp => _onMessageOpenedAppStreamController.stream;

  String? _token;
  String? get token => _token;

  // Initialize FCM service
  Future<void> initialize() async {
    // Set up message handlers
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
      _onMessageStreamController.add(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background state with message: ${message.data}');
      _onMessageOpenedAppStreamController.add(message);
    });

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Check for initial message (app opened from terminated state)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from terminated state with message: ${message.data}');
        _onMessageOpenedAppStreamController.add(message);
      }
    });

    // Get token
    await getToken();
  }

  // Request notification permissions
  Future<NotificationSettings> requestPermissions({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
  }) async {
    // For Android 13+ (API level 33+), we need to request the POST_NOTIFICATIONS permission
    if (Platform.isAndroid) {
      // Check Android version programmatically
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      // Android 13 is API level 33
      if (sdkInt >= 33) {
        // Request the POST_NOTIFICATIONS permission
        final status = await Permission.notification.request();
        print('Android 13+ notification permission status: $status');
        
        // If permission is denied, return early with denied status
        if (status.isDenied || status.isPermanentlyDenied) {
          return NotificationSettings(
            authorizationStatus: AuthorizationStatus.denied,
            alert: false,
            announcement: false,
            badge: false,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: false,
          );
        }
      }
    }
    
    // Request FCM permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: alert,
      announcement: announcement,
      badge: badge,
      carPlay: carPlay,
      criticalAlert: criticalAlert,
      provisional: provisional,
      sound: sound,
    );
    
    print('User granted permission: ${settings.authorizationStatus}');
    return settings;
  }

  // Get the FCM token
  Future<String?> getToken() async {
    _token = await _firebaseMessaging.getToken();
    print('FCM Token: $_token');
    return _token;
  }

  // Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  // Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  // Clean up resources
  void dispose() {
    _onMessageStreamController.close();
    _onMessageOpenedAppStreamController.close();
  }
}
