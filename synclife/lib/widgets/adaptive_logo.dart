import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AdaptiveLogo extends StatelessWidget {
  final double widthFactor;
  final double maxWidth;
  final double minWidth;

  const AdaptiveLogo({
    super.key,
    this.widthFactor = 0.5,
    this.maxWidth = 300,
    this.minWidth = 120,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    double logoWidth = screenWidth * widthFactor;
    logoWidth = logoWidth.clamp(minWidth, maxWidth);

    return SizedBox(
      width: logoWidth,
      height: logoWidth,
      child: SvgPicture.asset(
        isDark 
            ? 'assets/images/Logo SyncLife Dark.svg'
            : 'assets/images/Logo SyncLife Light.svg',
        fit: BoxFit.contain,
      ),
    );
  }
}
