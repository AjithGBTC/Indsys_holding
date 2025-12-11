// location_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../service/location_task_handler.dart';

class LocationProvider extends ChangeNotifier {
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  StreamSubscription<Position>? _locationStream;
  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> startForegroundLocation() async {
    final ok = await requestPermission();
    if (!ok) {
      print('Location permission not granted');
      return;
    }

    if (_isRunning) {
      print('Already running');
      return;
    }

    // Get current position first
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('Initial position: $_currentPosition');
      await _storeLocation(_currentPosition!);
    } catch (e) {
      print('Error getting initial position: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("userEmail") ?? "";

    print('Starting foreground service for user: $email');

    await FlutterForegroundTask.startService(
      notificationTitle: 'Location Tracking',
      notificationText: 'Recording location in background...',
      callback: startCallback,
    );

    _isRunning = true;
    notifyListeners();
  }

  Future<void> _storeLocation(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("userEmail") ?? "";
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);

      print('Storing location: ${position.latitude}, ${position.longitude} for $email');

      final id = await DBHelper.instance.insertLocation({
        "email": email,
        "latitude": position.latitude,
        "longitude": position.longitude,
        "timestamp": now.toIso8601String(),
        "date": today,
      });

      print('Location stored with ID: $id');
    } catch (e) {
      print('Error storing location: $e');
    }
  }

  Future<void> stopForegroundLocation() async {
    if (!_isRunning) return;

    await FlutterForegroundTask.stopService();
    await _locationStream?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  // Method to get real-time location updates for current date
  void startLiveLocationUpdates() {
    _locationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      _currentPosition = position;
      _storeLocation(position);
      notifyListeners();
    });
  }

  // Stop live updates
  void stopLiveLocationUpdates() {
    _locationStream?.cancel();
    _currentPosition = null;
  }

  @override
  void dispose() {
    _locationStream?.cancel();
    super.dispose();
  }
}