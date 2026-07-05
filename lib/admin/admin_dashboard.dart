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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('LandSnap — Admin Dashboard'),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 🔹 Premium Welcome Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/logo.png', // logo same as login/signup
                        height: 100,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Welcome, Admin',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Manage your land records efficiently\nand securely with LandSnap.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.4),
                      ),
                    ],
                  ),
                ),

                // 🔹 Modern Action Buttons
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _navigateTo(context, AddLandScreen(user: user)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.add_location_alt_rounded, size: 28, color: primaryColor),
                        ),
                        const SizedBox(width: 20),
                        const Expanded(
                          child: Text(
                            'Add New Land',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _navigateTo(context, ViewLandScreen(user: user)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.list_alt_rounded, size: 28, color: primaryColor),
                        ),
                        const SizedBox(width: 20),
                        const Expanded(
                          child: Text(
                            'View Land Records',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                      ],
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
