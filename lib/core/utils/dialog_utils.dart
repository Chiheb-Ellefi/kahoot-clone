import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class DialogUtils {
  static void showError(BuildContext context, String message, {VoidCallback? onClose}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primary800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error400, size: 28),
            const SizedBox(width: 8),
            Text(
              'Error',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.nunito(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (onClose != null) onClose();
            },
            child: Text('OK', style: GoogleFonts.nunito(color: AppColors.primary200, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static void showSuccess(BuildContext context, String title, String message, {VoidCallback? onClose}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primary800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success400, size: 28),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.nunito(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (onClose != null) onClose();
            },
            child: Text('OK', style: GoogleFonts.nunito(color: AppColors.primary200, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
