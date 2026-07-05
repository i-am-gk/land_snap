import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import '../services/land_repository.dart';
import '../models/map_polygon_feature.dart';

import 'package:firebase_auth/firebase_auth.dart';
enum MapType { satellite, standard, terrain, light }

class MapView extends StatefulWidget {
  final User? user;
  final String? initialKhasraId;
  const MapView({this.user, this.initialKhasraId, super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with TickerProviderStateMixin {
  // Controllers & Services
  late final AnimatedMapController _animatedController;
  final LandRepository _landRepo = LandRepository();
  
  // State Variables
  String? _selectedKhasraId;
  MapType _mapType = MapType.satellite;
  bool _hasInitialZoomed = false;

  @override
  void initState() {
    super.initState();
    _animatedController = AnimatedMapController(vsync: this);
    _selectedKhasraId = widget.initialKhasraId;
  }

  /// Automatically fits the camera to show all plots on first load
  void _fitCameraOnce(List<MapPolygonFeature> features) {
    if (_hasInitialZoomed || features.isEmpty) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Priority 1: Zoom to specific selection if provided
      if (_selectedKhasraId != null) {
        final selected = features.cast<MapPolygonFeature?>().firstWhere(
          (f) => f?.khasraId == _selectedKhasraId,
          orElse: () => null,
        );
        if (selected != null) {
          _animatedController.animateTo(
            dest: selected.centroid,
            zoom: 17,
            rotation: 0,
          );
          _hasInitialZoomed = true;
          return;
        }
      }

      // Priority 2: Fit all bounds
      final allPoints = features.expand((f) => f.points).toList();
      if (allPoints.isEmpty) return;
      
      final bounds = LatLngBounds.fromPoints(allPoints);
      _animatedController.animatedFitCamera(
        cameraFit: CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.fastOutSlowIn,
      );
      _hasInitialZoomed = true;
    });
  }

  /// Ray Casting Algorithm: Tap detection for polygons
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    var isInside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if (((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude)) &&
          (point.longitude < (polygon[j].longitude - polygon[i].longitude) * (point.latitude - polygon[i].latitude) / (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude)) {
        isInside = !isInside;
      }
    }
    return isInside;
  }

  void _handleMapTap(TapPosition tapPos, LatLng point, List<MapPolygonFeature> features) {
    MapPolygonFeature? clickedFeature;
    
    for (var feature in features) {
      if (_isPointInPolygon(point, feature.points)) {
        clickedFeature = feature;
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _selectedKhasraId = clickedFeature?.khasraId;
    });

    if (clickedFeature != null) {
      _showLandInformation(clickedFeature);
    }
  }

  void _showLandInformation(MapPolygonFeature feature) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4, 
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Khasra #${feature.khasraId}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6D4C41)),
            ),
            const Divider(height: 32),
            
            _buildDetailRow("Owner", feature.ownerName),
            _buildDetailRow("Area", feature.areaDetail),
            _buildDetailRow("Type", feature.areaType),
            _buildDetailRow("Khata", feature.khataNumber),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6D4C41),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Close Preview", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  String _getTileUrl() {
    switch (_mapType) {
      case MapType.satellite:
        return "https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}";
      case MapType.standard:
        return "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
      case MapType.terrain:
        return "https://tile.opentopomap.org/{z}/{x}/{y}.png";
      case MapType.light:
        return "https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LandSnap Explorer", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6D4C41),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: "Switch Map Mode",
            icon: const Icon(Icons.layers_outlined),
            onPressed: () {
              if (mounted) {
                setState(() {
                  _mapType = MapType.values[(_mapType.index + 1) % MapType.values.length];
                });
              }
            },
          )
        ],
      ),
      body: StreamBuilder<List<MapPolygonFeature>>(
        stream: _landRepo.watchAllPlots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final features = snapshot.data ?? [];
          _fitCameraOnce(features);

          return Stack(
            children: [
              FlutterMap(
                mapController: _animatedController.mapController,
                options: MapOptions(
                  onTap: (tapPos, point) => _handleMapTap(tapPos, point, features),
                  initialCenter: const LatLng(34.613, 73.140),
                  initialZoom: 16.0,
                  cameraConstraint: CameraConstraint.contain(
                    bounds: LatLngBounds(
                      const LatLng(-90, -180),
                      const LatLng(90, 180),
                    ),
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: _getTileUrl(),
                    userAgentPackageName: 'com.landsnap.app',
                  ),
                  
                  PolygonLayer(
                    polygons: features
                        .where((f) => f.points.length >= 3) // Safe filter to prevent LatLngBounds crash
                        .map((f) {
                      final isSelected = _selectedKhasraId == f.khasraId;
                      return Polygon(
                        points: f.points,
                        color: isSelected 
                            ? Colors.green.withOpacity(0.3)
                            : const Color(0xFF6D4C41).withOpacity(0.3),
                        borderColor: isSelected 
                            ? Colors.greenAccent[700]!
                            : const Color(0xFF6D4C41),
                        borderStrokeWidth: isSelected ? 5 : 3,
                        isFilled: true,
                      );
                    }).toList(),
                  ),

                  MarkerLayer(
                    markers: features.map((f) {
                      final isSelected = _selectedKhasraId == f.khasraId;
                      return Marker(
                        point: f.centroid,
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: () {
                            if (mounted) setState(() => _selectedKhasraId = f.khasraId);
                            _showLandInformation(f);
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                color: isSelected ? Colors.orange : Colors.red,
                                size: isSelected ? 36 : 30,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              
              _buildLegend(features.isNotEmpty),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPopupCard(MapPolygonFeature f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Khasra #${f.khasraId}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF6D4C41))),
              const Icon(Icons.verified, size: 16, color: Colors.blue),
            ],
          ),
          const Divider(height: 12),
          _buildPopupInfo("Owner", f.ownerName),
          _buildPopupInfo("Area", f.areaDetail),
          _buildPopupInfo("Type", f.areaType),
        ],
      ),
    );
  }

  Widget _buildPopupInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(bool isVisible) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Map Legend", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              _buildLegendItem(const Color(0xFF6D4C41), "Land Boundary"),
              _buildLegendItem(Colors.orange, "Selected Area"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
