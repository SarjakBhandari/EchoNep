import 'package:echo_nep/core/models/user_role.dart';
import 'package:echo_nep/core/providers/role_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7F1E1), Color(0xFFFFFCF5)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                const Icon(Icons.landscape, size: 74, color: Color(0xFF0B6E99)),
                const SizedBox(height: 18),
                Text(
                  'ECHONEP',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF062A3A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how you want to translate in Nepal',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF5A5A5A),
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                _RoleCard(
                  title: 'I am a Tourist',
                  subtitle: 'English to Nepali',
                  icon: Icons.public, // replaced emoji with icon
                  accentColor: const Color(0xFF0B6E99),
                  onTap: () =>
                      ref.read(roleProvider.notifier).setRole(UserRole.tourist),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  title: 'म व्यापारी हुँ',
                  subtitle: 'नेपाली to English',
                  icon: Icons.store, // replaced emoji with icon
                  accentColor: const Color(0xFFB85C38),
                  onTap: () =>
                      ref.read(roleProvider.notifier).setRole(UserRole.trader),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accentColor.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: accentColor.withOpacity(0.12),
                child: Icon(
                  icon,
                  size: 26,
                  color: accentColor,
                  semanticLabel: title,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF062A3A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: const Color(0xFF5A5A5A),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: accentColor),
            ],
          ),
        ),
      ),
    );
  }
}
