import 'package:flutter/material.dart';

/// Text field with the shared decoration. [obscure] plus [visible] implements
/// the password visibility toggle (eye icon, never color-only).
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.obscure = false,
    this.visible,
    this.onToggleVisible,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscure;
  final bool? visible;
  final VoidCallback? onToggleVisible;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final toggleVisible = onToggleVisible;
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
      obscureText: obscure && !(visible ?? false),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: toggleVisible == null
            ? null
            : IconButton(
                tooltip: (visible ?? false)
                    ? 'Subre password'
                    : 'Hale password',
                icon: Icon(
                  (visible ?? false) ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
                onPressed: toggleVisible,
              ),
      ),
    );
  }
}
