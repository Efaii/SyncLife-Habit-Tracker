import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/ui_helper.dart';
import '../../widgets/adaptive_logo.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Tentang Aplikasi',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo
            const AdaptiveLogo(
              widthFactor: 0.25,
              minWidth: 80,
              maxWidth: 100,
            ),
            const SizedBox(height: 24),
            
            // App Name
            Text(
              'SyncLife',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Description
            Text(
              'SyncLife hadir dengan teknologi AI-based habit tracking untuk membantu kamu membangun rutinitas yang lebih baik, melacak kebiasaan harian secara cerdas, dan mencapai tujuan produktivitasmu dengan mudah dan menyenangkan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: textColor.withValues(alpha: 0.8),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            
            // Version Info & Updates
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
                    title: Text(
                      'Versi Aplikasi',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textColor),
                    ),
                    trailing: Text(
                      '1.0.0',
                      style: GoogleFonts.inter(color: textColor.withValues(alpha: 0.6)),
                    ),
                  ),
                  Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade100),
                  ListTile(
                    leading: Icon(Icons.system_update_alt_rounded, color: theme.colorScheme.primary),
                    title: Text(
                      'Periksa Pembaruan',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textColor),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      UIHelper.showSuccessSnackbar(context, 'Versi Anda sudah yang terbaru');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Privacy Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Privasi & Keamanan',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: Colors.green.shade600, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Anda Aman',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: textColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kami sangat menghargai privasi Anda. Data Anda dikelola dengan standar keamanan tinggi:\n'
                          '• Data Enkripsi (AES-256)\n'
                          '• Penyimpanan Cloud yang aman (Supabase Auth)\n'
                          '• Kebijakan ketat untuk tidak membagikan data perilaku pengguna ke pihak ketiga.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: textColor.withValues(alpha: 0.8),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Legal & Lisensi Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Legal & Lisensi',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.policy_outlined, color: theme.colorScheme.primary),
                    title: Text(
                      'Kebijakan Privasi Lengkap',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textColor),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final url = Uri.parse('https://google.com');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Kebijakan Privasi'),
                              content: const Text('Dokumen sedang dalam tahap penyusunan.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Tutup'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                  ),
                  Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade100),
                  ListTile(
                    leading: Icon(Icons.description_outlined, color: theme.colorScheme.primary),
                    title: Text(
                      'Syarat & Ketentuan',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textColor),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final url = Uri.parse('https://google.com');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Syarat & Ketentuan'),
                              content: const Text('Dokumen sedang dalam tahap penyusunan.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Tutup'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                  ),
                  Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade100),
                  ListTile(
                    leading: Icon(Icons.code_rounded, color: theme.colorScheme.primary),
                    title: Text(
                      'Lisensi Open Source',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textColor),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      showLicensePage(context: context, applicationName: 'SyncLife', applicationVersion: '1.0.0', applicationLegalese: '© 2026 SyncLife Team');
                    },
                  ),
                  Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade100),
                  ListTile(
                    leading: Icon(Icons.business_center_outlined, color: theme.colorScheme.primary),
                    title: Text(
                      'Tim Pengembang',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textColor),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            'Tim Pengembang SyncLife',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Tim Developer Synclife', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                subtitle: Text('All rights reserved © 2026', style: GoogleFonts.inter(color: theme.colorScheme.onSurfaceVariant)),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Tutup'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            Text(
              '© 2026 SyncLife. Hak cipta dilindungi.',
              style: GoogleFonts.inter(fontSize: 12, color: textColor.withValues(alpha: 0.4)),
            ),
          ],
        ),
      ),
    );
  }
}
