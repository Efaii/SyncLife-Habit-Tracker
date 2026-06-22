import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import '../../utils/ui_helper.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'petermbal0010@gmail.com',
      query: 'subject=SyncLife Support Request',
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      await Clipboard.setData(const ClipboardData(text: 'support@synclife.com'));
      if (context.mounted) {
        UIHelper.showSuccessSnackbar(context, 'Tidak ada aplikasi email terdeteksi. Alamat email disalin ke clipboard!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Pusat Bantuan',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton.icon(
            onPressed: () => _launchEmail(context),
            icon: const Icon(Icons.support_agent_rounded),
            label: Text(
              'Butuh Bantuan Lain? Hubungi Kami',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hai, ada yang bisa kami bantu?',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            
            // Penggunaan Dasar
            Text(
              'Penggunaan Dasar',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              context,
              'Bagaimana cara menambah kebiasaan baru?',
              'Anda dapat menambah kebiasaan baru dengan menekan tombol "+" di bagian tengah layar utama. Kemudian masukkan detail kebiasaan Anda.',
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              context,
              'Apakah aplikasi bisa digunakan offline?',
              'Ya! Anda tetap bisa mencentang kebiasaan tanpa internet. Data akan otomatis disinkronisasi ke cloud ketika perangkat Anda kembali terhubung.',
            ),
            
            const SizedBox(height: 24),
            // Prediksi AI
            Text(
              'Prediksi AI',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              context,
              'Bagaimana cara kerja Prediksi AI?',
              'SyncLife menggunakan algoritma Naive Bayes untuk memprediksi peluang Anda menyelesaikan habit berdasarkan data historis, tingkat kesibukan, dan mood Anda. Fitur ini membutuhkan data konsisten minimal 7 hari (fase kalibrasi) sebelum insight akurat dapat ditampilkan.',
            ),
            
            const SizedBox(height: 24),
            // Akun
            Text(
              'Akun & Privasi',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              context,
              'Apakah data saya aman dan tersinkronisasi?',
              'Sangat aman. Semua data Anda disimpan dengan aman di server cloud (Supabase) dengan aturan keamanan berlapis. Cukup login dengan akun yang sama untuk memulihkan data Anda di perangkat berbeda.',
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: theme.colorScheme.onSurface),
          ),
          iconColor: theme.colorScheme.primary,
          collapsedIconColor: theme.colorScheme.onSurfaceVariant,
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          children: [
            Text(
              answer,
              style: GoogleFonts.inter(fontSize: 14, color: theme.colorScheme.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
