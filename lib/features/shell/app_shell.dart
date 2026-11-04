import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/pijar_bottom_bar.dart';
import '../dashboard/home_data.dart';
import '../dashboard/home_page.dart';
import '../materials/materials_page.dart';
import '../profile/profile_page.dart';
import 'app_tab.dart';
import 'coming_soon_page.dart';

/// Main screen after login: icon-only bottom bar on phones (SQL practice is
/// the round button in the middle), side rail on wide screens.
/// Student and Lecturer/Admin share the same five tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.role});

  final String role;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _order = [
    AppTab.home,
    AppTab.materials,
    AppTab.sql,
    AppTab.tests,
    AppTab.profile,
  ];

  int _index = 0;
  late Future<HomeData> _future = loadHomeData();

  bool get _isStudent => widget.role == 'student';

  BottomBarItem _itemFor(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return const BottomBarItem(
          label: 'Home',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        );
      case AppTab.materials:
        return _isStudent
            ? const BottomBarItem(
          label: 'Materials',
          icon: Icons.menu_book_outlined,
          selectedIcon: Icons.menu_book_rounded,
        )
            : const BottomBarItem(
          label: 'Content',
          icon: Icons.folder_copy_outlined,
          selectedIcon: Icons.folder_copy_rounded,
        );
      case AppTab.sql:
        return const BottomBarItem(
          label: 'SQL Practice',
          icon: Icons.terminal_rounded,
          selectedIcon: Icons.terminal_rounded,
        );
      case AppTab.tests:
        return const BottomBarItem(
          label: 'Tests',
          icon: Icons.fact_check_outlined,
          selectedIcon: Icons.fact_check_rounded,
        );
      case AppTab.profile:
        return const BottomBarItem(
          label: 'Profile',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
        );
    }
  }

  Widget _pageFor(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return HomePage(
          role: widget.role,
          future: _future,
          onRefresh: _reload,
          onGoToTab: _goTo,
        );
      case AppTab.materials:
        return MaterialsPage(role: widget.role, embedded: true);
      case AppTab.sql:
        return const ComingSoonPage(
          title: 'SQL Practice',
          icon: Icons.terminal_rounded,
        );
      case AppTab.tests:
        return ComingSoonPage(
          title: _isStudent ? 'Tests' : 'Tests & Results',
          icon: Icons.fact_check_rounded,
        );
      case AppTab.profile:
        return ProfilePage(
          role: widget.role,
          future: _future,
          onRefresh: _reload,
        );
    }
  }

  void _select(int index) => setState(() => _index = index);

  void _goTo(AppTab tab) {
    final index = _order.indexOf(tab);
    if (index >= 0) setState(() => _index = index);
  }

  Future<void> _reload() async {
    final next = loadHomeData();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // The error is shown by the pages that use the future.
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [for (final tab in _order) _pageFor(tab)];
    final items = [for (final tab in _order) _itemFor(tab)];
    final body = IndexedStack(index: _index, children: pages);

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() => _index = 0);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 700;

          if (wide) {
            return Scaffold(
              body: Row(
                children: [
                  SafeArea(
                    child: NavigationRail(
                      selectedIndex: _index,
                      onDestinationSelected: _select,
                      labelType: NavigationRailLabelType.selected,
                      backgroundColor: Colors.white,
                      indicatorColor: AppColors.tilePurple,
                      destinations: [
                        for (final item in items)
                          NavigationRailDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.selectedIcon,
                                color: AppColors.primary),
                            label: Text(item.label),
                          ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              ),
            );
          }

          return Scaffold(
            body: body,
            bottomNavigationBar: PijarBottomBar(
              items: items,
              currentIndex: _index,
              onTap: _select,
              centerIndex: _order.indexOf(AppTab.sql),
            ),
          );
        },
      ),
    );
  }
}