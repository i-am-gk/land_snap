import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../admin/admin_dashboard.dart';
import '../user/user_dashboard.dart';

class AuthGate extends StatefulWidget {
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _authSub;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _authSub = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _routeUser(user);
      } else {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _routeUser(User user) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .get();

      String role = "user"; // default role
      if (doc.exists) {
        final data = doc.data(); // Map<String, dynamic>?
        if (data != null && data["role"] is String) {
          role = data["role"] as String;
        }
      }

      if (!mounted) return;

      if (role == "admin") {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => AdminDashboard(user: user)),
          (_) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => UserDashboard(user: user)),
          (_) => false,
        );
      }
    } catch (e) {
      print("Error fetching user role: $e");
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    return LoginScreen();
  }
}
