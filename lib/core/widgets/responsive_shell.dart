import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../utils/responsive_breakpoints.dart';
import 'njangi_logo.dart';
import 'phosphor_icon.dart';
import 'primary_gradient_button.dart';

class NavDestinationItem {
  const NavDestinationItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final String route;
  final IconData icon;
  final IconData activeIcon;
}

/// Reusable Responsive Shell Widget for Njangiva:
/// - Displays the rounded Bottom Navigation Bar on Mobile (`< 600px`)
///   where the active tab highlights only the icon and label in crimson red.
/// - Displays a Navigation Rail / Sidebar on Tablet & Desktop Web (`>= 600px`)
///   with mouse hover states and a quick "New Savings Goal" CTA.
class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({
    super.key,
    required this.currentLocation,
    required this.child,
  });

  final String currentLocation;
  final Widget child;

  static const List<NavDestinationItem> destinations = [
    NavDestinationItem(
      label: 'Home',
      route: '/home',
      icon: PhosphorIcons.house,
      activeIcon: PhosphorIcons.houseFill,
    ),
    NavDestinationItem(
      label: 'Goals',
      route: '/goals',
      icon: PhosphorIcons.target,
      activeIcon: PhosphorIcons.targetBold,
    ),
    NavDestinationItem(
      label: 'Transactions',
      route: '/transactions',
      icon: PhosphorIcons.arrowsLeftRight,
      activeIcon: PhosphorIcons.arrowsLeftRightBold,
    ),
    NavDestinationItem(
      label: 'Profile',
      route: '/profile',
      icon: PhosphorIcons.user,
      activeIcon: PhosphorIcons.userFill,
    ),
  ];

  int get _selectedIndex {
    if (currentLocation.startsWith('/goals')) return 1;
    if (currentLocation.startsWith('/transactions')) return 2;
    if (currentLocation.startsWith('/profile')) return 3;
    return 0;
  }

  void _onSelectTab(BuildContext context, int index) {
    final target = destinations[index].route;
    if (currentLocation != target) {
      context.go(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizeClass = ResponsiveBreakpoints.of(context);

    if (sizeClass == ScreenSizeClass.compact) {
      return Scaffold(
        backgroundColor: AppColors.softBackground,
        body: child,
        bottomNavigationBar: _MobileBottomNavBar(
          selectedIndex: _selectedIndex,
          onSelect: (index) => _onSelectTab(context, index),
        ),
      );
    }

    final isExpanded = sizeClass == ScreenSizeClass.expanded;

    return Scaffold(
      backgroundColor: AppColors.softBackground,
      body: Row(
        children: [
          _DesktopSidebar(
            selectedIndex: _selectedIndex,
            isExpanded: isExpanded,
            onSelect: (index) => _onSelectTab(context, index),
            onCreateGoal: () => context.push('/goals/create'),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MobileBottomNavBar extends StatelessWidget {
  const _MobileBottomNavBar({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.softBackground,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.9),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkNavy.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: List.generate(ResponsiveShell.destinations.length, (i) {
                final item = ResponsiveShell.destinations[i];
                final isSelected = i == selectedIndex;

                return Expanded(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => onSelect(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            size: 23,
                            color: isSelected
                                ? AppColors.primaryRed
                                : const Color(0xFF4B5563),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primaryRed
                                      : const Color(0xFF4B5563),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.isExpanded,
    required this.onSelect,
    required this.onCreateGoal,
  });

  final int selectedIndex;
  final bool isExpanded;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreateGoal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isExpanded ? 268 : 92,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? 20 : 12,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: isExpanded
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (isExpanded)
                const NjangiBrandHeader(fontSize: 21, badgeSize: 42)
              else
                const NjangiHeroBadge(size: 44, iconSize: 26),
              const SizedBox(height: 32),
              for (var i = 0; i < ResponsiveShell.destinations.length; i++) ...[
                _SidebarNavTile(
                  item: ResponsiveShell.destinations[i],
                  isSelected: i == selectedIndex,
                  isExpanded: isExpanded,
                  onTap: () => onSelect(i),
                ),
                const SizedBox(height: 8),
              ],
              const Spacer(),
              if (isExpanded)
                PrimaryGradientButton(
                  label: 'New Savings Goal',
                  leadingIcon: PhosphorIcons.plusBold,
                  height: 48,
                  onPressed: onCreateGoal,
                )
              else
                IconButton.filled(
                  onPressed: onCreateGoal,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    minimumSize: const Size(48, 48),
                  ),
                  icon: const Icon(PhosphorIcons.plusBold, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarNavTile extends StatefulWidget {
  const _SidebarNavTile({
    required this.item,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  final NavDestinationItem item;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  State<_SidebarNavTile> createState() => _SidebarNavTileState();
}

class _SidebarNavTileState extends State<_SidebarNavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = _hovered ? AppColors.softBackground : Colors.transparent;
    final fgColor = widget.isSelected
        ? AppColors.primaryRed
        : AppColors.secondaryText;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isExpanded ? 16 : 0,
              vertical: 13,
            ),
            child: widget.isExpanded
                ? Row(
                    children: [
                      Icon(
                        widget.isSelected
                            ? widget.item.activeIcon
                            : widget.item.icon,
                        color: fgColor,
                        size: 21,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.item.label,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: widget.isSelected
                                  ? AppColors.primaryRed
                                  : AppColors.darkNavy,
                              fontWeight: widget.isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                      ),
                    ],
                  )
                : Center(
                    child: Icon(
                      widget.isSelected
                          ? widget.item.activeIcon
                          : widget.item.icon,
                      color: fgColor,
                      size: 23,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
