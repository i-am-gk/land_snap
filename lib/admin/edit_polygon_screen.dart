import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../services/land_repository.dart';
import '../models/map_polygon_feature.dart';
import '../services/geometry_preview_split_service.dart';

class EditPolygonScreen extends StatefulWidget {
  final MapPolygonFeature feature;
  const EditPolygonScreen({required this.feature, super.key});

  @override
  State<EditPolygonScreen> createState() => _EditPolygonScreenState();
}

class _EditPolygonScreenState extends State<EditPolygonScreen>
    with TickerProviderStateMixin {
  late List<LatLng> _points;
  late final AnimatedMapController _animatedController;
  final TextEditingController _searchController = TextEditingController();
  final LandRepository _landRepo = LandRepository();
  final GlobalKey _mapKey = GlobalKey();

  bool _isSaving = false;
  bool _isSatellite = true;
  bool _isEditing = false; // Added drawing mode state
  bool _isMoveMode = false; // Added move mode state
  int? _draggedIndex;
  int? _selectedIndex;
  List<dynamic> _suggestions = [];
  Timer? _debounce;
  
  // Temporary Subdivision Preview State
  List<List<LatLng>> _previewPolygons = [];

  @override
  void initState() {
    super.initState();
    _points = List.from(widget.feature.points);
    _isEditing = _points.isEmpty; // Enable drawing mode for new records
    _animatedController = AnimatedMapController(vsync: this);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _animatedController.dispose();
    super.dispose();
  }

  void _addPoint(TapPosition _, LatLng point) {
    if (mounted) {
      setState(() {
        _points.add(point);
        _selectedIndex = _points.length - 1; // Auto-select new point
      });
    }
  }

  void _removeSelectedPoint() {
    if (_selectedIndex != null && _selectedIndex! < _points.length) {
      if (mounted) {
        setState(() {
          _points.removeAt(_selectedIndex!);
          _selectedIndex = null;
        });
      }
    }
  }

  void _clearPoints() {
    if (mounted) {
      setState(() {
        _points.clear();
        _selectedIndex = null;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        if (mounted) {
          setState(() {
            _suggestions = [];
          });
        }
        return;
      }

      final url = Uri.parse(
          "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5");

      try {
        final response =
            await http.get(url, headers: {'User-Agent': 'LandSnap App'});
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (mounted) {
            setState(() {
              _suggestions = data;
            });
          }
        }
      } catch (e) {
        debugPrint("Autocomplete error: $e");
      }
    });
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1");

    try {
      final response =
          await http.get(url, headers: {'User-Agent': 'LandSnap App'});
      final data = json.decode(response.body);

      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        final target = LatLng(lat, lon);

        _animatedController.mapController.move(target, 16);
        _searchController.clear();
        FocusScope.of(context).unfocus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not found')),
        );
      }
    } catch (e) {
      debugPrint("Search error: $e");
    }
  }

  Future<void> _save() async {
    if (_points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Polygon must have at least 3 points')),
      );
      return;
    }

    if (mounted) setState(() => _isSaving = true);
    try {
      await _landRepo.updateGeometry(widget.feature.khasraId, _points);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Boundary updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save boundary')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSubdivisionPreviewBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Subdivision Preview",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6D4C41),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Split Into",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ListTile(
                title: const Text("2 Parts"),
                leading: const Icon(Icons.pie_chart_outline),
                onTap: () {
                  Navigator.pop(context);
                  _generatePreview(2);
                },
              ),
              ListTile(
                title: const Text("3 Parts"),
                leading: const Icon(Icons.pie_chart_outline),
                onTap: () {
                  Navigator.pop(context);
                  _generatePreview(3);
                },
              ),
              ListTile(
                title: const Text("4 Parts"),
                leading: const Icon(Icons.pie_chart_outline),
                onTap: () {
                  Navigator.pop(context);
                  _generatePreview(4);
                },
              ),
              const Divider(),
              if (_previewPolygons.isNotEmpty)
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _previewPolygons.clear();
                      });
                    },
                    icon: const Icon(Icons.clear, color: Colors.red),
                    label: const Text("Clear Preview", style: TextStyle(color: Colors.red)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _generatePreview(int parts) {
    if (_points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Polygon must have at least 3 points to preview.')),
      );
      return;
    }
    setState(() {
      _previewPolygons = GeometryPreviewSplitService.generatePreviewSplits(_points, parts);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Khasra #${widget.feature.khasraId}"),
        backgroundColor: const Color(0xFF6D4C41),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Preview Split",
            icon: const Icon(Icons.grid_on),
            onPressed: _showSubdivisionPreviewBottomSheet,
          ),
          IconButton(
            tooltip: "Toggle View",
            icon: Icon(_isSatellite ? Icons.map : Icons.satellite_alt),
            onPressed: () => setState(() => _isSatellite = !_isSatellite),
          ),
          IconButton(
            icon: Icon(_isEditing ? Icons.edit_off : Icons.edit),
            tooltip: _isEditing ? "Stop Drawing" : "Start Drawing",
            onPressed: () => setState(() {
              _isEditing = !_isEditing;
              if (_isEditing) _isMoveMode = false;
            }),
          ),
          IconButton(
            icon: Icon(_isMoveMode ? Icons.pan_tool : Icons.pan_tool_outlined),
            tooltip: _isMoveMode ? "Stop Moving" : "Start Moving",
            onPressed: () => setState(() {
              _isMoveMode = !_isMoveMode;
              if (_isMoveMode) _isEditing = false;
            }),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: "Clear All",
            onPressed: _clearPoints,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 🔹 Map Layer
          FlutterMap(
            key: _mapKey,
            mapController: _animatedController.mapController,
            options: MapOptions(
              onTap: (pos, point) {
                if (_isEditing && !_isMoveMode) {
                  _addPoint(pos, point);
                }
              },
              initialCenter: _points.isNotEmpty
                  ? _points.first
                  : const LatLng(34.613, 73.140),
              initialZoom: 17.0,
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  const LatLng(-90, -180),
                  const LatLng(90, 180),
                ),
              ),
              interactionOptions: InteractionOptions(
                flags: _draggedIndex != null || _isMoveMode
                    ? InteractiveFlag.none
                    : (InteractiveFlag.all & ~InteractiveFlag.rotate),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _isSatellite
                    ? "https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}"
                    : "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.landsnap.app',
              ),
              // Reference Polygons Layer
              StreamBuilder<List<MapPolygonFeature>>(
                stream: _landRepo.watchAllPlots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final palette = [
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.purple,
                    Colors.teal,
                    Colors.amber,
                  ];

                  final referenceFeatures = snapshot.data!
                      .where((f) => f.khasraId != widget.feature.khasraId && f.points.length >= 3)
                      .toList();

                  final referencePolygons = referenceFeatures.asMap().entries.map((entry) {
                    final index = entry.key;
                    final f = entry.value;
                    final baseColor = palette[index % palette.length];

                    return Polygon(
                      points: f.points,
                      color: baseColor.withOpacity(0.15),
                      borderColor: baseColor.withOpacity(0.8),
                      borderStrokeWidth: 2,
                    );
                  }).toList();

                  return PolygonLayer(polygons: referencePolygons);
                },
              ),
              // Active Polygon Layer
              if (_points.length >= 3)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _points,
                      color: Colors.orange.withValues(alpha: 0.4),
                      borderColor: Colors.orange,
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),
              // Subdivision Preview Polygon Layer
              if (_previewPolygons.isNotEmpty)
                PolygonLayer(
                  polygons: _previewPolygons.asMap().entries.map((entry) {
                    final index = entry.key;
                    final polyPoints = entry.value;
                    final palette = [
                      Colors.purple,
                      Colors.cyan,
                      Colors.pink,
                      Colors.lime,
                    ];
                    final color = palette[index % palette.length];
                    return Polygon(
                      points: polyPoints,
                      color: color.withOpacity(0.4),
                      borderColor: color,
                      borderStrokeWidth: 4,
                    );
                  }).toList(),
                ),
              // Subdivision Preview Area Labels
              if (_previewPolygons.isNotEmpty)
                MarkerLayer(
                  markers: _previewPolygons.asMap().entries.map((entry) {
                    final index = entry.key;
                    final polyPoints = entry.value;
                    final centroid = GeometryPreviewSplitService.calculateCentroid(polyPoints);
                    final areaMeters = GeometryPreviewSplitService.calculateAreaInSquareMeters(polyPoints);
                    final areaFeet = areaMeters * 10.7639;
                    
                    return Marker(
                      point: centroid,
                      width: 100,
                      height: 50,
                      alignment: Alignment.center,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white, width: 0.5),
                          ),
                          child: Center(
                            child: Text(
                              'Part ${index + 1}\n${areaMeters.toStringAsFixed(1)} m²\n${areaFeet.toStringAsFixed(1)} ft²',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              // Live distance labels between consecutive points
              if (_points.length >= 2)
                MarkerLayer(
                  markers: List.generate(
                    _points.length >= 3 ? _points.length : _points.length - 1,
                    (index) {
                      final p1 = _points[index];
                      final p2 = _points[(index + 1) % _points.length];
                      final midLat = (p1.latitude + p2.latitude) / 2;
                      final midLng = (p1.longitude + p2.longitude) / 2;
                      final distMeters = const Distance().distance(p1, p2);
                      final distFt = distMeters * 3.28084;
                      final dist = distMeters.toStringAsFixed(1);
                      final distFeet = distFt.toStringAsFixed(1);

                      return Marker(
                        point: LatLng(midLat, midLng),
                        width: 100,
                        height: 24,
                        alignment: Alignment.center,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white, width: 0.5),
                            ),
                            child: Center(
                              child: Text(
                                '$dist m ($distFeet ft)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              MarkerLayer(
                markers: _points.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  final isDragging = _draggedIndex == idx;
                  final isSelected = _selectedIndex == idx;

                  return Marker(
                    point: p,
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selectedIndex = idx),
                      onPanStart: (_) {
                        if (!_isMoveMode) return;
                        setState(() {
                          _draggedIndex = idx;
                          _selectedIndex = idx;
                        });
                      },
                      onPanUpdate: (details) {
                        if (!_isMoveMode) return;
                        // Use CRS (Coordinate Reference System) for proper conversion
                        final camera = _animatedController.mapController.camera;
                        final crs = camera.crs;
                        final zoom = camera.zoom;
                        final currentPoint = crs.latLngToPoint(p, zoom);
                        final newPoint = Point(
                          currentPoint.x + details.delta.dx,
                          currentPoint.y + details.delta.dy,
                        );
                        final newLatLng = crs.pointToLatLng(newPoint, zoom);
                        setState(() {
                          _points[idx] = newLatLng;
                        });
                      },
                      onPanEnd: (_) => setState(() => _draggedIndex = null),
                      child: Container(
                        color: Colors.transparent, // Large touch area
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: (isDragging || isSelected) ? 28 : 16,
                            height: (isDragging || isSelected) ? 28 : 16,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDragging ? Colors.red : Colors.blue)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.blueAccent,
                                width: isSelected ? 4 : 2,
                              ),
                              boxShadow: (isDragging || isSelected)
                                  ? [
                                      BoxShadow(
                                          color: Colors.black38,
                                          blurRadius: 12,
                                          spreadRadius: 2)
                                    ]
                                  : [],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 🔹 Search Bar Overlay
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4))
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search location (e.g., Haripur)",
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF6D4C41)),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      if (mounted) {
                        setState(() {
                          _suggestions = [];
                        });
                      }
                    },
                  ),
                ),
                onChanged: _onSearchChanged,
                onSubmitted: _searchLocation,
              ),
            ),
          ),

          // 🔹 Suggestions Overlay
          if (_suggestions.isNotEmpty)
            Positioned(
              top: 85,
              left: 20,
              right: 20,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final item = _suggestions[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on_outlined,
                            color: Color(0xFF6D4C41)),
                        title: Text(
                          item['display_name'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        onTap: () {
                          final lat = double.parse(item['lat']);
                          final lon = double.parse(item['lon']);
                          final target = LatLng(lat, lon);

                          _animatedController.mapController.move(target, 16);
                          _searchController.clear();
                          if (mounted) {
                            setState(() {
                              _suggestions = [];
                            });
                          }
                          FocusScope.of(context).unfocus();
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

          // 🔹 Bottom Control Panel (Conditional)
          if (_selectedIndex != null)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, -2))
                  ],
                ),
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Point #${_selectedIndex! + 1} Selected",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6D4C41))),
                        const Text("Drag to move or delete",
                            style:
                                TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _removeSelectedPoint,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: "Delete Point",
                    ),
                    const SizedBox(width: 8),
                    Expanded(
  child: SizedBox(
    height: 50,
    child: ElevatedButton(
      onPressed: () =>
          setState(() => _selectedIndex = null),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6D4C41),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          "Done",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
  ),
),


                  ],
                ),
              ),
            ),

          // 🔹 Bottom Control Stack (Help Tip + Save Button)
          if (_selectedIndex == null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Tap a point to select. Drag to adjust.\nDouble-tap map to add points.",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          if (_points.length >= 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                "Perimeter: ${(List.generate(_points.length, (i) => const Distance().distance(_points[i], _points[(i + 1) % _points.length])).fold<double>(0.0, (a, b) => a + b)).toStringAsFixed(1)} m (${((List.generate(_points.length, (i) => const Distance().distance(_points[i], _points[(i + 1) % _points.length])).fold<double>(0.0, (a, b) => a + b)) * 3.28084).toStringAsFixed(1)} ft)",
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton.extended(
                    onPressed: _isSaving ? null : _save,
                    backgroundColor: const Color(0xFF6D4C41),
                    foregroundColor: Colors.white,
                    label: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text("Save Boundary"),
                    icon: const Icon(Icons.save),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
