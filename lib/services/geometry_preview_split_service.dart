import 'dart:math';
import 'package:latlong2/latlong.dart';

class GeometryPreviewSplitService {
  /// Slices a polygon into [parts] roughly equal segments by splitting its bounding box horizontally.
  /// This is a simple visual approximation algorithm that interpolates along the edges.
  static List<List<LatLng>> generatePreviewSplits(List<LatLng> points, int parts) {
    if (points.length < 3 || parts < 2) return [];

    // Find bounding box
    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    List<List<LatLng>> generatedPolygons = [];
    double latStep = (maxLat - minLat) / parts;

    // Create horizontal slice boundaries
    List<double> sliceLatitudes = [];
    for (int i = 1; i < parts; i++) {
      sliceLatitudes.add(minLat + (i * latStep));
    }
    
    // Sutherland-Hodgman style clipping against horizontal bands
    for (int i = 0; i < parts; i++) {
      double bottomLat = (i == 0) ? -90.0 : sliceLatitudes[i - 1];
      double topLat = (i == parts - 1) ? 90.0 : sliceLatitudes[i];
      
      List<LatLng> clipped = _clipPolygonByLatitudeBand(points, bottomLat, topLat);
      if (clipped.length >= 3) {
        generatedPolygons.add(clipped);
      }
    }

    return generatedPolygons;
  }

  static List<LatLng> _clipPolygonByLatitudeBand(List<LatLng> poly, double bottomLat, double topLat) {
    List<LatLng> out = List.from(poly);
    out = _clipPolygonByEdge(out, bottomLat, true);
    out = _clipPolygonByEdge(out, topLat, false);
    return out;
  }

  static List<LatLng> _clipPolygonByEdge(List<LatLng> poly, double edgeLat, bool isBottom) {
    if (poly.isEmpty) return [];
    
    List<LatLng> clipped = [];
    for (int i = 0; i < poly.length; i++) {
      LatLng current = poly[i];
      LatLng prev = i == 0 ? poly.last : poly[i - 1];

      bool currentInside = isBottom ? (current.latitude >= edgeLat) : (current.latitude <= edgeLat);
      bool prevInside = isBottom ? (prev.latitude >= edgeLat) : (prev.latitude <= edgeLat);

      if (currentInside != prevInside) {
        // Compute intersection
        double t = (edgeLat - prev.latitude) / (current.latitude - prev.latitude);
        double intersectLng = prev.longitude + t * (current.longitude - prev.longitude);
        clipped.add(LatLng(edgeLat, intersectLng));
      }

      if (currentInside) {
        clipped.add(current);
      }
    }
    return clipped;
  }

  static double calculateAreaInSquareMeters(List<LatLng> polygon) {
    if (polygon.length < 3) return 0.0;
    
    double area = 0.0;
    double avgLat = 0.0;
    for (var p in polygon) {
      avgLat += p.latitude;
    }
    avgLat /= polygon.length;
    
    const double metersPerLatDegree = 111320.0;
    double metersPerLngDegree = 111320.0 * cos(avgLat * pi / 180.0);
    
    for (int i = 0; i < polygon.length; i++) {
      LatLng p1 = polygon[i];
      LatLng p2 = (i + 1 == polygon.length) ? polygon[0] : polygon[i + 1];
      
      double x1 = p1.longitude * metersPerLngDegree;
      double y1 = p1.latitude * metersPerLatDegree;
      double x2 = p2.longitude * metersPerLngDegree;
      double y2 = p2.latitude * metersPerLatDegree;
      
      area += (x1 * y2) - (x2 * y1);
    }
    
    return (area.abs() / 2.0);
  }

  static LatLng calculateCentroid(List<LatLng> polygon) {
    if (polygon.isEmpty) return const LatLng(0, 0);
    if (polygon.length == 1) return polygon.first;
    if (polygon.length == 2) {
      return LatLng((polygon[0].latitude + polygon[1].latitude) / 2, (polygon[0].longitude + polygon[1].longitude) / 2);
    }

    double signedArea = 0.0;
    double cx = 0.0;
    double cy = 0.0;
    
    for (int i = 0; i < polygon.length; i++) {
      LatLng p1 = polygon[i];
      LatLng p2 = (i + 1 == polygon.length) ? polygon[0] : polygon[i + 1];
      
      double x1 = p1.longitude;
      double y1 = p1.latitude;
      double x2 = p2.longitude;
      double y2 = p2.latitude;
      
      double a = (x1 * y2) - (x2 * y1);
      signedArea += a;
      cx += (x1 + x2) * a;
      cy += (y1 + y2) * a;
    }
    
    signedArea *= 0.5;
    
    if (signedArea == 0) {
      double sumLat = 0.0;
      double sumLng = 0.0;
      for (var p in polygon) {
        sumLat += p.latitude;
        sumLng += p.longitude;
      }
      return LatLng(sumLat / polygon.length, sumLng / polygon.length);
    }
    
    cx /= (6.0 * signedArea);
    cy /= (6.0 * signedArea);
    
    return LatLng(cy, cx);
  }
}
