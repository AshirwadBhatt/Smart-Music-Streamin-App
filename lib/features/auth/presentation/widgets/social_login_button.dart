import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SocialLoginButton extends StatelessWidget {
  final String label;
  final String iconPath;
  final VoidCallback? onTap;

  const SocialLoginButton({super.key, required this.label, required this.iconPath, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(iconPath, width: 22, height: 22, errorBuilder: (_, __, ___) =>
              const Icon(Icons.g_mobiledata_rounded, color: AppColors.textPrimary, size: 26)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    ),
  );
}
