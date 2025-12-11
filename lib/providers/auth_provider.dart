import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/location_provider.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;

  User? get user => _auth.currentUser;
  bool get isLoggedIn => user != null;

  // SIGNUP
  Future<String?> signup(BuildContext context,
      {required String email, required String password}) async {
    try {
      isLoading = true;
      notifyListeners();

      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('loggedIn', true);
      await prefs.setString('userEmail', email);

      // Request location permission & start foreground task
      final loc = LocationProvider();
      final ok = await loc.requestPermission();
      if (!ok) {
        isLoading = false;
        notifyListeners();
        return 'Location permission not granted';
      }

      isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // LOGIN
  Future<String?> login(BuildContext context,
      {required String email, required String password}) async {
    try {
      isLoading = true;
      notifyListeners();

      // Try login
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Save session info
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('loggedIn', true);
      await prefs.setString('userEmail', email);

      // Request location permission
      final loc = LocationProvider();
      final ok = await loc.requestPermission();
      if (!ok) {
        isLoading = false;
        notifyListeners();
        return 'Location permission not granted';
      }

      isLoading = false;
      notifyListeners();
      return null; // success
    } on FirebaseAuthException catch (e) {
      // Optionally create user if not found
      if (e.code == 'user-not-found') {
        final signupRes =
        await signup(context, email: email, password: password);
        return signupRes; // null if success
      }

      isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }


  // LOGOUT
  Future<void> logout(BuildContext context) async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('loggedIn', false);
    await prefs.remove('userEmail');

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }

    notifyListeners();
  }

  static Future<bool> checkLoggedInFlag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('loggedIn') ?? false;
  }
}
