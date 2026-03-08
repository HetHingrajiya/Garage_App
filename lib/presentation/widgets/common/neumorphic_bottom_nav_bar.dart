import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autocare_pro/core/theme/app_theme.dart';
import 'package:autocare_pro/presentation/widgets/common/realistic_container.dart';
import 'package:autocare_pro/data/repositories/auth_repository.dart';

class NeumorphicBottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NeumorphicBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRoleAsync = ref.watch(currentUserRoleProvider);
    final isMechanic = userRoleAsync.value?.toLowerCase() == 'mechanic';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      color: Colors.transparent,
      child: RealisticContainer(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        borderRadius: 30,
        state: NeumorphicState.convex,
        depth: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavBarItem(
              icon: Icons.dashboard_rounded,
              isSelected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            if (!isMechanic)
              _NavBarItem(
                icon: Icons.people_rounded,
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
            _NavBarItem(
              icon: Icons.assignment_rounded,
              isSelected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavBarItem(
              icon: Icons.settings_rounded,
              isSelected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
            _NavBarItem(
              icon: Icons.account_circle_rounded,
              isSelected: currentIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: RealisticContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: 16,
        state: isSelected ? NeumorphicState.concave : NeumorphicState.flat,
        depth: isSelected ? 4 : 0,
        showShadow: isSelected,
        color: isSelected ? null : Colors.transparent,
        child: Icon(
          icon,
          color: isSelected 
            ? AppTheme.primaryColor 
            : (isDark ? Colors.white38 : const Color(0xFFCBD5E1)), // Slate 300
          size: 24,
        ),
      ),
    );
  }
}
