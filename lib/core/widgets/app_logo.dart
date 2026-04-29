import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color color;

  const AppLogo({
    super.key,
    this.size = 48,
    this.color = AppColors.primary600,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/quizzo.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
