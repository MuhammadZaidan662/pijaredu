import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Self-registration is for students only.
  /// Lecturer accounts are created by an admin, never from the app form.
  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String password,
    String? studentNumber,
  }) async {
    final nim = studentNumber?.trim() ?? '';
    return await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        if (nim.isNotEmpty) 'student_number': nim,
      },
    );
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
}