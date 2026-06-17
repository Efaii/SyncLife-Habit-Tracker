import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/home/main_screen.dart'; // for bottomNavIndexProvider
import '../features/home/dashboard_screen.dart';
import '../features/statistics/statistics_screen.dart';
import '../features/predictor/prediction_provider.dart';
import '../features/profile/profile_provider.dart';

class LogoutButton extends ConsumerWidget {
  final bool isDarkMode;
  final Color logoutColor;
  final Color logoutBgColor;

  const LogoutButton({
    super.key,
    required this.isDarkMode,
    this.logoutColor = const Color(0xFFE53935),
    this.logoutBgColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () async {
          ref.read(bottomNavIndexProvider.notifier).setIndex(0);
          
          // Clear state on logout
          ref.invalidate(habitsProvider);
          ref.invalidate(todayCompletedHabitsProvider);
          ref.invalidate(statisticsProvider);
          ref.invalidate(predictionProvider);
          ref.invalidate(profileProvider);

          await Supabase.instance.client.auth.signOut();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          }
        },
        icon: Icon(Icons.logout_rounded, color: logoutColor, size: 22),
        label: Text(
          'Keluar',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: logoutColor,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: logoutColor.withValues(alpha: 0.5), width: 1.5),
          backgroundColor: logoutBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
