import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/user_role.dart';
import '../../core/providers/role_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';

class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.gradientMid, palette.gradientStart],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF062A3A),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset('assets/branding/logo_foreground.png'),
                ),
                const SizedBox(height: 18),
                Text(
                  'ECHONEP',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how you want to translate in Nepal',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    color: palette.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                _RoleCard(
                  title: 'I am a Tourist',
                  subtitle: 'English to Nepali',
                  emoji: '🌏',
                  accentColor: const Color(0xFF0B6E99),
                  onTap: () =>
                      ref.read(roleProvider.notifier).setRole(UserRole.tourist),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  title: 'म व्यापारी हुँ',
                  subtitle: 'नेपाली to English',
                  emoji: '🏪',
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

class _RoleCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final Color accentColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AppCard(
          accent: widget.accentColor,
          radius: AppRadius.lg,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: widget.accentColor.withValues(alpha: 0.12),
                child: Text(widget.emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: widget.accentColor),
            ],
          ),
        ),
      ),
    );
  }
}
