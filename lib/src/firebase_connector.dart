import 'package:tencent_flutter_apns/src/connector.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebasePushConnector extends PushConnector {
  @override
  final isDisabledByUser = ValueNotifier<bool?>(null);

  bool didInitialize = false;
  String? name;

  @override
  Future<void> configure({
    MessageHandler? onMessage,
    MessageHandler? onLaunch,
    MessageHandler? onResume,
    MessageHandler? onBackgroundMessage,
    FirebaseOptions? options,
    String? name,
  }) async {
    this.name = name;
    late FirebaseMessaging firMsg;
    if (name != null) {
      firMsg = FirebaseMessaging.instanceFor(name);
    } else {
      firMsg = FirebaseMessaging.instance;
    }
    if (!didInitialize) {
      await Firebase.initializeApp(
        name: name,
        options: options,
      );
      didInitialize = true;
    }

    firMsg.onTokenRefresh.listen((value) {
      token.value = value;
    });

    FirebaseMessaging.onMessage.listen(onMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(onResume);

    if (onBackgroundMessage != null) {
      FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
    }
    final initial = await firMsg.getInitialMessage();
    if (initial != null) {
      onLaunch?.call(initial);
    }

    token.value = await firMsg.getToken();
  }

  @override
  final token = ValueNotifier(null);

  @override
  void requestNotificationPermissions() async {
    late FirebaseMessaging firMsg;
    if (name != null) {
      firMsg = FirebaseMessaging.instanceFor(name!);
    } else {
      firMsg = FirebaseMessaging.instance;
    }
    if (!didInitialize) {
      await Firebase.initializeApp();
      didInitialize = true;
    }

    NotificationSettings permissions = await firMsg.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (permissions.authorizationStatus.name == 'authorized') {
      isDisabledByUser.value = false;
    } else if (permissions.authorizationStatus.name == 'denied') {
      isDisabledByUser.value = true;
    }
  }

  @override
  String get providerType => 'GCM';

  @override
  Future<void> unregister() async {
    late FirebaseMessaging firMsg;
    if (name != null) {
      firMsg = FirebaseMessaging.instanceFor(name!);
    } else {
      firMsg = FirebaseMessaging.instance;
    }
    await firMsg.setAutoInitEnabled(false);
    await firMsg.deleteToken();

    token.value = null;
  }
}
