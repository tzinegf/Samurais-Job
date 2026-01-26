import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';

class LocationPickerView extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerView({Key? key, this.initialLocation}) : super(key: key);

  @override
  _LocationPickerViewState createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<LocationPickerView> {
  late LatLng _currentCenter;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Default to São Paulo center if no initial location
    _currentCenter = widget.initialLocation ?? LatLng(-23.55052, -46.633309);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selecionar Localização'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              Get.back(result: _currentCenter);
            },
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _currentCenter = position.center;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.samurais_job',
              ),
            ],
          ),
          Center(
            child: Icon(
              Icons.location_pin,
              color: Colors.red,
              size: 48,
            ),
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: () {
                Get.back(result: _currentCenter);
              },
              child: Text('Confirmar Localização'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Color(0xFFDE3344),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
