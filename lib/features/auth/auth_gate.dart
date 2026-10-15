
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart';
import '../dashboard/dashboard_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final SupabaseClient _supabase = Supabase.instance.client;

  StreamSubscription<AuthState>? _authSubscription;

  User? _user;
  String? _role;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _authSubscription = _supabase.auth.onAuthStateChange.listen(
          (state) {
        _loadUser(state.session?.user);
      },
    );

    // Periksa juga sesi yang mungkin sudah tersimpan.
    _loadUser(_supabase.auth.currentUser);
  }

  Future<void> _loadUser(User? user) async {
    if (!mounted) return;

    if (user == null) {
      setState(() {
        _user = null;
        _role = null;
        _error = null;
        _loading = false;
      });
      return;
    }

    setState(() {
      _user = user;
      _role = null;
      _error = null;
      _loading = true;
    });

    try {
      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted || _supabase.auth.currentUser?.id != user.id) {
        return;
      }

      if (profile == null) {
        setState(() {
          _error = 'Profil pengguna tidak ditemukan.';
          _loading = false;
        });
        return;
      }

      setState(() {
        _role = profile['role'] as String?;
        _loading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Gagal memuat profil: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted || _supabase.auth.currentUser?.id != user.id) {
        return;
      }

      setState(() {
        _error = 'Gagal memuat profil: $e';
        _loading = false;
      });
    }
  }


@override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_user == null) {
      return const LoginPage();
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _loadUser(_user),
                  child: const Text('Coba Lagi'),
                ),
                TextButton(
                  onPressed: () => _supabase.auth.signOut(),
                  child: const Text('Keluar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!['student', 'lecturer', 'admin'].contains(_role)) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Role pengguna tidak dikenal.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _supabase.auth.signOut(),
                child: const Text('Keluar'),
              ),
            ],
          ),
        ),
      );
    }

    return DashboardPage(role: _role!);
  }
}
