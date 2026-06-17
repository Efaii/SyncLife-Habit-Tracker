import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/providers/theme_provider.dart';

import '../profile/edit_profile_screen.dart';
import '../profile/profile_provider.dart';
import '../../widgets/logout_button.dart';
import 'help_center_screen.dart';
import 'about_app_screen.dart';
import '../../core/services/notification_service.dart';
import '../habits/habit_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _localSmartReminders;
  bool? _localStreakAlerts;
  Timer? _debounceTimer;

  void _updateSettingsDB() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    final currentSmart = _localSmartReminders;
    final currentStreak = _localStreakAlerts;
    
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      await ref.read(profileRepositoryProvider).upsertProfile(
        user.id,
        smartReminders: currentSmart,
        streakAlerts: currentStreak,
      );
      
      if (currentStreak == false) {
        await NotificationService().cancelStreakAlert();
      }
      
      if (currentSmart == false) {
        final habits = await ref.read(habitRepositoryProvider).getHabits();
        await NotificationService().cancelSmartReminders(habits);
      }

      ref.invalidate(profileProvider);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Widget Helper: Theme Selector Tile
  Widget _buildThemeSelectorTile({
    required ThemeMode currentThemeMode,
    required Color textColor,
    required Color subtitleColor,
    required Color iconBgColor,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                child: Icon(Icons.palette_rounded, color: isDarkMode ? Colors.white : const Color(0xFF2B3A8C), size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tampilan Tema', 
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pilih mode tema aplikasi', 
                      style: GoogleFonts.inter(fontSize: 13, color: subtitleColor)
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('Sistem'), icon: Icon(Icons.brightness_auto_rounded)),
                  ButtonSegment(value: ThemeMode.light, label: Text('Terang'), icon: Icon(Icons.light_mode_rounded)),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Gelap'), icon: Icon(Icons.dark_mode_rounded)),
                ],
                selected: {currentThemeMode},
                onSelectionChanged: (Set<ThemeMode> newSelection) {
                  ref.read(themeProvider.notifier).setTheme(newSelection.first);
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: isDarkMode ? const Color(0xFF5A72EA).withValues(alpha: 0.2) : const Color(0xFF2B3A8C).withValues(alpha: 0.1),
                  selectedForegroundColor: isDarkMode ? const Color(0xFF90A4AE) : const Color(0xFF2B3A8C),
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackInitial(String fullName) {
    return Text(
      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
      style: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.value;
    final user = Supabase.instance.client.auth.currentUser;

    final String? avatarUrl = profile?.avatarUrl;
    final String fullName = profile?.fullName ?? 'Pengguna';
    final String bio = (profile?.bio != null && profile!.bio!.isNotEmpty) 
        ? profile.bio! 
        : 'Belum ada bio';
    
    // Palet Warna Dinamis
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    final iconBgColor = isDarkMode ? Colors.white12 : const Color(0xFF2B3A8C).withValues(alpha: 0.08);

    // Warna khusus untuk tombol Log Out
    final logoutColor = isDarkMode ? Colors.red.shade400 : Colors.red.shade700;
    final logoutBgColor = isDarkMode ? Colors.red.withValues(alpha: 0.1) : Colors.red.shade50;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Pengaturan',
          style: GoogleFonts.outfit(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KARTU PROFIL
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                    );
                    if (result == true) {
                      setState(() {});
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
                    child: Row(
                      children: [
                        // Avatar with subtle border
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: theme.colorScheme.primary,
                            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? CachedNetworkImageProvider(avatarUrl)
                                : null,
                            child: (avatarUrl == null || avatarUrl.isEmpty)
                                ? Text(
                                    fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                                    style: GoogleFonts.outfit(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Text details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                fullName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bio,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: subtitleColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Sleek Edit Button
                        IconButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                            );
                            if (result == true) {
                              setState(() {});
                            }
                          },
                          icon: Icon(
                            Icons.edit_outlined,
                            color: subtitleColor,
                            size: 22,
                          ),
                          tooltip: 'Edit Profil',
                          style: IconButton.styleFrom(
                            backgroundColor: iconBgColor,
                            shape: const CircleBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            Text(
              'Preferensi',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            
            // 2. GRUP PENGATURAN PREFERENSI
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildThemeSelectorTile(
                    currentThemeMode: currentThemeMode,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    iconBgColor: iconBgColor,
                    isDarkMode: isDarkMode,
                  ),
                  _buildDivider(isDarkMode),
                  _buildSwitchTile(
                    icon: Icons.auto_awesome,
                    title: 'Pengingat Cerdas',
                    subtitle: 'Notifikasi prediktif berdasarkan AI',
                    value: _localSmartReminders ?? profile?.smartReminders ?? true,
                    onChanged: (val) {
                      setState(() => _localSmartReminders = val);
                      _updateSettingsDB();
                    },
                    iconBgColor: iconBgColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    isDarkMode: isDarkMode,
                  ),
                  _buildDivider(isDarkMode),
                  _buildSwitchTile(
                    icon: Icons.local_fire_department_rounded,
                    title: 'Peringatan Streak',
                    subtitle: 'Beri tahu jika streak saya dalam bahaya',
                    value: _localStreakAlerts ?? profile?.streakAlerts ?? true,
                    onChanged: (val) {
                      setState(() => _localStreakAlerts = val);
                      _updateSettingsDB();
                    },
                    iconBgColor: iconBgColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Text(
              'Bantuan & Informasi',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            
            // 3. GRUP PENGATURAN LAINNYA
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildActionTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Pusat Bantuan',
                    iconBgColor: iconBgColor,
                    textColor: textColor,
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
                      );
                    },
                  ),
                  _buildDivider(isDarkMode),
                  _buildActionTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Tentang Aplikasi',
                    iconBgColor: iconBgColor,
                    textColor: textColor,
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AboutAppScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),

            // 4. TOMBOL LOG OUT
            LogoutButton(
              isDarkMode: isDarkMode,
              logoutColor: logoutColor,
              logoutBgColor: logoutBgColor,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widget Helper: Garis Pemisah (Divider) yang rapi
  Widget _buildDivider(bool isDarkMode) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDarkMode ? Colors.white10 : Colors.grey.shade100,
      indent: 76,
      endIndent: 24,
    );
  }

  // Widget Helper: Menu dengan Switch Toggle
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color iconBgColor,
    required Color textColor,
    required Color subtitleColor,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isDarkMode ? Colors.white : const Color(0xFF2B3A8C),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF2B3A8C),
            inactiveThumbColor: isDarkMode ? Colors.grey.shade400 : Colors.white,
            inactiveTrackColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  // Widget Helper: Menu Biasa dengan Panah
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color iconBgColor,
    required Color textColor,
    required bool isDarkMode,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isDarkMode ? Colors.white : const Color(0xFF2B3A8C),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDarkMode ? Colors.white30 : Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}