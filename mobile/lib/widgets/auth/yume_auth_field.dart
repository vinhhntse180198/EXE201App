import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';

/// Input có icon — khớp `.auth-field-wrap` trên web.
class YumeAuthField extends StatelessWidget {
  const YumeAuthField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon = Icons.mail_outline,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: YumeColors.ink, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: YumeColors.card,
            prefixIcon: Icon(icon, size: 20, color: YumeColors.muted),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: YumeColors.border.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: YumeColors.border.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: YumeColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
