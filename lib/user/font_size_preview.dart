import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/accessible_text_wrapper.dart';

class FontSizePreviewScreen extends StatelessWidget {
  const FontSizePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessibleTextWrapper(
      provider: appFontSizeProvider,
      child: _FontSizePreviewBody(provider: appFontSizeProvider),
    );
  }
}

class _FontSizePreviewBody extends StatefulWidget {
  final dynamic provider;
  const _FontSizePreviewBody({required this.provider});

  @override
  State<_FontSizePreviewBody> createState() => _FontSizePreviewBodyState();
}

class _FontSizePreviewBodyState extends State<_FontSizePreviewBody> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.provider.fontScale;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Accessibility"),
        backgroundColor: primaryColor,
        elevation: 2,
        actions: [
          TextButton(
            onPressed: () async {
              await widget.provider.reset();
              setState(() => _sliderValue = widget.provider.fontScale);
            },
            child: const Text("Reset", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Logo
              Image.asset('assets/logo.png', height: 100),
              const SizedBox(height: 20),

              // Live preview card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Preview",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "This is a sample text preview. Adjust the slider below to see changes in font size in real-time across the entire application.",
                        style: TextStyle(height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Slider card
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Adjust Font Size",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${(_sliderValue * 100).toInt()}%",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.text_fields, size: 16,
                              color: Colors.black38),
                          Expanded(
                            child: Slider(
                              value: _sliderValue,
                              min: widget.provider.minScale,
                              max: widget.provider.maxScale,
                              divisions: 14,
                              activeColor: primaryColor,
                              onChanged: (value) {
                                setState(() => _sliderValue = value);
                              },
                              onChangeEnd: (value) {
                                widget.provider.setFontScale(value);
                              },
                            ),
                          ),
                          const Icon(Icons.text_fields, size: 24,
                              color: Colors.black38),
                        ],
                      ),
                      const Text(
                        "Changes apply immediately across all user screens.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.black45),
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
