import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared card surface with consistent radius, border and padding.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
    final onTap = this.onTap;
    if (onTap == null) return card;
    return InkWell(borderRadius: BorderRadius.circular(12), onTap: onTap, child: card);
  }
}

/// Menu row used on the home screens; shows a chevron when tappable.
class AppMenuItem extends StatelessWidget {
  const AppMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled || onTap == null;
    final color = disabled ? AppColors.muted : AppColors.primary;
    return AppCard(
      onTap: disabled ? null : onTap,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.sectionTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          if (!disabled) const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}
