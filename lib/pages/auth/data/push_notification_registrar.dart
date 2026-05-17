import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'profile_repository.dart';

class PushNotificationRegistrar {
  PushNotificationRegistrar({
    required ProfileRepository profileRepository,
    FirebaseMessaging? messaging,
  }) : _profileRepository = profileRepository,
       _messaging = messaging ?? FirebaseMessaging.instance;

  final ProfileRepository _profileRepository;
  final FirebaseMessaging _messaging;

  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _registeredUserId;

  Future<void> registerForUser({required String userId}) async {
    if (Firebase.apps.isEmpty) {
      return;
    }

    _registeredUserId = userId;
    await _messaging.setAutoInitEnabled(true);

    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    final String? token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _profileRepository.updatePushToken(
        userId: userId,
        pushToken: token,
      );
    }

    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((
      String nextToken,
    ) async {
      final String? currentUserId = _registeredUserId;
      if (currentUserId == null || nextToken.isEmpty) {
        return;
      }
      await _profileRepository.updatePushToken(
        userId: currentUserId,
        pushToken: nextToken,
      );
    });
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }
}
