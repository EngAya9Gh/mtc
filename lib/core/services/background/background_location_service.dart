import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../di/di_container.dart';
import '../../utils/end_points.dart';

class BackgroundLocationService {
  static final BackgroundLocationService _instance = BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  static const String notificationChannelId = 'background_location_channel';
  static const int notificationId = 888;

  Future<void> initialize() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId, // id
      'Location Tracking Service', // title
      description: 'This channel is used for background location tracking.', // description
      importance: Importance.low, // low importance prevents sound
    );

    if (!kIsWeb) {
      final dynamic flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      // Create channel on the device
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'خدمة التتبع تعمل',
        initialNotificationContent: 'يتم الآن تتبع الموقع في الخلفية',
        foregroundServiceNotificationId: notificationId,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  Future<void> startService() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
  }

  Future<void> stopService() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke('stopService');
    }
  }
}

// Ensure this is a top-level function
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  // For UI communication
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Init necessary background dependencies
  final prefs = await SharedPreferences.getInstance();
  final dio = Dio(BaseOptions(
    baseUrl: EndPoints.debugBaseUrl, // Using debug base url as per project rules
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  Position? latestPosition;

  // 1. Fetch location every 30 seconds
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        latestPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
      }
    } catch (e) {
      debugPrint('Background Location Fetch Error: $e');
    }
  });

  // 2. Send location to server every 120 seconds
  Timer.periodic(const Duration(seconds: 120), (timer) async {
    if (latestPosition == null) return;

    try {
      final token = prefs.getString('api_token');
      final driverId = prefs.getInt('driver_id'); // We need to make sure driver_id is saved

      if (token != null && driverId != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
        
        final response = await dio.post(
          EndPoints.updateLocation,
          data: {
            'driver_id': driverId,
            'lat': latestPosition!.latitude.toString(),
            'lng': latestPosition!.longitude.toString(),
          },
        );
        debugPrint('Location Update API Response: ${response.data}');
      }
    } catch (e) {
      debugPrint('Background Location API Error: $e');
    }
  });
}
