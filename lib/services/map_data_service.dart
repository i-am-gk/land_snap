// NEW FILE: lib/services/map_data_service.dart
// ---------------------------------------------------------
// MODULE: Map Data Service (Isolated)
// PURPOSE: Handles fetching and parsing of GeoJSON data.
//          This service is completely independent of Firestore 
//          and existing Land/Auth models.
// ---------------------------------------------------------

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Data Model for a Land Polygon on the Map
class MapPolygonFeature {
  final String khasraId;
  final List<LatLng> points;
  final Map<String, dynamic> properties;

  MapPolygonFeature({
    required this.khasraId,
    required this.points,
    required this.properties,
  });
}

class MapDataService {
  // CONFIG: Your Firebase Storage URL for GeoJSON (optional)
  // If this is empty, the app will automatically use the local asset.
  static const String _remoteUrl = ""; 
  static const String _localAssetPath = "assets/map_data.json";

  /// Main entry point to load data with safe network-to-local fallback
  Future<List<MapPolygonFeature>> loadMapData() async {
    try {
      String jsonString;

      if (_remoteUrl.isNotEmpty) {
        // Attempt to fetch from Remote (Firebase Storage)
        final response = await http
            .get(Uri.parse(_remoteUrl))
            .timeout(const Duration(seconds: 8));
            
        if (response.statusCode == 200) {
          jsonString = response.body;
        } else {
          // Fallback to local if remote server returns error
          jsonString = await rootBundle.loadString(_localAssetPath);
        }
      } else {
        // Load from Local Assets
        jsonString = await rootBundle.loadString(_localAssetPath);
      }

      return _parseGeoJson(jsonString);
    } catch (e) {
      // Final safety fallback: always try to load local if network fails
      try {
        final fallback = await rootBundle.loadString(_localAssetPath);
        return _parseGeoJson(fallback);
      } catch (assetError) {
        print("MapDataService Error: Both remote and local failed. $assetError");
        return [];
      }
    }
  }

  /// Internal parser to convert GeoJSON strings to MapPolygonFeatures
  List<MapPolygonFeature> _parseGeoJson(String raw) {
    final Map<String, dynamic> data = json.decode(raw);
    List<MapPolygonFeature> features = [];

    if (data['features'] == null) return [];

    for (var f in data['features']) {
      final props = f['properties'] ?? {};
      final geometry = f['geometry'];

      // Only process Polygons
      if (geometry != null && geometry['type'] == 'Polygon') {
        List<LatLng> pts = [];
        
        // Use "khasra" property as per requirement
        final String id = props['khasra']?.toString() ?? "N/A";

        // GeoJSON uses [lng, lat]
        for (var c in geometry['coordinates'][0]) {
          pts.add(LatLng(c[1], c[0]));
        }

        features.add(MapPolygonFeature(
          khasraId: id,
          points: pts,
          properties: props,
        ));
      }
    }
    return features;
  }

  /// Ray Casting Algorithm: Independent utility for tap detection
  bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    var isInside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if (((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude)) &&
          (point.longitude < (polygon[j].longitude - polygon[i].longitude) * (point.latitude - polygon[i].latitude) / (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude)) {
        isInside = !isInside;
      }
    }
    return isInside;
  }
}
