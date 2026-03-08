import 'package:autocare_pro/data/repositories/user_repository.dart';
import 'package:autocare_pro/core/theme/app_theme.dart';
import 'package:autocare_pro/presentation/widgets/common/realistic_container.dart';
import 'package:autocare_pro/presentation/widgets/common/neumorphic_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

final mechanicsListProvider = FutureProvider((ref) => ref.watch(userRepositoryProvider).getAllMechanics());

class MechanicsListScreen extends ConsumerWidget {
  const MechanicsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mechanicsAsync = ref.watch(mechanicsListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? AppTheme.nmBaseDark : AppTheme.nmBaseLight;

    return Scaffold(
      backgroundColor: baseColor,
      body: Column(
        children: [
          // Neumorphic Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
            child: Row(
              children: [
                NeumorphicIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 20),
                Text(
                  'Mechanics',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B), // Slate 800
                  ),
                ),
                const Spacer(),
                NeumorphicIconButton(
                  icon: Icons.person_add_rounded,
                  onTap: () => context.push('/mechanics/add'),
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),

          Expanded(
            child: mechanicsAsync.when(
              data: (mechanics) {
                if (mechanics.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.engineering_rounded, size: 60, color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('No mechanics registered', style: GoogleFonts.inter(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(mechanicsListProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    itemCount: mechanics.length,
                    itemBuilder: (context, index) {
                      final mechanic = mechanics[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: RealisticContainer(
                          padding: const EdgeInsets.all(20),
                          borderRadius: 30,
                          child: InkWell(
                            onTap: () => context.push('/mechanics/${mechanic.id}', extra: mechanic),
                            child: Row(
                              children: [
                                RealisticContainer(
                                  padding: EdgeInsets.zero,
                                  borderRadius: 100,
                                  width: 56,
                                  height: 56,
                                  state: NeumorphicState.convex,
                                  depth: 4,
                                  child: Center(
                                    child: Text(
                                      mechanic.name.isNotEmpty ? mechanic.name[0].toUpperCase() : 'M',
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mechanic.name,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          color: isDark ? Colors.white : const Color(0xFF1E293B), // Slate 800
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        mechanic.email,
                                        style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        children: mechanic.skills.take(2).map((skill) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            skill,
                                            style: GoogleFonts.inter(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                                          ),
                                        )).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    RealisticContainer(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      borderRadius: 12,
                                      state: NeumorphicState.concave,
                                      depth: 2,
                                      child: Text(
                                        mechanic.status,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: mechanic.status == 'Active' ? Colors.green : Colors.red,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '${mechanic.experience} Yrs Exp',
                                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
