import 'package:flutter/material.dart';

class TvAutoScrollRoot extends StatefulWidget {
  const TvAutoScrollRoot({
    super.key,
    required this.child,
    this.alignment = 0.5,
  });

  final Widget child;
  final double alignment;

  @override
  State<TvAutoScrollRoot> createState() => _TvAutoScrollRootState();
}

class _TvAutoScrollRootState extends State<TvAutoScrollRoot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.addListener(_handleFocusChange);
    });
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    final primaryFocus = FocusManager.instance.primaryFocus;
    final context = primaryFocus?.context;

    if (primaryFocus != null && context != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Scrollable.ensureVisible(
            context,
            alignment: widget.alignment,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
