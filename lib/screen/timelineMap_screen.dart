import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../providers/location_provider.dart';

class TimelineMapScreen extends StatefulWidget {
  const TimelineMapScreen({super.key});
  @override
  State<TimelineMapScreen> createState() => _TimelineMapScreenState();
}

class _TimelineMapScreenState extends State<TimelineMapScreen> {
  DateTime selectedDate = DateTime.now();
  bool _isToday = true;
  List<LatLng> _points = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Completer<GoogleMapController> _controller = Completer();
  bool _isMapLoading = true;

  // For live tracking
  Marker? _liveLocationMarker;
  Timer? _liveUpdateTimer;

  @override
  void initState() {
    super.initState();
    _checkIfToday();
    _loadForDate(selectedDate);
  }

  @override
  void dispose() {
    _liveUpdateTimer?.cancel();
    super.dispose();
  }

  void _checkIfToday() {
    final now = DateTime.now();
    _isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  Future<void> _loadForDate(DateTime date) async {
    setState(() {
      _isMapLoading = true;
    });

    final ds = DateFormat('yyyy-MM-dd').format(date);
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail') ?? '';

    final rows = await DBHelper.instance.getLocationsByDate(ds, email: email);

    print('Loaded ${rows.length} locations for date: $ds');

    final pts = rows.map((r) {
      final lat = (r['latitude'] is int) ? (r['latitude'] as int).toDouble() : r['latitude'] as double;
      final lng = (r['longitude'] is int) ? (r['longitude'] as int).toDouble() : r['longitude'] as double;
      return LatLng(lat, lng);
    }).toList();

    Set<Marker> markers = {};
    Set<Polyline> polylines = {};

    if (pts.isNotEmpty) {
      // Add start marker
      markers.add(Marker(
        markerId: const MarkerId('start'),
        position: pts.first,
        infoWindow: InfoWindow(
          title: 'Start Point',
          snippet: 'Time: ${DateFormat('hh:mm a').format(DateTime.parse(rows.first['timestamp']))}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));

      // Add end marker
      markers.add(Marker(
        markerId: const MarkerId('end'),
        position: pts.last,
        infoWindow: InfoWindow(
          title: 'End Point',
          snippet: 'Time: ${DateFormat('hh:mm a').format(DateTime.parse(rows.last['timestamp']))}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));

      // Add polyline
      polylines.add(Polyline(
        polylineId: const PolylineId('path'),
        points: pts,
        width: 5,
        color: Colors.blue,
      ));

      // Center camera on the path
      final bounds = _calculateBounds(pts);

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (await _controller.future != null) {
          final ctl = await _controller.future;
          await ctl.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
        }
      });
    }

    setState(() {
      _points = pts;
      _markers = markers;
      _polylines = polylines;
      _isMapLoading = false;
    });

    // If it's today, start live location updates
    if (_isToday) {
      _startLiveUpdates();
    } else {
      _stopLiveUpdates();
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    if (points.isEmpty) {
      // Default bounds if no points
      return LatLngBounds(
        southwest: const LatLng(51.5074, -0.1278), // London
        northeast: const LatLng(51.5074, -0.1278),
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    // Add some padding
    minLat -= 0.001;
    maxLat += 0.001;
    minLng -= 0.001;
    maxLng += 0.001;

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _checkIfToday();
      });
      await _loadForDate(picked);
    }
  }

  void _startLiveUpdates() {
    // Clear any existing timer
    _liveUpdateTimer?.cancel();

    final locProvider = Provider.of<LocationProvider>(context, listen: false);

    // Start listening to location updates
    locProvider.startLiveLocationUpdates();

    // Update UI every 5 seconds to show current location
    _liveUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (locProvider.currentPosition != null) {
        final pos = locProvider.currentPosition!;
        final currentLatLng = LatLng(pos.latitude, pos.longitude);

        setState(() {
          // Update or add live location marker
          _liveLocationMarker = Marker(
            markerId: const MarkerId('live_location'),
            position: currentLatLng,
            infoWindow: const InfoWindow(title: 'Current Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            anchor: const Offset(0.5, 0.5),
            rotation: pos.heading,
          );

          // Add to markers set
          _markers = {..._markers};
          if (_liveLocationMarker != null) {
            _markers.add(_liveLocationMarker!);
          }
        });

        // Animate camera to follow location
        try {
          final ctl = await _controller.future;
          await ctl.animateCamera(CameraUpdate.newLatLng(currentLatLng));
        } catch (e) {
          print('Error animating camera: $e');
        }
      }
    });
  }

  void _stopLiveUpdates() {
    _liveUpdateTimer?.cancel();
    _liveUpdateTimer = null;

    final locProvider = Provider.of<LocationProvider>(context, listen: false);
    locProvider.stopLiveLocationUpdates();

    setState(() {
      _liveLocationMarker = null;
    });
  }

  void _centerOnLiveLocation() async {
    final locProvider = Provider.of<LocationProvider>(context, listen: false);
    if (locProvider.currentPosition != null) {
      final pos = locProvider.currentPosition!;
      try {
        final ctl = await _controller.future;
        await ctl.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(pos.latitude, pos.longitude),
          17,
        ));
      } catch (e) {
        print('Error centering on location: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locProvider = Provider.of<LocationProvider>(context);

    return Scaffold(

      appBar: AppBar(
        backgroundColor: Color(0xff0AA2E8),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('${DateFormat.yMMMd().format(selectedDate)} ${_isToday ? '(Live)' : ''}',style: TextStyle(
          color: Colors.white
        ),),
        actions: [
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month,
                  color: Colors.white
              ),
          ),

        ],
      ),

      body: Stack(
        children: [
          // Google Map
          _buildMap(),

          // Loading indicator
          if (_isMapLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // No data message (only shows when no points and not today)
          if (!_isMapLoading && _points.isEmpty && !_isToday)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No location data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No location data available for selected date',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

          // Live location button (if today)
          if (_isToday && locProvider.currentPosition != null)
            Positioned(
              bottom: 100,
              right: 20,
              child: FloatingActionButton.small(
                onPressed: _centerOnLiveLocation,
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
            ),

          // Info card at bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isToday ? 'Live Tracking Active' : 'Historical Data',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Points: ${_points.length}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (_points.isNotEmpty)
                    Text(
                      'Distance: ${_calculateTotalDistance().toStringAsFixed(2)} km',
                      style: const TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final locProvider = Provider.of<LocationProvider>(context);

    // Determine initial position
    LatLng initialPosition;
    double initialZoom = 12;

    if (_points.isNotEmpty) {
      initialPosition = _points.first;
      initialZoom = 15;
    } else if (locProvider.currentPosition != null) {
      initialPosition = LatLng(
        locProvider.currentPosition!.latitude,
        locProvider.currentPosition!.longitude,
      );
      initialZoom = 15;
    } else {
      // Default position (you can set to your city or use device location)
      initialPosition = const LatLng(0, 0);
      initialZoom = 2;
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: initialZoom,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapType: MapType.normal,
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);

        // If we have points, center the map
        if (_points.isNotEmpty) {
          final bounds = _calculateBounds(_points);
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
          });
        }
      },
      onCameraIdle: () {
        // Camera movement stopped
      },
      onCameraMove: (CameraPosition position) {
        // Camera is moving
      },
    );
  }

  double _calculateTotalDistance() {
    double total = 0;
    for (int i = 1; i < _points.length; i++) {
      total += _calculateDistance(_points[i - 1], _points[i]);
    }
    return total;
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const R = 6371.0; // Earth's radius in kilometers
    final lat1 = p1.latitude * math.pi / 180.0;
    final lon1 = p1.longitude * math.pi / 180.0;
    final lat2 = p2.latitude * math.pi / 180.0;
    final lon2 = p2.longitude * math.pi / 180.0;

    final dlat = lat2 - lat1;
    final dlon = lon2 - lon1;

    final a = math.sin(dlat / 2) * math.sin(dlat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) * math.sin(dlon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }
}