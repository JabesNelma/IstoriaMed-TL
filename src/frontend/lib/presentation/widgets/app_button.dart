import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Primary action button with a single loading presentation used everywhere.
/// While loading it is disabled so it cannot be pressed repeatedly.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = loading || onPressed == null;
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (icon != null) ...[Icon(icon), const SizedBox(width: AppSpacing.sm)],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
    return SizedBox(
      height: 48,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        // Keep the callback attached so semantic state stays enabled/disabled
        // rather than the button silently swallowing taps.
        onPressed: disabled ? null : onPressed,
        child: child,
      ),
    );
  }
}
