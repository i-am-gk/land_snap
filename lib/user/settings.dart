import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../auth/auth_service.dart';
import '../widgets/accessible_text_wrapper.dart';
import 'about_screen.dart';
import 'terms_screen.dart';
import 'font_size_preview.dart';

class Settings extends StatelessWidget {
  final User user;
  final AuthService _authService = AuthService();
  Settings({required this.user, super.key});

  void _logout(BuildContext context) async {
    await _authService.signout();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  void _openAbout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AboutScreen()),
    );
  }

  void _openTerms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsScreen()),
    );
  }

  void _openFontSizePreview(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FontSizePreviewScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleTextWrapper(
      provider: appFontSizeProvider,
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final userName = user.displayName ?? "Verified User";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Account Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          children: [
            // 🔹 Profile Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Image.asset('assets/logo.png', height: 60),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.verified_rounded, size: 14, color: primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              'Standard Access',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            _buildSectionTitle("General"),
            const SizedBox(height: 16),

            // 🔹 Options Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.info_outline_rounded,
                    title: "About LandSnap",
                    subtitle: "App version and mission",
                    color: Colors.blueAccent,
                    onTap: () => _openAbout(context),
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    icon: Icons.description_outlined,
                    title: "Terms & Conditions",
                    subtitle: "Usage policy and legal",
                    color: Colors.orangeAccent,
                    onTap: () => _openTerms(context),
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    icon: Icons.text_fields_rounded,
                    title: "Accessibility",
                    subtitle: "Font size and display preview",
                    color: Colors.green,
                    onTap: () => _openFontSizePreview(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Logout Button
            ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 64),
                backgroundColor: Colors.white,
                foregroundColor: Colors.redAccent,
                elevation: 0,
                side: BorderSide(color: Colors.red.shade100, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "v1.2.0 (Stable)",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.black38,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 70, endIndent: 20, color: Colors.grey.shade100);
  }
}
