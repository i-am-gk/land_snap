import 'package:flutter/material.dart';
import '../services/font_size_provider.dart';

/// Wraps a user-side screen with a scoped MediaQuery that applies the
/// user's accessibility font scale. Safe to use only on informational
/// screens — never on map, admin, or GIS screens.
class AccessibleTextWrapper extends StatelessWidget {
  final Widget child;
  final FontSizeProvider provider;

  const AccessibleTextWrapper({
    required this.child,
    required this.provider,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final existing = MediaQuery.of(context);
        return MediaQuery(
          data: existing.copyWith(
            textScaler: TextScaler.linear(provider.fontScale),
          ),
          child: child,
        );
      },
    );
  }
}
