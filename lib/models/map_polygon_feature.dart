import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class MapPolygonFeature {
  final String khasraId;
  final List<LatLng> points;
  final String ownerName;
  final String areaDetail;
  final String areaType;
  final String khataNumber;

  const MapPolygonFeature({
    required this.khasraId,
    required this.points,
    this.ownerName = 'N/A',
    this.areaDetail = 'N/A',
    this.areaType = 'N/A',
    this.khataNumber = 'N/A',
  });

  /// Factory to parse from Firestore. Returns null if geometry is invalid.
  static MapPolygonFeature? fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;

    List<LatLng> points = [];

    // 1. Try new flat 'points' format first
    if (data.containsKey('points') && data['points'] is List) {
      final List pointsData = data['points'];
      points = pointsData.map<LatLng>((p) {
        final map = p as Map<String, dynamic>;
        return LatLng(
          (map['lat'] as num).toDouble(),
          (map['lng'] as num).toDouble(),
        );
      }).toList();
    } 
    // 2. Fallback to old GeoJSON-style 'geometry' format
    else if (data.containsKey('geometry')) {
      final geometry = data['geometry'] as Map<String, dynamic>?;
      if (geometry != null && geometry['type'] == 'Polygon') {
        final outerRings = geometry['coordinates'] as List?;
        if (outerRings != null && outerRings.isNotEmpty) {
          final ring = outerRings[0] as List;
          points = ring.map<LatLng>((c) {
            final coord = c as List;
            return LatLng(
              (coord[1] as num).toDouble(),
              (coord[0] as num).toDouble(),
            );
          }).toList();
        }
      }
    }

    if (points.isEmpty) return null;

    return MapPolygonFeature(
      khasraId: data['khasraNumber']?.toString() ?? doc.id,
      points: points,
      ownerName: data['ownerName']?.toString() ?? 'N/A',
      areaDetail: data['areaDetail']?.toString() ?? 'N/A',
      areaType: data['areaType']?.toString() ?? 'N/A',
      khataNumber: data['khataNumber']?.toString() ?? 'N/A',
    );
  }

  /// Calculates the visual center of the polygon for marker placement.
  LatLng get centroid {
    if (points.isEmpty) return const LatLng(0, 0);
    double lat = 0, lng = 0;
    for (var p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }
}
