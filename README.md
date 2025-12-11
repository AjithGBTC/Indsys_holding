# indsys_holding

**Authentication**
Firebase Email/Password login
Session persistence using shared_preferences
Auto-login until user logs out

**Background Location Tracking**
Background tracking powered by flutter_foreground_task
Uses geolocator for accurate GPS data
Collects:
latitude
longitude
timestamp
date
user email

Writes entries to SQLite database (sqflite)
Tracking runs even if the app is minimized or closed

**Timeline Visualization**
Google Maps integration using google_maps_flutter
Draws route polyline for selected date
Start/End markers
Date picker to select timeline day
Loads persisted location data from local database

**Core Architecture**

State Management: Provider
Local Database: SQLite
Background Execution: Foreground service
Auth: Firebase Authentication
Session Storage: SharedPreferences
Location: Geolocator
