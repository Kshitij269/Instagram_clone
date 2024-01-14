import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print("Title: ${message.notification?.title}");
  print("Body: ${message.notification?.body}");
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    // Platform messages are inefficient for this use-case, so we're using a
    // common subscribe method that works on both native and web.
    String? token = await _firebaseMessaging.getToken();
    print('FlutterFire Messaging Token: $token');
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  }
}
