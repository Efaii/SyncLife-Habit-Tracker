import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cached_network_image/cached_network_image.dart';


import '../auth/auth_provider.dart';
import '../home/main_screen.dart'; // for bottomNavIndexProvider
import '../home/dashboard_screen.dart';
import '../statistics/statistics_screen.dart';
import '../predictor/prediction_provider.dart';
import 'profile_provider.dart';
import '../../utils/ui_helper.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  String _initialName = '';
  String _initialBio = '';
  


  @override
  void initState() {
    super.initState();
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _initialName = user.userMetadata?['full_name'] as String? ?? 
          user.email?.split('@').first ?? '';
      _nameController.text = _initialName;

      ref.read(profileProvider.future).then((profile) {
        if (profile != null && mounted) {
           if (profile.fullName != null) {
             _initialName = profile.fullName!;
             _nameController.text = _initialName;
           }
           if (profile.bio != null) {
             _initialBio = profile.bio!;
             _bioController.text = _initialBio;
           }
           // Reset the unsaved flag just in case
           if (mounted) setState(() => _hasUnsavedChanges = false);
        }
      });
    }
    
    // Listeners for unsaved changes
    _nameController.addListener(_onTextChanged);
    _bioController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasChanges = _nameController.text != _initialName || _bioController.text != _initialBio;
    if (_hasUnsavedChanges != hasChanges) {
      setState(() => _hasUnsavedChanges = hasChanges);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      var bytes = await image.readAsBytes();
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 500,
        minHeight: 500,
        quality: 70,
      );
      bytes = compressed;
      
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      final fileName = '${user.id}_avatar.png'; 
      
      await _supabase.storage.from('avatars').uploadBinary(
        'public/$fileName',
        bytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/png'),
      );
      
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl('public/$fileName');
      final uniqueAvatarUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
      
      final oldAvatarUrl = ref.read(profileProvider).value?.avatarUrl;
      if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
        await CachedNetworkImage.evictFromCache(oldAvatarUrl);
      }
      
      await _supabase.from('profiles').update({
        'avatar_url': uniqueAvatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      ref.invalidate(profileProvider);

      if (mounted) {
        UIHelper.showSuccessSnackbar(context, 'Foto profil berhasil diperbarui!');
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        UIHelper.showErrorSnackbar(context, 'Gagal mengunggah foto: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameController.text.trim();
    final newBio = _bioController.text.trim();
    
    setState(() => _isLoading = true);
    
    try {
      await _supabase.from('profiles').update({
        'full_name': newName,
        'bio': newBio,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _supabase.auth.currentUser!.id);
      
      ref.invalidate(profileProvider);

      if (mounted) {
        UIHelper.showSuccessSnackbar(context, 'Profil berhasil disimpan!');
        _hasUnsavedChanges = false;
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        UIHelper.showErrorSnackbar(context, 'Gagal memperbarui profil: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Akun Permanen', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('Apakah Anda yakin ingin menghapus akun ini secara permanen? Semua data Anda akan hilang dan tidak dapat dipulihkan.', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Ya, Hapus Akun', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) {
          // As requested, using the Supabase auth.admin method.
          // Note: This requires the service_role key to be configured in Supabase.
          await _supabase.auth.admin.deleteUser(userId); 
        }
        ref.read(bottomNavIndexProvider.notifier).setIndex(0);
        
        // Clear state
        ref.invalidate(habitsProvider);
        ref.invalidate(todayCompletedHabitsProvider);
        ref.invalidate(statisticsProvider);
        ref.invalidate(predictionProvider);
        ref.invalidate(profileProvider);

        await ref.read(authRepositoryProvider).signOut();
      } catch (e) {
        if (mounted) {
          UIHelper.showErrorSnackbar(context, 'Akun tidak dapat dihapus: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.value;

    final user = _supabase.auth.currentUser;
    final avatarUrl = profile?.avatarUrl ?? user?.userMetadata?['avatar_url'] as String?;
    final email = user?.email ?? '';


    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Perubahan Belum Disimpan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: Text('Ada perubahan yang belum disimpan. Yakin ingin keluar?', style: GoogleFonts.inter()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Batal', style: GoogleFonts.inter(color: theme.colorScheme.primary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Keluar', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        if (shouldPop == true && context.mounted) {
          Navigator.pop(context, true);
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Edit Profil',
            style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.w700),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: textColor),
            onPressed: () async {
              if (_hasUnsavedChanges) {
                final shouldPop = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Perubahan Belum Disimpan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    content: Text('Ada perubahan yang belum disimpan. Yakin ingin keluar?', style: GoogleFonts.inter()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Batal', style: GoogleFonts.inter(color: theme.colorScheme.primary)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Keluar', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
                if (shouldPop == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              } else {
                Navigator.pop(context, true);
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _isLoading ? null : _pickAndUploadImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF2B3A8C).withValues(alpha: 0.1),
                              border: Border.all(color: const Color(0xFF2B3A8C), width: 3),
                            ),
                            child: ClipOval(
                              child: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: avatarUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const CircularProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.person_rounded, size: 50, color: Color(0xFF2B3A8C)),
                                    )
                                  : const Icon(Icons.person_rounded, size: 50, color: Color(0xFF2B3A8C)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2B3A8C),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                Text('Identitas', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 16),
                
                TextFormField(
                  initialValue: email,
                  readOnly: true,
                  style: GoogleFonts.inter(color: isDarkMode ? Colors.white54 : Colors.black54),
                  decoration: InputDecoration(
                    labelText: 'Email (Google)',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade200,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.inter(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDarkMode ? Colors.white10 : Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF2B3A8C), width: 2),
                    ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Nama lengkap tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _bioController,
                  maxLines: 2,
                  style: GoogleFonts.inter(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Deskripsikan sedikit tentang diri Anda...',
                    prefixIcon: const Icon(Icons.info_outline_rounded),
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDarkMode ? Colors.white10 : Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF2B3A8C), width: 2),
                    ),
                  ),
                ),
                

                
                const SizedBox(height: 48),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B3A8C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Simpan Perubahan',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                
                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 24),
                
                Text('Zona Bahaya', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _handleDeleteAccount,
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
                    label: Text('Hapus Akun Permanen', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
                

                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
