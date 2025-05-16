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

