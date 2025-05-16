# 1 First, let's set up Firebase Messaging in your Flutter project

### Before Starts:
> Connect Firebase to your project using `firebase configure`

⚠️ Warning : When you connect Firebase to a Flutter app using `flutterfire configure`:

#### ✔️ It **does generate**:

-   `lib/firebase_options.dart` — containing all app-specific Firebase config values.
    

#### ❌ It **does not always download**:

-   `android/app/google-services.json`
    
-   `ios/Runner/GoogleService-Info.plist`

Especially on **Windows**, the `plist` is almost never downloaded due to platform limitations.

-   If you're on **macOS/Linux**: it often **downloads them automatically**
    
-   If you're on **Windows**: you usually need to **manually download the `.plist`** (and sometimes `.json` too if it fails).

| Firebase Service | Requires `.plist` (iOS) / `.json` (Android)?|
| - | - |
| Firebase Auth | ✅ Yes |
| Firebase Messaging (FCM) | ✅ Yes |
| Firebase Firestore| ✅ Yes |
| Firebase Analytics| ✅ Yes |
| Firebase Crashlytics| ✅ Yes |

### Solution : Manually add `GoogleService-Info.plist` to your Flutter iOS project
-   Go to the Firebase Console
    
-   Open your project: `fir-d62e1`
    
-   Click the **gear icon** (⚙️) next to "Project Overview" → go to **Project settings**
    
-   Scroll down to **Your apps**
    
-   Under the iOS app (`com.example.tableCalender`), click **Download `GoogleService-Info.plist`**

-  Move the File Into Your Project ` ios/Runner/GoogleService-Info.plist `
---
Start by adding the required packages to your `pubspec.yaml`:

### Setup:
```
dependencies: 
	firebase_core:  ^2.24.2 
	firebase_messaging:  ^14.7.10
```
Run `flutter pub get` to install these dependencies.

# 2. Initialize Firebase

In your main.dart file, you need to initialize Firebase before running your app:
```
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

// Define a top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Set the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(MyApp());
}

```

# 3. Request permissions

For iOS, you need to request permission from the user:

 ```
class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _setupFCM();
  }

  Future<void> _requestPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission on iOS
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }
  
  // More code will go here
}

```

# 4. Set up FCM message handling

Set up handlers for different states of the app:

```
void _setupFCM() {
  // Foreground messaging
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      // Show the notification as an overlay
      // You can use a package like flutter_local_notifications here
    }
  });

  // When the app is opened from a terminated state
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      print('App opened from terminated state with message: ${message.data}');
      // Navigate to appropriate screen based on the message
    }
  });

  // When the app is in the background but opened from a notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('App opened from background state with message: ${message.data}');
    // Navigate to appropriate screen based on the message
  });
}

```

# 5. Get the FCM token

To send messages to a specific device, you need to get its FCM token:

```
Future<void> _getFCMToken() async {
  String? token = await FirebaseMessaging.instance.getToken();
  print('FCM Token: $token');
  // Store this token in your database to target this specific device
}
```

## 6. Subscribe to topics (optional)

If you want to send messages to groups of devices:

```
await FirebaseMessaging.instance.subscribeToTopic('weather');
```

## 7. Permission for Android !

> On Android, the permission to receive notifications is granted by default when the app is installed. Unlike iOS, Android doesn't require explicit user permission for basic notifications.

Here's the explanation:

1.  **iOS**: Requires explicit user permission through the `requestPermission()` method, which shows a permission dialog to the user.
2.  **Android**:
    -   For basic notifications: Permission is granted automatically at installation time.
    -   The code you shared will work on both platforms - on iOS it will show the permission dialog, and on Android it will simply succeed without showing any UI.

However, there are some Android-specific considerations:

1.  **Android 13 (API level 33) and higher**: Actually does require runtime permission for posting notifications. You need to request the `POST_NOTIFICATIONS` permission.
2.  **Notification Channels**: Required on Android 8.0 (API level 26) and higher for all notifications.

Here's how you should handle permissions for a cross-platform app that works on both newer and older Android versions as well as iOS:

```
Future<void> _requestPermissions() async {
  // For iOS
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');
  
  // For Android 13+ (API level 33+)
  if (Platform.isAndroid) {
    // Check if we're on Android 13 or higher
    if (await _isAndroid13OrHigher()) {
      // Request the POST_NOTIFICATIONS permission
      await Permission.notification.request();
    }
  }
}

Future<bool> _isAndroid13OrHigher() async {
  if (Platform.isAndroid) {
    var androidInfo = await DeviceInfoPlugin().androidInfo;
    var sdkInt = androidInfo.version.sdkInt;
    return sdkInt >= 33; // Android 13 is API level 33
  }
  return false;
}

```

For this to work, you'll need to add these dependencies:

```
dependencies:
  device_info_plus: ^8.0.0
  permission_handler: ^10.0.0
  platform: ^3.1.0
```


Also, update your `AndroidManifest.xml` to include:

```
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```


So to directly answer your question:

-   For older Android versions (pre-Android 13), you don't need to request permission explicitly - it's granted by default.
-   For Android 13+, you should request the POST_NOTIFICATIONS permission.
-   The iOS permission request code you shared won't affect Android users.


## 1.1 Add Flutter Local Notifications for better handling (recommended)

For better notification handling especially on Android, add the `flutter_local_notifications` package:

```
dependencies:
  flutter_local_notifications: ^9.1.4
```

Then set it up:

```
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Initialize the plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Define notification channel for Android
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description: 'This channel is used for important notifications.', // description
  importance: Importance.high,
);

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Set the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Create notification channel on Android
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Update iOS foreground notification presentation options
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _token;
  
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _requestPermissions();
    _getFCMToken();
    _setupFCM();
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped with payload: ${response.payload}');
        // Navigate based on payload if needed
      },
    );
  }

  Future<void> _requestPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission on iOS
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
    
    // Also request permission for local notifications on iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }
  
  Future<void> _getFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    setState(() {
      _token = token;
    });
    print('FCM Token: $token');
    // Save this token to your backend for sending targeted notifications
  }
  
  void _setupFCM() {
    // Foreground messaging
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      // If `onMessage` is triggered with a notification, construct our own
      // local notification to show to users using the created channel.
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android.smallIcon,
              // other properties...
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          payload: message.data['route'],
        );
      }
    });

    // When the app is opened from a terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from terminated state with message: ${message.data}');
        _handleMessage(message);
      }
    });

    // When the app is in the background but opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background state with message: ${message.data}');
      _handleMessage(message);
    });
    
    // Subscribe to a topic (optional)
    _subscribeToTopic('all_users');
  }
  
  void _handleMessage(RemoteMessage message) {
    // Navigate to appropriate screen based on data in the message
    if (message.data['route'] != null) {
      // Navigate to the appropriate screen
      // Example:
      // Navigator.pushNamed(context, message.data['route']);
    }
  }
  
  Future<void> _subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('FCM Implementation'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Firebase Cloud Messaging Demo',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 20),
              Text(
                'Your FCM Token:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _token ?? 'Loading token...',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _getFCMToken();
                },
                child: Text('Refresh Token'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```
## 1.2 Configure platform-specific settings

### For Android:

1.  Make sure your `AndroidManifest.xml` has the necessary permissions:

```
<manifest ...>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <!-- other permissions -->
    <application ...>
        <!-- Add this for FCM service -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="high_importance_channel" />
        <!-- ... -->
    </application>
</manifest>
```

### For iOS:

1.  Update your `Info.plist` file:

```
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

## 9. Testing your implementation

You can test FCM notifications through:

1.  Firebase Console
2.  A REST API call to FCM
3.  Using Firebase Admin SDK in your backend code

I've created a complete implementation artifact that combines all these steps. Would you like me to explain any specific part of the implementation in more detail





--- 

Code Gide provided by AI


FCM Notification Service for Flutter
This is a plug-and-play Firebase Cloud Messaging (FCM) service for Flutter applications that handles notifications properly, including Android 13+ permission requirements.

Features
✅ Complete FCM integration in a single service class
✅ Proper Android 13+ (API level 33+) permission handling
✅ Background notification handling
✅ Foreground notification handling
✅ App opened from notification handling
✅ FCM token management
✅ Topic subscription support
Setup Instructions
1. Add Required Dependencies
Add these dependencies to your pubspec.yaml:

yaml
dependencies:
  firebase_core: ^2.15.1
  firebase_messaging: ^14.6.7
  permission_handler: ^11.0.0
  device_info_plus: ^9.0.3
2. Update Android Permissions
Add the following to your android/app/src/main/AndroidManifest.xml within the <manifest> tag:

xml
<!-- FCM Permissions -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.VIBRATE"/>

<!-- For Android 13+ (API level 33+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- FCM permissions for older Android versions -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
3. Add FCM Service File
Copy the fcm_service.dart file to your project.

4. Initialize the Service
Initialize Firebase and the FCM service in your main.dart:

dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FCMService().initialize();
  runApp(MyApp());
}
5. Use the Service in Your App
dart
final FCMService _fcmService = FCMService();

// Request permissions
await _fcmService.requestPermissions();

// Get FCM token
String? token = await _fcmService.getToken();

// Listen for foreground messages
_fcmService.onMessage.listen((message) {
  // Handle foreground message
});

// Listen for app opened from notification
_fcmService.onMessageOpenedApp.listen((message) {
  // Handle app opened from notification
});

// Subscribe to a topic
await _fcmService.subscribeToTopic('news');
Handling iOS
For iOS, you need to add capabilities in Xcode:

Open Runner.xcworkspace in Xcode
Go to the Runner target's "Signing & Capabilities" tab
Add the "Push Notifications" capability
Add the "Background Modes" capability and check "Remote notifications"
Troubleshooting
If notifications aren't working:

Check that you've initialized Firebase correctly
Verify permissions are granted
Make sure your FCM token is valid and registered with your server
Check the Android manifest permissions
For iOS, verify the required capabilities are enabled
License
This code is available under the MIT License.


