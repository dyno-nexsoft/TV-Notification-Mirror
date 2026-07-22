import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';

/// Shared widget for displaying application icons with lazy loading & caching.
class AppIconWidget extends StatefulWidget {
  final String packageName;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final double size;
  final Map<String, Uint8List?> cache;

  const AppIconWidget({
    super.key,
    required this.packageName,
    required this.fallbackIcon,
    required this.fallbackColor,
    this.size = 24.0,
    required this.cache,
  });

  @override
  State<AppIconWidget> createState() => _AppIconWidgetState();
}

class _AppIconWidgetState extends State<AppIconWidget> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadIconIfNeeded();
  }

  @override
  void didUpdateWidget(covariant AppIconWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packageName != widget.packageName) {
      _loadIconIfNeeded();
    }
  }

  Future<void> _loadIconIfNeeded() async {
    final pkg = widget.packageName;
    if (widget.cache.containsKey(pkg) || _loading) return;

    if (mounted) setState(() => _loading = true);

    try {
      final appInfo = await InstalledApps.getAppInfo(pkg);
      if (mounted) {
        setState(() {
          widget.cache[pkg] = appInfo?.icon;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          widget.cache[pkg] = null;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cachedIcon = widget.cache[widget.packageName];
    if (cachedIcon != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          cachedIcon,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        ),
      );
    }

    return Icon(
      widget.fallbackIcon,
      color: widget.fallbackColor,
      size: widget.size,
    );
  }
}
