import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../db/database_helper.dart';
import '../../models/owner.dart';
import '../../models/cabinet.dart';

class VeterinaryMapView extends StatefulWidget {
  final List<Owner> vets;

  const VeterinaryMapView({Key? key, required this.vets}) : super(key: key);

  @override
  State<VeterinaryMapView> createState() => _VeterinaryMapViewState();
}

class _VeterinaryMapViewState extends State<VeterinaryMapView> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  Map<int, Cabinet?> _cabinets = {};

  static const Color primaryPurple = Color(0xFF7C4DFF);
  static const Color lightPurple = Color(0xFF9575CD);
  static const Color accentOrange = Color(0xFFFF7043);
  static const Color lightPurpleBackground = Color(0xFFF3E5F5);

  @override
  void initState() {
    super.initState();
    _loadCabinets();
  }

  Future<void> _loadCabinets() async {
    final Map<int, Cabinet?> temp = {};
    for (final vet in widget.vets) {
      final cabinet = await DatabaseHelper.instance.getCabinetForVet(vet.id!);
      temp[vet.id!] = cabinet;
    }

    setState(() {
      _cabinets = temp;
      _markers = _createMarkers();
    });
  }

  List<Marker> _createMarkers() {
    final markers = <Marker>[];
    for (final vet in widget.vets) {
      final cabinet = _cabinets[vet.id];
      if (cabinet != null &&
          cabinet.latitude != null &&
          cabinet.longitude != null) {
        markers.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(cabinet.latitude!, cabinet.longitude!),
            child: const Icon(
              Icons.location_pin,
              color: accentOrange,
              size: 40,
            ),
          ),
        );
      }
    }
    return markers;
  }

  void _goToVeterinary(Owner vet) {
    final cabinet = _cabinets[vet.id];
    if (cabinet != null &&
        cabinet.latitude != null &&
        cabinet.longitude != null) {
      _mapController.move(LatLng(cabinet.latitude!, cabinet.longitude!), 15.0);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte des Vétérinaires'),
        backgroundColor: primaryPurple,
      ),
      body: _cabinets.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            flex: 6,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _getInitialCenter(),
                initialZoom: 11.0,
                onMapReady: () {
                  if (_markers.length > 1) {
                    _mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: _boundsFromMarkers(),
                        padding: const EdgeInsets.all(50.0),
                      ),
                    );
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: lightPurpleBackground.withOpacity(0.3),
                border: Border(
                  top: BorderSide(
                    color: primaryPurple.withOpacity(0.2),
                    width: 2,
                  ),
                ),
              ),
              child: _buildVetList(),
            ),
          ),
        ],
      ),
    );
  }

  LatLng _getInitialCenter() {
    for (final cabinet in _cabinets.values) {
      if (cabinet?.latitude != null && cabinet?.longitude != null) {
        return LatLng(cabinet!.latitude!, cabinet.longitude!);
      }
    }
    return const LatLng(36.8065, 10.1815); // Tunis par défaut
  }

  LatLngBounds _boundsFromMarkers() {
    return LatLngBounds.fromPoints(_markers.map((m) => m.point).toList());
  }

  Widget _buildVetList() {
    final vetsWithCabinet = widget.vets.where((v) {
      final c = _cabinets[v.id];
      return c != null && c.latitude != null && c.longitude != null;
    }).toList();

    if (vetsWithCabinet.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off,
                size: 64, color: lightPurple.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              "Aucun vétérinaire avec un cabinet localisé.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: vetsWithCabinet.length,
      itemBuilder: (context, index) {
        final vet = vetsWithCabinet[index];
        final cabinet = _cabinets[vet.id];
        final address = cabinet?.address ?? 'Adresse non spécifiée';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 2,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: lightPurpleBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_pin_circle,
                color: primaryPurple,
                size: 28,
              ),
            ),
            title: Text(
              'Dr. ${vet.name}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryPurple,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: const Icon(
              Icons.my_location,
              color: accentOrange,
            ),
            onTap: () => _goToVeterinary(vet),
          ),
        );
      },
    );
  }
}
