import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_repository.dart';

class PushNotificationRegistrar {
  PushNotificationRegistrar({
    required ProfileRepository profileRepository,
    FirebaseMessaging? messaging,
  }) : _profileRepository = profileRepository,
       _messaging = messaging ?? FirebaseMessaging.instance;

  final ProfileRepository _profileRepository;
  final FirebaseMessaging _messaging;

  static const String _pushPreferenceKey =
      'mindfulconnect.push_notifications_enabled';

  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _registeredUserId;

  Future<bool> isEnabled() async {
    if (Firebase.apps.isEmpty) {
      return false;
    }

    final bool localPreference = await _isLocallyEnabled();
    if (!localPreference) {
      return false;
    }

    final NotificationSettings settings = await _messaging
        .getNotificationSettings();
    return _isAuthorized(settings.authorizationStatus);
  }

  Future<void> syncTokenIfAuthorized({required String userId}) async {
    if (Firebase.apps.isEmpty) {
      return;
    }

    final NotificationSettings settings = await _messaging
        .getNotificationSettings();
    if (!await _isLocallyEnabled() ||
        !_isAuthorized(settings.authorizationStatus)) {
      return;
    }

    _registeredUserId = userId;
    await _messaging.setAutoInitEnabled(true);
    await _registerCurrentToken(userId: userId);
    _listenTokenRefresh();
  }

  Future<bool> requestPermissionAndRegisterForUser({
    required String userId,
  }) async {
    if (Firebase.apps.isEmpty) {
      return false;
    }

    _registeredUserId = userId;
    await _messaging.setAutoInitEnabled(true);
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (!_isAuthorized(settings.authorizationStatus)) {
      return false;
    }

    await _setLocallyEnabled(true);
    await _registerCurrentToken(userId: userId);
    _listenTokenRefresh();
    return true;
  }

  Future<void> disableForUser({required String userId}) async {
    await _setLocallyEnabled(false);
    if (Firebase.apps.isNotEmpty) {
      await _messaging.setAutoInitEnabled(false);
      await _messaging.deleteToken();
    }
    _registeredUserId = null;
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    await _profileRepository.updatePushToken(userId: userId, pushToken: null);
  }

  Future<void> _registerCurrentToken({required String userId}) async {
    final String? token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _profileRepository.updatePushToken(
        userId: userId,
        pushToken: token,
      );
    }
  }

  void _listenTokenRefresh() {
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

  bool _isAuthorized(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  Future<bool> _isLocallyEnabled() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_pushPreferenceKey) ?? true;
  }

  Future<void> _setLocallyEnabled(bool value) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_pushPreferenceKey, value);
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }
}
