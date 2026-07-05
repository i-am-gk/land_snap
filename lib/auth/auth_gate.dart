import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      // ── Step 1: Try to read cached role for instant, zero-network routing ──
      final prefs = await SharedPreferences.getInstance();
      final cachedRole = prefs.getString('user_role');

      if (cachedRole != null && mounted) {
        // Route immediately from cache — no Firestore call needed.
        _navigateToRole(user, cachedRole);
        return;
      }

      // ── Step 2: Cache miss — fetch role from Firestore once, then cache it ──
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      String role = "user"; // safe default
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data["role"] is String) {
          role = data["role"] as String;
        }
      }

      // Cache the role so subsequent launches are instant.
      await prefs.setString('user_role', role);

      if (!mounted) return;
      _navigateToRole(user, role);
    } catch (e) {
      debugPrint("Error routing user: $e");
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _navigateToRole(User user, String role) {
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
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    return LoginScreen();
  }
}
