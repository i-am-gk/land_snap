import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../models/map_polygon_feature.dart';

class LandRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'lands';

  // ── USER APP: REAL-TIME DATA ─────────────────────────────────────────────

  /// Streams all land plots that have geometry data.
  /// Used by the MapView to automatically reflect changes.
  Stream<List<MapPolygonFeature>> watchAllPlots() {
    return _db
        .collection(_collection)
        .where('hasGeometry', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MapPolygonFeature.fromFirestore(doc))
          .whereType<MapPolygonFeature>() // Filter out nulls/invalid records
          .toList();
    });
  }

  // ── ADMIN APP: CRUD OPERATIONS ───────────────────────────────────────────

  /// Updates or creates a full land record including geometry.
  Future<void> saveLandRecord({
    required String khasraId,
    required Map<String, dynamic> metadata,
    List<LatLng>? points,
  }) async {
    final Map<String, dynamic> data = {
      ...metadata,
      'khasraNumber': khasraId,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (points != null && points.isNotEmpty) {
      data['points'] = points.map((p) => {
        'lat': p.latitude,
        'lng': p.longitude,
      }).toList();
      data['hasGeometry'] = true;
    }

    await _db.collection(_collection).doc(khasraId).set(data, SetOptions(merge: true));
  }

  /// Specialized update for just metadata (used in existing Admin edit dialogs).
  Future<void> updateMetadata(String khasraId, Map<String, dynamic> metadata) {
    return _db.collection(_collection).doc(khasraId).update(metadata);
  }

  /// Specialized update for just geometry (used in the upcoming boundary editor).
  Future<void> updateGeometry(String khasraId, List<LatLng> points) {
    return _db.collection(_collection).doc(khasraId).update({
      'points': points.map((p) => {
        'lat': p.latitude,
        'lng': p.longitude,
      }).toList(),
      'hasGeometry': true,
    });
  }

  /// Delete a record.
  Future<void> deleteLandRecord(String khasraId) {
    return _db.collection(_collection).doc(khasraId).delete();
  }
}
