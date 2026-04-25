import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'land_repository.dart';

class MigrationResult {
  final int total;
  final int success;
  final int failed;
  final List<String> errors;

  MigrationResult({required this.total, required this.success, required this.failed, required this.errors});
}

class GeoJsonMigrator {
  final LandRepository _repo = LandRepository();

  /// Migrates local JSON data to Firestore. 
  /// Returns a [MigrationResult] for UI feedback.
  Future<MigrationResult> migrateToFirestore() async {
    int total = 0;
    int success = 0;
    int failed = 0;
    List<String> errors = [];

    try {
      final String response = await rootBundle.loadString('assets/map_data.json');
      final data = json.decode(response);
      final List features = data['features'] ?? [];
      total = features.length;

      for (var feature in features) {
        try {
          final props = feature['properties'] ?? {};
          final geometry = feature['geometry'];
          final String khasraId = props['khasra']?.toString() ?? "unknown";

          if (khasraId == "unknown") {
            failed++;
            errors.add("Skipped: Feature missing khasra ID");
            continue;
          }

          if (geometry != null && geometry['type'] == 'Polygon') {
            final List ring = geometry['coordinates'][0];
            final points = ring.map<LatLng>((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();

            await _repo.saveLandRecord(
              khasraId: khasraId,
              metadata: {}, // Merge-only: doesn't overwrite existing metadata
              points: points,
            );
            success++;
          } else {
            failed++;
            errors.add("Skipped Khasra #$khasraId: Invalid or missing polygon geometry");
          }
        } catch (e) {
          failed++;
          errors.add("Error migrating feature: $e");
        }
      }
    } catch (e) {
      errors.add("Critical migration error: $e");
    }

    return MigrationResult(total: total, success: success, failed: failed, errors: errors);
  }
}
