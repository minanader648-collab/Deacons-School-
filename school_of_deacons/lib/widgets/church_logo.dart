import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// يعرض شعار الكنيسة إن وُجد، وإلا أيقونة افتراضية.
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

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppTheme.copticGold,
      backgroundImage: image,
      child: image == null
          ? Icon(
              Icons.church_rounded,
              size: radius * 1.1,
              color: iconColor ?? AppTheme.primaryDarkBurgundy,
            )
          : null,
    );
  }
}
