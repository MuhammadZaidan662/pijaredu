import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../core/widgets/home_widgets.dart';
import '../../core/widgets/pijar_logo.dart';
import '../materials/materials_page.dart';
import '../shell/app_tab.dart';
import 'home_data.dart';

/// Home for every role. Student sees learning shortcuts, lecturer/admin see
/// management shortcuts. Shortcuts jump to a tab by name ([AppTab]).
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.role,
    required this.future,
    required this.onRefresh,
    required this.onGoToTab,
  });

  final String role;
  final Future<HomeData> future;
  final Future<void> Function() onRefresh;
  final ValueChanged<AppTab> onGoToTab;

  bool get _isStudent => role == 'student';

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

  List<MenuItem> _menu(BuildContext context) {
    if (_isStudent) {
      return [
        MenuItem(
          icon: Icons.menu_book_rounded,
          label: 'Materials',
          color: AppColors.tilePurple,
          onTap: () => onGoToTab(AppTab.materials),
        ),
        MenuItem(
          icon: Icons.play_circle_rounded,
          label: 'Videos',
          color: AppColors.tilePink,
          onTap: () => showComingSoon(context, 'Videos'),
        ),
        MenuItem(
          icon: Icons.terminal_rounded,
          label: 'SQL Editor',
          color: AppColors.tileYellow,
          onTap: () => onGoToTab(AppTab.sql),
        ),
        MenuItem(
          icon: Icons.quiz_rounded,
          label: 'Pretest',
          color: AppColors.tileGreen,
          onTap: () => onGoToTab(AppTab.tests),
        ),
        MenuItem(
          icon: Icons.fact_check_rounded,
          label: 'Posttest',
          color: AppColors.tileBlue,
          onTap: () => onGoToTab(AppTab.tests),
        ),
        MenuItem(
          icon: Icons.bar_chart_rounded,
          label: 'Results',
          color: AppColors.tilePurple,
          onTap: () => onGoToTab(AppTab.tests),
        ),
        MenuItem(
          icon: Icons.trending_up_rounded,
          label: 'Progress',
          color: AppColors.tilePink,
          onTap: () => showComingSoon(context, 'Progress'),
        ),
        MenuItem(
          icon: Icons.person_rounded,
          label: 'Profile',
          color: AppColors.tileYellow,
          onTap: () => onGoToTab(AppTab.profile),
        ),
      ];
    }

    return [
      MenuItem(
        icon: Icons.menu_book_rounded,
        label: 'Materials',
        color: AppColors.tilePurple,
        onTap: () => onGoToTab(AppTab.materials),
      ),
      MenuItem(
        icon: Icons.play_circle_rounded,
        label: 'Videos',
        color: AppColors.tilePink,
        onTap: () => showComingSoon(context, 'Videos'),
      ),
      MenuItem(
        icon: Icons.quiz_rounded,
        label: 'Pretest Questions',
        color: AppColors.tileGreen,
        onTap: () => onGoToTab(AppTab.tests),
      ),
      MenuItem(
        icon: Icons.fact_check_rounded,
        label: 'Posttest Questions',
        color: AppColors.tileBlue,
        onTap: () => onGoToTab(AppTab.tests),
      ),
      MenuItem(
        icon: Icons.groups_rounded,
        label: 'Students',
        color: AppColors.tileYellow,
        onTap: () => showComingSoon(context, 'Students'),
      ),
      MenuItem(
        icon: Icons.terminal_rounded,
        label: 'SQL Editor',
        color: AppColors.tileGreen,
        onTap: () => onGoToTab(AppTab.sql),
      ),
      MenuItem(
        icon: Icons.bar_chart_rounded,
        label: 'Results',
        color: AppColors.tilePurple,
        onTap: () => onGoToTab(AppTab.tests),
      ),
      MenuItem(
        icon: Icons.person_rounded,
        label: 'Profile',
        color: AppColors.tilePink,
        onTap: () => onGoToTab(AppTab.profile),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<HomeData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _content(context, snapshot.data!);
          }
          if (snapshot.hasError) {
            return HomeLoadError(
              message: 'Could not load your data.\n${snapshot.error}',
              onRetry: () => onRefresh(),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _content(BuildContext context, HomeData data) {
    final firstName = data.name.split(' ').first;
    final count = data.materialCount;
    final updates = data.latestMaterials;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome back,',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textGrey,
                              ),
                            ),
                            Text(
                              firstName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PijarLogo(size: 44),
                    ],
                  ),
                  const SizedBox(height: 20),
                  HeroCard(
                    name: data.name,
                    roleLabel: _roleLabel,
                    pillLabel: '$count ${count == 1 ? 'material' : 'materials'}',
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Menu'),
                  const SizedBox(height: 12),
                  MenuGrid(items: _menu(context)),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'Latest Updates',
                    actionLabel: updates.isEmpty ? null : 'See all',
                    onAction: () => onGoToTab(AppTab.materials),
                  ),
                  const SizedBox(height: 8),
                  if (updates.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'No materials yet.',
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                    )
                  else
                    for (final material in updates) ...[
                      UpdateCard(
                        title: material['title']?.toString() ?? 'Untitled',
                        subtitle: _subtitleFor(material),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MaterialDetailPage(material: material),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _subtitleFor(Map<String, dynamic> material) {
    final description = material['description']?.toString() ?? '';
    final isDraft = !_isStudent && material['is_published'] != true;
    if (!isDraft) return description;
    return description.isEmpty ? 'Draft' : 'Draft · $description';
  }
}