
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../materials/materials_page.dart';

class DashboardPage extends StatelessWidget {
  final String role;

  const DashboardPage({
    super.key,
    required this.role,
  });

  static const Color primary = Color(0xFF3157C8);
  static const Color heading = Color(0xFF1E293B);
  static const Color muted = Color(0xFF64748B);

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
        return 'Pelajari materi Database Systems dan kembangkan kemampuanmu.';
      case 'lecturer':
        return 'Akses materi pembelajaran dan kelola aktivitas mengajarmu.';
      case 'admin':
        return 'Pantau aktivitas aplikasi dan kelola pengguna.';
      default:
        return 'Selamat datang di PijarEdu.';
    }
  }

  IconData get pageIcon {
    switch (role) {
      case 'student':
        return Icons.school_rounded;
      case 'lecturer':
        return Icons.menu_book_rounded;
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.dashboard_rounded;
    }
  }

  String get roleLabel {
    switch (role) {
      case 'student':
        return 'Student';
      case 'lecturer':
        return 'Lecturer';
      case 'admin':
        return 'Administrator';
      default:
        return role;
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal keluar. Silakan coba lagi.'),
        ),
      );
    }
  }

  void _openMaterials(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaterialsPage(role: role),
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: primary,
                  size: 25,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: heading,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: muted,
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Buka halaman',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'PijarEdu',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            final horizontalPadding = isWide ? 36.0 : 20.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${roleLabel}!',
                        style: const TextStyle(
                          fontSize: 14,
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pageTitle,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: heading,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 26),

                      // Banner utama
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF3157C8),
                              Color(0xFF5278E8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(
                                  alpha: 0.16,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                roleLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              role == 'student'
                                  ? 'Siap belajar hari ini?'
                                  : 'Selamat datang di PijarEdu!',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              role == 'student'
                                  ? 'Temukan materi baru dan terus tingkatkan pemahamanmu.'
                                  : description,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Color(0xFFE7ECFF),
                              ),
                            ),
                            const SizedBox(height: 22),
                            FilledButton.icon(
                              onPressed: () => _openMaterials(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                              ),
                              icon: const Icon(
                                Icons.menu_book_rounded,
                              ),
                              label: const Text('Jelajahi Materi'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                      const Text(
                        'Menu Pembelajaran',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: heading,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pilih menu untuk melanjutkan aktivitasmu.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Kartu menyesuaikan lebar layar
                      GridView.count(
                        crossAxisCount: isWide ? 3 : 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics:
                        const NeverScrollableScrollPhysics(),
                        childAspectRatio: isWide ? 1.35 : 2.0,
                        children: [
                          _featureCard(
                            icon: pageIcon,
                            title: 'Materi Pembelajaran',
                            subtitle: role == 'student'
                                ? 'Pelajari materi Database Systems.'
                                : 'Buka materi pembelajaran yang tersedia.',
                            onTap: () => _openMaterials(context),
                          ),
                          _featureCard(
                            icon: Icons.person_outline_rounded,
                            title: 'Profil Akun',
                            subtitle: 'Periksa informasi akun yang sedang digunakan.',
                            onTap: () {
                              showDialog<void>(
                                context: context,
                                builder: (dialogContext) {
                                  return AlertDialog(
                                    title: const Text('Profil Akun'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        const Text('Email'),
                                        const SizedBox(height: 4),
                                        SelectableText(email),
                                        const SizedBox(height: 16),
                                        const Text('Role'),
                                        const SizedBox(height: 4),
                                        Text(roleLabel),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext),
                                        child: const Text('Tutup'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          _featureCard(
                            icon: Icons.logout_rounded,
                            title: 'Keluar',
                            subtitle: 'Akhiri sesi akun dengan aman.',
                            onTap: () => _logout(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.account_circle_outlined,
                                color: primary,
                                size: 26,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Akun yang sedang digunakan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: heading,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    SelectableText(
                                      email,
                                      style: const TextStyle(
                                        color: muted,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Role: $roleLabel',
                                      style: const TextStyle(
                                        color: muted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Center(
                        child: Text(
                          'PijarEdu • Platform Pembelajaran',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
