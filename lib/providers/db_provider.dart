import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

class DBProvider extends ChangeNotifier {
  List<Map<String, dynamic>> dayLocations = [];

  Future<void> loadLocationsByDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final String? email = prefs.getString('userEmail');
    dayLocations = await DBHelper.instance.getLocationsByDate(date, email: email);
    notifyListeners();
  }

  void clear() {
    dayLocations = [];
    notifyListeners();
  }
}
