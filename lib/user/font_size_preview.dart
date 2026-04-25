import 'package:flutter/material.dart';

class FontSizePreviewScreen extends StatefulWidget {
  const FontSizePreviewScreen({super.key});

  @override
  State<FontSizePreviewScreen> createState() => _FontSizePreviewScreenState();
}

class _FontSizePreviewScreenState extends State<FontSizePreviewScreen> {
  double currentSize = 18;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Font Size Preview"),
        backgroundColor: primaryColor,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Logo
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

              // Sample Text Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    "This is a sample text preview. Adjust the slider below to see changes in font size in real-time.",
                    style: TextStyle(fontSize: currentSize, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Slider Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Adjust Font Size",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Slider(
                        value: currentSize,
                        min: 12,
                        max: 32,
                        divisions: 20,
                        label: currentSize.toInt().toString(),
                        onChanged: (value) {
                          setState(() => currentSize = value);
                        },
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
