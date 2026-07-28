import 'package:flutter/material.dart';

/// Small colored circle indicating an online/offline (or active/inactive)
/// state, used across paired-device lists and the TV nav rail header.
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.isOnline, this.size = 8});

  final bool isOnline;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline
            ? theme.colorScheme.tertiary
            : theme.colorScheme.outline,
      ),
    );
  }
}
