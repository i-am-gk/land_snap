import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_service.dart';
import 'add_land_screen.dart';
import 'view_land_screen.dart';
import '../services/geojson_migrator.dart';

class AdminDashboard extends StatelessWidget {
  final User user;
  final AuthService _authService = AuthService();
  AdminDashboard({required this.user, super.key});

  void _logout(BuildContext context) async {
    await _authService.signout();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('LandSnap — Admin Dashboard'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 🔹 Logo + Welcome Card
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor.withOpacity(0.8), primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/logo.png', // logo same as login/signup
                      height: 80,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome Admin',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Manage your land records efficiently and securely with LandSnap.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // 🔹 Action Buttons with improved styling
              ElevatedButton.icon(
                onPressed:
                    () => _navigateTo(context, AddLandScreen(user: user)),
                icon: const Icon(Icons.add, size: 24),
                label: const Text('Add Land'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed:
                    () => _navigateTo(context, ViewLandScreen(user: user)),
                icon: const Icon(Icons.list, size: 24),
                label: const Text('View Land'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              if (false) ...[
                OutlinedButton.icon(
                  onPressed: () => _confirmMigration(context),
                  icon: const Icon(Icons.sync_alt),
                  label: const Text('Sync Local Data'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Tip: Use 'Sync Local Data' to import geometry from map_data.json into Firestore.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmMigration(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Data Sync'),
        content: const Text('This will upload polygon boundaries from map_data.json to Firestore. Existing metadata will not be overwritten.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                _runMigration(context);
              },
              child: const Text('Sync Now'),
            ),
          ),
        ],
      ),
    );
  }

  void _runMigration(BuildContext context) async {
    final migrator = GeoJsonMigrator();
    final result = await migrator.migrateToFirestore();
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sync Result'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total features found: ${result.total}'),
              Text('Successfully synced: ${result.success}', style: const TextStyle(color: Colors.green)),
              Text('Failed/Skipped: ${result.failed}', style: const TextStyle(color: Colors.red)),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...result.errors.take(3).map((e) => Text('• $e', style: const TextStyle(fontSize: 12))),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    }
  }
}
