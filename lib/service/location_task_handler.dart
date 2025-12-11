import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _stream;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail') ?? 'unknown';

    final settings = const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 10,
    );

    _stream = Geolocator.getPositionStream(locationSettings: settings)
        .listen((pos) async {

          print("pos===== ${pos}");

      final now = DateTime.now();
      final date = DateFormat('yyyy-MM-dd').format(now);

          try {
            final id = await DBHelper.instance.insertLocation({
              "email": email,
              "latitude": pos.latitude,
              "longitude": pos.longitude,
              "timestamp": now.toIso8601String(),
              "date": date,
            });

            print("✔ Inserted into DB, row id = $id");

          } catch (e) {
            print("❌ DB Insert Error: $e");
          }
    });
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool willBeRestarted) async {
    await _stream?.cancel();
  }

  @override
  void onButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}
}
