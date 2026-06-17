import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionableNotificationModal extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback primaryAction;
  final String primaryButtonText;
  final VoidCallback? secondaryAction;
  final String? secondaryButtonText;

  const ActionableNotificationModal({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.primaryAction,
    required this.primaryButtonText,
    this.secondaryAction,
    this.secondaryButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final primaryBlue = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    final dialogBgColor = theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface;

    return Dialog(
      backgroundColor: dialogBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: subtitleColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: primaryAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  primaryButtonText,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            if (secondaryAction != null && secondaryButtonText != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: secondaryAction,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: subtitleColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    secondaryButtonText!,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void showAppNotification(
  BuildContext context, {
  required String title,
  required String message,
  required IconData icon,
  required VoidCallback primaryAction,
  required String primaryButtonText,
  VoidCallback? secondaryAction,
  String? secondaryButtonText,
  bool barrierDismissible = true,
}) {
  showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => ActionableNotificationModal(
      title: title,
      message: message,
      icon: icon,
      primaryAction: primaryAction,
      primaryButtonText: primaryButtonText,
      secondaryAction: secondaryAction,
      secondaryButtonText: secondaryButtonText,
    ),
  );
}
