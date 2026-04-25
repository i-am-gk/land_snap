import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        backgroundColor: primaryColor,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Logo at top
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.asset('assets/logo.png', height: 80, width: 80),
                ),
              ),
              const SizedBox(height: 20),

              // Terms content
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Terms & Conditions",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "By using the LandSnap application, you agree to the following terms:",
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "1. The information displayed is based on available cadastral data. Accuracy may vary depending on government records and uploaded data.\n\n"
                        "2. Users must access and use land information responsibly. Any misuse of the platform or data may result in restricted access.\n\n"
                        "3. Admins and Government Officials are responsible for maintaining and updating land records through the official LandSnap Web Portal.\n\n"
                        "4. LandSnap does not guarantee real-time satellite accuracy. The system uses GIS layers, GeoJSON files, and geospatial indexing for parcel mapping.\n\n"
                        "5. No personal user data is shared with third parties. Only essential authentication data is stored securely using the platform's backend.\n\n"
                        "By continuing, you acknowledge understanding and compliance with these terms.",
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
