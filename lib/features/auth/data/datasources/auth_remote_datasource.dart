import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  // Google Sign-In via OAuth redirect (works on web/desktop)
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: Uri.base.origin,
    );
  }

  Future<void> signInWithPhone(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<User> verifyOtp(String phone, String otp) async {
    final res = await _client.auth.verifyOTP(
      type: OtpType.sms, phone: phone, token: otp,
    );
    await _upsertProfile(res.user!);
    return res.user!;
  }

  Future<User> signInWithEmail(String email, String password) async {
    final res = await _client.auth.signInWithPassword(
        email: email, password: password);
    return res.user!;
  }

  Future<User> signUpWithEmail(String email, String password, String username) async {
    final res = await _client.auth.signUp(email: email, password: password);
    if (res.user != null) {
      await _client.from('profiles').upsert({
        'id': res.user!.id, 'email': email, 'username': username,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    return res.user!;
  }

  Future<void> signOut() async => await _client.auth.signOut();

  User? getCurrentUser() => _client.auth.currentUser;

  Future<void> _upsertProfile(User user) async {
    await _client.from('profiles').upsert({
      'id': user.id,
      'email': user.email ?? '',
      'username': user.userMetadata?['full_name'] ??
          user.email?.split('@').first ?? 'User',
      'avatar_url': user.userMetadata?['avatar_url'],
    }, onConflict: 'id');
  }
}
