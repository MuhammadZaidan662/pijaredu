import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/widgets/home_widgets.dart';
import '../../core/widgets/user_avatar.dart';
import '../dashboard/home_data.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.role,
    required this.future,
    required this.onRefresh,
  });

  final String role;
  final Future<HomeData> future;
  final Future<void> Function() onRefresh;

  String get _roleLabel {
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

  Future<void> _edit(BuildContext context, HomeData data) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(role: role, data: data),
      ),
    );
    if (changed == true) await onRefresh();
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to log in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // AuthGate listens to the session and returns to the login screen.
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not log out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<HomeData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasData) return _content(context, snapshot.data!);
          if (snapshot.hasError) {
            return HomeLoadError(
              message: 'Could not load your profile.\n${snapshot.error}',
              onRetry: () => onRefresh(),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _content(BuildContext context, HomeData data) {
    final studentNumber = data.studentNumber ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Semantics(
                          button: true,
                          label: 'Edit profile photo',
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _edit(context, data),
                            child: UserAvatar(
                              name: data.name,
                              imageUrl: data.avatarUrl,
                              size: 96,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          data.name,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _roleLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () => _edit(context, data),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit profile'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            minimumSize: const Size(0, 46),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(AppRadius.button),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.person_outline,
                          label: 'Full name',
                          value: data.name,
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: data.email,
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          icon: Icons.badge_outlined,
                          label: 'Role',
                          value: _roleLabel,
                        ),
                        if (role == 'student') ...[
                          const Divider(height: 1),
                          _InfoRow(
                            icon: Icons.numbers_rounded,
                            label: 'Student ID',
                            value: studentNumber,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textGrey,
                  ),
                ),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}