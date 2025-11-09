import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/veterinary.dart';

class VeterinaryMapView extends StatefulWidget {
  final List<Veterinary> vets;

  const VeterinaryMapView({Key? key, required this.vets}) : super(key: key);

  @override
  VeterinaryMapViewState createState() => VeterinaryMapViewState();
}

class VeterinaryMapViewState extends State<VeterinaryMapView> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];

  static const Color primaryPurple = Color(0xFF7C4DFF);
  static const Color lightPurple = Color(0xFF9575CD);
  static const Color accentOrange = Color(0xFFFF7043);
  static const Color lightPurpleBackground = Color(0xFFF3E5F5);

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  void _createMarkers() {
    final markers = <Marker>[];
    for (final vet in widget.vets) {
      // CORRIGÉ: On utilise les getters directs du modèle, c'est plus propre.
      if (vet.hasLocation) {
        markers.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(vet.latitude!, vet.longitude!),
            child: Icon(Icons.location_pin, color: accentOrange, size: 40),
          ),
        );
      }
    }
    setState(() {
      _markers = markers;
    });
  }

  void _goToVeterinary(Veterinary vet) {
    if (vet.hasLocation) {
      _mapController.move(LatLng(vet.latitude!, vet.longitude!), 15.0);
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
        elevation: 0,
      ),
      body: Column(
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
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: _markers,
                ),
              ],
            ),
          ),
          Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: lightPurpleBackground.withOpacity(0.3),
                  border: Border(
                    top: BorderSide(color: primaryPurple.withOpacity(0.2), width: 2),
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
    if (widget.vets.isNotEmpty) {
      final firstVetWithLocation = widget.vets.firstWhere(
        (v) => v.hasLocation,
        orElse: () => widget.vets.first,
      );
      
      if (firstVetWithLocation.hasLocation) {
        return LatLng(firstVetWithLocation.latitude!, firstVetWithLocation.longitude!);
      }
    }
    return const LatLng(36.8065, 10.1815); // Tunis par défaut
  }

  LatLngBounds _boundsFromMarkers() {
    return LatLngBounds.fromPoints(_markers.map((m) => m.point).toList());
  }

  Widget _buildVetList() {
    final vetsWithLocation = widget.vets.where((v) => v.hasLocation).toList();
    
    if (vetsWithLocation.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: lightPurple.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Aucun vétérinaire avec une localisation\n n\'a été trouvé.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: vetsWithLocation.length,
      itemBuilder: (context, index) {
        final vet = vetsWithLocation[index];
        final address = vet.address ?? 'Adresse non spécifiée';
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
              'Dr. ${vet.owner.name}',
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
