import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';

/// Reusable avatar widget with fallback to initials
/// 
/// Shows user avatar with proper fallback:
/// - If avatarUrl exists: displays cached network image
/// - If null: displays user initial in gradient circle
class AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final double radius;
  final bool showBorder;
  final Color? borderColor;

  const AvatarWidget({
    required this.avatarUrl,
    required this.username,
    this.radius = 24,
    this.showBorder = false,
    this.borderColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final defaultInitial = _getDefaultInitial(username);
    final bgColor = _getBackgroundColor(username);

    return Container(
      decoration: showBorder
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor ?? AppColors.primary400,
                width: 2,
              ),
            )
          : null,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary600,
        backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
            ? CachedNetworkImageProvider(avatarUrl!) as ImageProvider?
            : null,
        child: (avatarUrl == null || avatarUrl!.isEmpty)
            ? Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [bgColor, bgColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    defaultInitial,
                    style: TextStyle(
                      fontSize: radius * 0.8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  String _getDefaultInitial(String name) {
    if (name.isEmpty) return '👤';
    return name[0].toUpperCase();
  }

  Color _getBackgroundColor(String name) {
    final colors = [
      AppColors.primary400,
      AppColors.success400,
      AppColors.accent400,
      AppColors.error400,
    ];
    return colors[name.length % colors.length];
  }
}