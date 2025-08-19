import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

const notificationChannelId = 'pnp_location_service';
const notificationId = 888;

Future<void> initializeService() async {
  try {
    print('BackgroundService: Starting initialization...');
    
    final service = FlutterBackgroundService();

    // Create notification channel for Android
    await _createNotificationChannel();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'PNP Device Monitor Active',
        initialNotificationContent: 'Monitoring device location and status',
        foregroundServiceNotificationId: notificationId,
        autoStartOnBoot: false,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
    
    print('BackgroundService: Initialization completed successfully');
  } catch (e, stackTrace) {
    print('BackgroundService: Initialization failed: $e');
    print('BackgroundService: Stack trace: $stackTrace');
    // Don't rethrow - let the app continue without background service
  }
}

Future<void> _createNotificationChannel() async {
  try {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'PNP Location Service',
      description: 'Keeps the PNP Device Monitor running in background',
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: false,
      showBadge: true,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    print('BackgroundService: Notification channel created');
  } catch (e) {
    print('BackgroundService: Error creating notification channel: $e');
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  try {
    DartPluginRegistrant.ensureInitialized();
    print('BackgroundService: iOS background service started');
    return true;
  } catch (e) {
    print('BackgroundService: Error in iOS background: $e');
    return false;
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    DartPluginRegistrant.ensureInitialized();
    print('BackgroundService: Service started successfully');

    // Initial notification
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "PNP Device Monitor",
        content: "Service starting...",
      );
    }

    // Listen for stop service requests
    service.on('stopService').listen((event) {
      print('BackgroundService: Stop service requested');
      try {
        service.stopSelf();
        print('BackgroundService: Service stopped');
      } catch (e) {
        print('BackgroundService: Error stopping service: $e');
      }
    });

    // Update notification immediately to show it's running
    Timer(const Duration(seconds: 2), () {
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "PNP Device Monitor Active",
          content: "Background monitoring enabled - Tap to open app",
        );
      }
    });

    // Periodic updates every 30 seconds
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        final deploymentCode = prefs.getString('deploymentCode');
        
        if (token == null || deploymentCode == null) {
          print('BackgroundService: No credentials found, stopping service');
          timer.cancel();
          service.stopSelf();
          return;
        }

        final now = DateTime.now();
        final timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        
        // Get current location
        final position = await _getCurrentLocationSafe();
        
        if (position != null) {
          // Update notification with current time and location status
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: "PNP Device Monitor Active",
              content: "Last update: $timeString • Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}",
            );
          }
          
          print('BackgroundService: Location update - ${position.latitude}, ${position.longitude}');
          
          // Here you can send location to your API
          await _sendLocationToAPI(token, deploymentCode, position);
        } else {
          // Update notification even if location is not available
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: "PNP Device Monitor Active",
              content: "Last update: $timeString • Location: Unavailable",
            );
          }
        }
        
      } catch (e) {
        print('BackgroundService: Error in periodic task: $e');
        // Update notification with error status
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "PNP Device Monitor Active",
            content: "Service running with limited functionality",
          );
        }
      }
    });
    
  } catch (e, stackTrace) {
    print('BackgroundService: Error in onStart: $e');
    print('BackgroundService: Stack trace: $stackTrace');
  }
}

Future<Position?> _getCurrentLocationSafe() async {
  try {
    // Check permissions first
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      print('BackgroundService: Location permission denied');
      return null;
    }

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('BackgroundService: Location services disabled');
      return null;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 15),
    );
    
    return position;
  } catch (e) {
    print('BackgroundService: Error getting location: $e');
    return null;
  }
}

Future<void> _sendLocationToAPI(String token, String deploymentCode, Position position) async {
  try {
    // Here you can add your API call
    // This is just a placeholder - replace with your actual API service
    print('BackgroundService: Would send location to API: ${position.latitude}, ${position.longitude}');
    
    // Example:
    // await ApiService.updateLocation(
    //   token: token,
    //   deploymentCode: deploymentCode,
    //   position: position,
    //   batteryLevel: 80, // You'd get this from device service
    //   signalStrength: 'good',
    // );
    
  } catch (e) {
    print('BackgroundService: Error sending location to API: $e');
  }
}

// Helper function to start service safely
Future<bool> startBackgroundServiceSafely() async {
  try {
    print('BackgroundService: Attempting to start service...');
    
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    
    if (isRunning) {
      print('BackgroundService: Service already running');
      return true;
    }
    
    final started = await service.startService();
    print('BackgroundService: Service start result: $started');
    
    // Give it a moment to start properly
    await Future.delayed(const Duration(seconds: 1));
    
    return started;
  } catch (e) {
    print('BackgroundService: Error starting service: $e');
    return false;
  }
}

// Helper function to stop service safely
Future<bool> stopBackgroundServiceSafely() async {
  try {
    print('BackgroundService: Attempting to stop service...');
    
    final service = FlutterBackgroundService();
    service.invoke("stopService");
    
    // Wait a bit for the service to stop
    await Future.delayed(const Duration(milliseconds: 1000));
    
    print('BackgroundService: Stop request sent');
    return true;
  } catch (e) {
    print('BackgroundService: Error stopping service: $e');
    return false;
  }
}