import 'package:flutter/material.dart';

import '../../app/theme.dart';

class BottomBarItem {
  const BottomBarItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  /// Not drawn on screen. Used for screen readers and long-press tooltips.
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Icon-only bottom bar with a round highlighted button in the middle.
///
/// Sizes follow the reference: 72 high, 24 icons, 52 center button inside a
/// 72 halo. The item at [centerIndex] is drawn as the round button.
class PijarBottomBar extends StatelessWidget {
  const PijarBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.centerIndex,
  });

  final List<BottomBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int centerIndex;

  static const double _barHeight = 72;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: AppColors.primary.withValues(alpha: 0.25),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _barHeight,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: i == centerIndex
                      ? _CenterButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  )
                      : _BarIcon(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarIcon extends StatelessWidget {
  const _BarIcon({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final BottomBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: Tooltip(
        message: item.label,
        child: InkResponse(
          onTap: onTap,
          radius: 32,
          child: Center(
            child: Icon(
              selected ? item.selectedIcon : item.icon,
              size: 26,
              color: selected ? AppColors.primary : AppColors.textGrey,
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final BottomBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: Tooltip(
        message: item.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 68,
              height: 68,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary
                    .withValues(alpha: selected ? 0.22 : 0.10),
              ),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  item.selectedIcon,
                  size: 26,
                  color: selected ? AppColors.spark : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}