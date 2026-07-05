// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth/auth_gate.dart';
import 'services/font_size_provider.dart';

// Single app-wide font scale instance — only used by user-side screens.
final FontSizeProvider appFontSizeProvider = FontSizeProvider();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LandSnapApp());
}

class LandSnapApp extends StatelessWidget {
  const LandSnapApp({super.key});
  @override
  Widget build(BuildContext context) {
    final Color primaryBrown = Color(0xFF6D4C41);
    final Color lightGray = Color(0xFFF5F5F5);

    return MaterialApp(
      title: 'LandSnap Demo',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: primaryBrown,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBrown,
          primary: primaryBrown,
        ),
        scaffoldBackgroundColor: lightGray,
        appBarTheme: AppBarTheme(
          backgroundColor: primaryBrown,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryBrown, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBrown,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ),
      home: FirebaseInitLoader(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FirebaseInitLoader extends StatefulWidget {
  @override
  _FirebaseInitLoaderState createState() => _FirebaseInitLoaderState();
}

class _FirebaseInitLoaderState extends State<FirebaseInitLoader> {
  late Future<FirebaseApp> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = Firebase.initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Initializing LandSnap...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error initializing Firebase:\n${snapshot.error}'),
            ),
          );
        } else {
          return AuthGate();
        }
      },
    );
  }
}
