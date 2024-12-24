import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:frontend_daktmt/custom_card.dart';

// ignore: camel_case_types
class map extends StatefulWidget {
  const map({
    super.key,
    required this.mapHeight,
    required this.mapWidth,
    required this.latitude,
    required this.longitude,
  });

  final double mapHeight;
  final double mapWidth;
  final double latitude;
  final double longitude;

  @override
  // ignore: library_private_types_in_public_api
  _mapState createState() => _mapState();
}

// ignore: camel_case_types
class _mapState extends State<map> {
  LatLng? _deviceLocation;
  late final LatLng _locationA;

  @override
  void initState() {
    super.initState();
    _locationA = LatLng(widget.latitude, widget.longitude);
    _requestLocationPermission(); // Yêu cầu quyền truy cập vị trí ngay khi khởi tạo
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Kiểm tra xem dịch vụ định vị có được bật không
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are not turned on.')),
      );
      return;
    }

    // Kiểm tra quyền truy cập vị trí
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location access has been denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('The location access is permanently denied.')),
      );
      return;
    }

    _getCurrentLocation(); // Lấy vị trí của người dùng nếu quyền đã được cấp
  }

  // Future<void> _getCurrentLocation() async {
  //   try {
  //     final position = await Geolocator.getCurrentPosition();
  //     setState(() {
  //       _deviceLocation = LatLng(position.latitude, position.longitude);
  //     });
  //   } catch (e) {
  //     // ignore: use_build_context_synchronously
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Unable to get a location: $e')),
  //     );
  //   }
  // }
  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _deviceLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to get a location: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: SizedBox(
        height: widget.mapHeight,
        width: widget.mapWidth,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: _deviceLocation ?? _locationA,
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://api.maptiler.com/maps/basic/{z}/{x}/{y}.png?key=pqZwfqHFA5XexcvOOXeb',
              subdomains: const ['a', 'b', 'c'],
            ),
            MarkerLayer(
              markers: [
                if (_deviceLocation != null)
                  Marker(
                    point: _deviceLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.emoji_people,
                      size: 40.0,
                      color: Colors.blue,
                    ),
                  ),
                Marker(
                  point: _locationA,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_on,
                    size: 40.0,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
