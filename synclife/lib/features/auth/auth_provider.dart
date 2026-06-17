import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kDebugMode ? Uri.base.origin : null,
      );
      return;
    }

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '826729222123-7ftqfeg6kvbauctrm2hca1373k41lgvf.apps.googleusercontent.com', // Use the Web Client ID here
      );

      // 1. Trigger the Google Authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      // If user cancels the sign-in
      if (googleUser == null) {
        return; 
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('No ID Token found.');
      }

      // 3. Authenticate with Supabase using the retrieved tokens
      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
    } catch (error) {
      // Handle and log error appropriately
      debugPrint('Google Sign-In Error: $error');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      }
      
      // Wipe SharedPreferences to ensure no stale PKCE or corrupted session remains
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Error during robust signOut: $e');
    }
  }
}
