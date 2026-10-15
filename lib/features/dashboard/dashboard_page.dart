
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../materials/materials_page.dart';

class DashboardPage extends StatelessWidget {
  final String role;

  const DashboardPage({
    super.key,
    required this.role,
  });

  String get pageTitle {
    switch (role) {
      case 'student':
        return 'Dashboard Student';
      case 'lecturer':
        return 'Dashboard Lecturer';
      case 'admin':
        return 'Dashboard Admin';
      default:
        return 'Dashboard';
    }
  }

  String get description {
    switch (role) {
      case 'student':
        return 'Pelajari materi Database Systems dan kerjakan tes.';
      case 'lecturer':
        return 'Kelola materi, video, soal, dan hasil belajar mahasiswa.';
      case 'admin':
        return 'Kelola akun Lecturer dan pantau pengguna aplikasi.';
      default:
        return '';
    }
  }

  IconData get pageIcon {
    switch (role) {
      case 'student':
        return Icons.school;
      case 'lecturer':
        return Icons.menu_book;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.dashboard;
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal keluar. Silakan coba lagi.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('PijarEdu'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(pageIcon, size: 72),
              const SizedBox(height: 16),
              Text(
                pageTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(email),
                  subtitle: Text('Role: $role'),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MaterialsPage(role: role),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Materi Pembelajaran'),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Dashboard awal berhasil ditampilkan. '
                    'Fitur pembelajaran akan ditambahkan berikutnya.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
