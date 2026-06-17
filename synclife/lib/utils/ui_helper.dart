import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UIHelper {
  static void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 4,
      ),
    );
  }

  static void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 4,
      ),
    );
  }

  static Widget renderHabitIcon(String iconString, {double size = 24, Color? color}) {
    if (iconString.isEmpty) return Text('⭐', style: TextStyle(fontSize: size));
    final codePoint = int.tryParse(iconString);
    if (codePoint != null) {
      return Icon(IconData(codePoint, fontFamily: 'MaterialIcons'), size: size, color: color ?? Colors.white);
    }
    return Text(iconString, style: TextStyle(fontSize: size));
  }

  static Future<bool?> showUncheckConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.colorScheme.onSurfaceVariant;
    final cardColor = theme.colorScheme.surface;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Batalkan penyelesaian habit ini?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textColor),
        ),
        content: Text(
          'Tindakan ini akan menghapus log habit hari ini.',
          style: GoogleFonts.inter(color: subtitleColor),
        ),
        backgroundColor: cardColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.inter(color: subtitleColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Ya, Batalkan',
              style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
