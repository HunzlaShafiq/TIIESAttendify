import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';


class GoogleMapProvider with ChangeNotifier {
  GoogleMapProvider() {
    loadOfficeMarkerIcon();
    getUserCurrentLocation();


  }

  Timer? _locationTimer;
  bool _mapReady = false;



  String _currentPlaceName = "Fetching location...";
  String get currentPlaceName => _currentPlaceName;

  /// ================= OFFICE GEOFENCE =================
  static const LatLng _officeLatLng =
  LatLng(30.677090, 73.082989); // TIIES Sahiwal

  BitmapDescriptor? _officeMarkerIcon;


  static const double _allowedRadiusInMeters = 100; // 100 meters
  double get allowedRadius => _allowedRadiusInMeters;

  double _distanceFromOffice = 0;
  double get distanceFromOffice => _distanceFromOffice;

  bool _attendanceAllowed = false;
  bool get attendanceAllowed => _attendanceAllowed;

  String get formattedDistance {
    if (_distanceFromOffice < 1000) {
      return "${_distanceFromOffice.toStringAsFixed(1)} m";
    }
    return "${(_distanceFromOffice / 1000).toStringAsFixed(2)} km";
  }



  bool _mapLoading = true;
  bool get mapLoading => _mapLoading;

  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? _mapController;

  LatLng _userCurrentLatLng = const LatLng(0, 0);
  LatLng get userCurrentLatLng => _userCurrentLatLng;

  Set<Marker> _userCurrentMarker = {};
  Set<Marker> get userCurrentMarker => _userCurrentMarker;

  CameraPosition _currentPosition = const CameraPosition(
    target: LatLng(30.677717, 73.106812),
    zoom: 15.4,
  );

  CameraPosition get currentPosition => _currentPosition;

  // ================= MAP CREATED =================
  void onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
      _mapController = controller;
      _mapReady = true;
    }
  }

  // ================= LOCATION =================
  Future<void> getUserCurrentLocation() async {
    _mapLoading = false;
    await Geolocator.requestPermission();

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _userCurrentLatLng =
        LatLng(position.latitude, position.longitude);

    _currentPosition = CameraPosition(
      target: _userCurrentLatLng,
      zoom: 14,
    );

    await updatePlaceName();
    setMarkers();
    checkAttendanceEligibility();
    startAutoLocationCheck();
    notifyListeners();
  }

  void setMarkers() {
    _userCurrentMarker = {
      Marker(
        markerId: const MarkerId('office'),
        position: _officeLatLng,
        icon: _officeMarkerIcon ??  BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueMagenta,
        ),
        infoWindow:
        const InfoWindow(title: "TIIES SAHIWAL"),
      ),
      Marker(
        markerId: const MarkerId('current'),
        position: _userCurrentLatLng,
        infoWindow:
        const InfoWindow(title: "Emoplyee Current Location"),
      ),
    };
  }

  // ================= AUTO UPDATE =================
  void startAutoLocationCheck() {
    _locationTimer?.cancel();

    _locationTimer = Timer.periodic(
      const Duration(seconds: 3),
          (_)  {
               _updateLiveLocation();
        },
    );
  }

  Future<void> _updateLiveLocation() async {
    if (!_mapReady) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      _userCurrentLatLng =
          LatLng(position.latitude, position.longitude);
      bool distanceChanged = checkDistanceChanged() >= 5;


      if(distanceChanged){
        
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(_userCurrentLatLng),
          );
        }
        await updatePlaceName();
        checkAttendanceEligibility();
        setMarkers();

        notifyListeners();
      }

    } catch (_) {}
  }

  // ================= CLEANUP =================
  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }






  Future<void> updatePlaceName() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _userCurrentLatLng.latitude,
        _userCurrentLatLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        _currentPlaceName =
            "${place.subLocality ?? ''} ${place.locality ?? ''}".trim();

        if (_currentPlaceName.isEmpty) {
          _currentPlaceName = place.administrativeArea ?? "Unknown location";
        }
      }
    } catch (e) {
      _currentPlaceName = "Location unavailable";
    }
  }




  void checkAttendanceEligibility() {
    _distanceFromOffice = checkDistanceChanged();

    _attendanceAllowed = _distanceFromOffice <=allowedRadius;
  }

  Future<void> loadOfficeMarkerIcon() async {
    _officeMarkerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(
        size: Size(20, 20),
        devicePixelRatio: 2.5,),
      'assets/TIIESLogo.png',
    );
  }


  double checkDistanceChanged(){

    return  Geolocator.distanceBetween(
      _officeLatLng.latitude,
      _officeLatLng.longitude,
      _userCurrentLatLng.latitude,
      _userCurrentLatLng.longitude,
    );
  }








}
