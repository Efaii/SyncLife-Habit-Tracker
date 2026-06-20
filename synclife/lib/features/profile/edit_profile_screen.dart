import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  
  Uint8List? _localImageBytes;
  bool _hasUnsavedImage = false;

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
    // Note: _hasUnsavedImage is handled independently
    if (_hasUnsavedChanges != (hasChanges || _hasUnsavedImage)) {
      setState(() => _hasUnsavedChanges = (hasChanges || _hasUnsavedImage));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImageForPreview() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      var bytes = await image.readAsBytes();
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 500,
        minHeight: 500,
        quality: 70,
      );
      setState(() {
        _localImageBytes = compressed;
        _hasUnsavedImage = true;
        _hasUnsavedChanges = true;
      });
    } catch (e) {
      if (mounted) {
        UIHelper.showErrorSnackbar(context, 'Gagal memproses foto: $e');
      }
    }
  }

  Future<void> _updateProfile() async {
    final newName = _nameController.text.trim();
    final newBio = _bioController.text.trim();
    
    if (newName.isEmpty) {
      UIHelper.showErrorSnackbar(context, 'Nama tidak boleh kosong');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      String? newAvatarUrl;

      // Defer upload to the Save process
      if (_hasUnsavedImage && _localImageBytes != null) {
        final fileName = '${user.id}_avatar.png'; 
        
        await _supabase.storage.from('avatars').uploadBinary(
          'public/$fileName',
          _localImageBytes!,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/png'),
        );
        
        final publicUrl = _supabase.storage.from('avatars').getPublicUrl('public/$fileName');
        newAvatarUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
        
        final oldAvatarUrl = ref.read(profileProvider).value?.avatarUrl;
        if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
          await CachedNetworkImage.evictFromCache(oldAvatarUrl);
        }
      }

      final updates = <String, dynamic>{
        'full_name': newName,
        'bio': newBio,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (newAvatarUrl != null) {
        updates['avatar_url'] = newAvatarUrl;
      }
      
      // Use partial update if row exists to prevent null overwrites
      final existing = await _supabase.from('profiles').select('id').eq('id', user.id).maybeSingle();
      if (existing != null) {
        await _supabase.from('profiles').update(updates).eq('id', user.id);
      } else {
        updates['id'] = user.id;
        await _supabase.from('profiles').insert(updates);
      }
      
      ref.invalidate(profileProvider);

      if (mounted) {
        UIHelper.showSuccessSnackbar(context, 'Profil berhasil disimpan!');
        _hasUnsavedChanges = false;
        _hasUnsavedImage = false;
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
    if (_isLoading) return;

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
      setState(() => _isLoading = true);
      try {
        // Step A: Call the Supabase RPC function to delete the user
        await _supabase.rpc('delete_user');
        
        // Step B: Wrap the local cleanup in a separate try-catch to ignore session_not_found
        try {
          await ref.read(authRepositoryProvider).signOut();
        } on AuthApiException catch (e) {
          if (e.statusCode == '403' || e.message.contains('session_not_found')) {
            // Ignore this error: session is already destroyed, which is expected.
          } else {
            debugPrint('Logout Error: $e');
          }
        } catch (e) {
          debugPrint('Unknown Logout Error: $e');
        }

        // Step C: Clear any local SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Clear providers state
        ref.read(bottomNavIndexProvider.notifier).setIndex(0);
        ref.invalidate(habitsProvider);
        ref.invalidate(todayCompletedHabitsProvider);
        ref.invalidate(statisticsProvider);
        ref.invalidate(predictionProvider);
        ref.invalidate(profileProvider);

        // Step D: Redirect the user back to the login screen
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          UIHelper.showErrorSnackbar(context, 'Akun tidak dapat dihapus: $e');
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
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
                      onTap: _isLoading ? null : _pickImageForPreview,
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
                              child: _localImageBytes != null
                                  ? Image.memory(
                                      _localImageBytes!,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                    )
                                  : (avatarUrl != null && avatarUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: avatarUrl,
                                          fit: BoxFit.cover,
                                          memCacheWidth: 200,
                                          placeholder: (context, url) => const CircularProgressIndicator(),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.person_rounded, size: 50, color: Color(0xFF2B3A8C)),
                                        )
                                      : const Icon(Icons.person_rounded, size: 50, color: Color(0xFF2B3A8C))),
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
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _bioController,
                  style: GoogleFonts.inter(color: textColor),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Bio Singkat',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_hasUnsavedChanges && !_isLoading) ? _updateProfile : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B3A8C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Simpan Perubahan', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Zona Bahaya
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.red),
                          const SizedBox(width: 8),
                          Text('Zona Bahaya', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Menghapus akun akan memusnahkan semua data habit, statistik, dan riwayat secara permanen.',
                        style: GoogleFonts.inter(color: isDarkMode ? Colors.red.shade200 : Colors.red.shade700, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleDeleteAccount,
                          icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                          label: Text('Hapus Akun Permanen', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
