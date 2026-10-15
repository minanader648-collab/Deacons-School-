import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// يعرض شعار الكنيسة المخصص أو شعار مدرسة صفوف السمائيين الافتراضي
class ChurchLogo extends StatelessWidget {
  final String? logoBase64;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;

  const ChurchLogo({
    super.key,
    required this.logoBase64,
    this.radius = 28,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoBase64 != null && logoBase64!.isNotEmpty;
    ImageProvider? image;
    if (hasLogo) {
      try {
        image = MemoryImage(base64Decode(logoBase64!));
      } catch (_) {
        image = null;
      }
    }

    // الشعار الافتراضي من مجلد assets
    image ??= const AssetImage('assets/images/logo.png');

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.copticGold, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDarkBurgundy.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.white,
        backgroundImage: image,
      ),
    );
  }
}
