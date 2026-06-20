import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';
import '../../utils/ui_helper.dart';
import 'register_screen.dart';
import '../home/main_screen.dart';
import '../home/dashboard_screen.dart';
import '../statistics/statistics_screen.dart';
import '../predictor/prediction_provider.dart';
import '../../widgets/adaptive_logo.dart';
import '../profile/profile_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingGoogle = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email') ?? '';
    final savedPassword = prefs.getString('saved_password') ?? '';
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (rememberMe) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setString('saved_password', _passwordController.text.trim());
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await _saveCredentials();
      await ref.read(authRepositoryProvider).signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
          
      // FORCE FETCH ON INITIALIZATION: invalidate cached providers
      ref.invalidate(habitsProvider);
      ref.invalidate(todayCompletedHabitsProvider);
      ref.invalidate(statisticsProvider);
      ref.invalidate(predictionProvider);
      ref.invalidate(profileProvider);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        UIHelper.showErrorSnackbar(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        UIHelper.showErrorSnackbar(context, 'Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoadingGoogle = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      
      // FORCE FETCH ON INITIALIZATION: invalidate cached providers
      ref.invalidate(habitsProvider);
      ref.invalidate(todayCompletedHabitsProvider);
      ref.invalidate(statisticsProvider);
      ref.invalidate(predictionProvider);
      ref.invalidate(profileProvider);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        UIHelper.showErrorSnackbar(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        UIHelper.showErrorSnackbar(context, 'Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingGoogle = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (context) {
        bool isResetting = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Reset Password', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Masukkan email Anda untuk menerima tautan reset password.', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isResetting ? null : () async {
                    if (emailController.text.trim().isEmpty) {
                      UIHelper.showErrorSnackbar(context, 'Email tidak boleh kosong');
                      return;
                    }
                    setStateDialog(() => isResetting = true);
                    try {
                      final email = emailController.text.trim();
                      
                      // 1. Periksa ketersediaan email via RPC
                      final dynamic isRegistered = await Supabase.instance.client.rpc(
                        'check_email_exists', 
                        params: {'email_input': email}
                      );
                      
                      if (!context.mounted) return;
                      
                      if (isRegistered != true) {
                        Navigator.of(context).pop(); // Tutup dialog sebelum snackbar
                        UIHelper.showErrorSnackbar(context, 'Email tidak terdaftar di sistem kami.');
                        return;
                      }

                      // 2. Kirim tautan pemulihan
                      await Supabase.instance.client.auth.resetPasswordForEmail(
                        email,
                        redirectTo: 'io.supabase.synclife://reset-callback/',
                      );
                      
                      if (!context.mounted) return;
                      Navigator.of(context).pop(); // Tutup dialog sebelum snackbar
                      UIHelper.showSuccessSnackbar(context, 'Tautan pemulihan telah dikirim ke email Anda.');
                      
                    } on AuthException catch (e) {
                      if (!context.mounted) return;
                      Navigator.of(context).pop(); // Tutup dialog sebelum snackbar
                      UIHelper.showErrorSnackbar(context, e.message);
                    } catch (e) {
                      if (!context.mounted) return;
                      Navigator.of(context).pop(); // Tutup dialog sebelum snackbar
                      UIHelper.showErrorSnackbar(context, 'Terjadi kesalahan: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B3A8C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isResetting 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : Text('Kirim', style: GoogleFonts.inter(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2B3A8C);
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: AdaptiveLogo(
                    widthFactor: 0.3,
                    minWidth: 100,
                    maxWidth: 150,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Selamat Datang di SyncLife',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in untuk melihat progres Anda',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _emailController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscuringCharacter: '●',
                  style: GoogleFonts.inter(
                    color: textColor,
                    letterSpacing: _obscurePassword ? 2.0 : 0.0,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: primaryBlue,
                        ),
                        Text(
                          'Ingat Saya',
                          style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: Text(
                        'Lupa Password?',
                        style: GoogleFonts.inter(
                          color: primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_isLoading || _isLoadingGoogle) ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Log In',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('ATAU', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: (_isLoading || _isLoadingGoogle) ? null : _loginWithGoogle,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: theme.cardColor,
                    side: BorderSide(color: theme.dividerColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoadingGoogle
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.blue, 
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Lanjutkan dengan Google',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: Text(
                    'Belum punya akun? Daftar sekarang',
                    style: GoogleFonts.inter(
                      color: primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
