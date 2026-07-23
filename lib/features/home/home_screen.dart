import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../core/models/quick_phrase.dart';
import '../../core/models/translation_result.dart';
import '../../core/models/user_role.dart';
import '../../core/providers/role_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/translation_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/api_error.dart';
import '../../core/widgets/app_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final UserRole role;

  const HomeScreen({super.key, required this.role});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _sourceController = TextEditingController();
  String? _recordingPath;
  bool _isRecording = false;
  bool _isBusy = false;

  Color get _accent => widget.role == UserRole.tourist
      ? const Color(0xFF0B6E99)
      : const Color(0xFF7E3F28);

  bool get _isTrader => widget.role == UserRole.trader;

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _pickPhrase(QuickPhrase phrase) async {
    if (_isBusy) return;
    HapticFeedback.selectionClick();
    final sourceText = widget.role == UserRole.tourist
        ? phrase.english
        : phrase.nepali;
    _sourceController.text = sourceText;
    ref.read(translationProvider.notifier).clear();
  }

  Future<void> _translateText(String sourceText) async {
    if (_isBusy || sourceText.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isBusy = true;
    });
    try {
      await ref
          .read(translationProvider.notifier)
          .translateText(text: sourceText, direction: widget.role.direction);
      final result = ref.read(translationProvider).result;
      if (result != null) {
        _sourceController.text = result.sourceText;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_isBusy) return;
    if (_isRecording) {
      HapticFeedback.mediumImpact();
      await _stopRecordingAndTranslate();
      return;
    }

    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      ref
          .read(translationProvider.notifier)
          .setError('Microphone permission is required.');
      return;
    }

    final tempDirectory = await getTemporaryDirectory();
    _recordingPath = '${tempDirectory.path}/himalaya_recording.wav';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000),
      path: _recordingPath!,
    );

    HapticFeedback.mediumImpact();
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecordingAndTranslate() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
    });
    try {
      final path = await _recorder.stop();
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
      }

      final audioPath = path ?? _recordingPath;
      if (audioPath == null) {
        return;
      }

      final audioBase64 = base64Encode(await File(audioPath).readAsBytes());
      final transcript = await ref
          .read(transcribeAudioUseCaseProvider)
          .call(
            audioBase64: audioBase64,
            direction: widget.role.direction,
            userType: widget.role.name,
          );
      _sourceController.text = transcript;
      _sourceController.selection = TextSelection.fromPosition(
        TextPosition(offset: transcript.length),
      );
      ref.read(translationProvider.notifier).clear();
    } on DioException catch (error) {
      if (mounted) {
        ref
            .read(translationProvider.notifier)
            .setError(
              error.type == DioExceptionType.receiveTimeout
                  ? 'ASR is taking too long. Please record a shorter phrase or try again.'
                  : describeDioError(error),
            );
      }
    } catch (error) {
      if (mounted) {
        ref.read(translationProvider.notifier).setError('ASR failed: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _playAudio(String audioB64) async {
    HapticFeedback.lightImpact();
    final audioBytes = base64Decode(audioB64);
    final tempDirectory = await getTemporaryDirectory();
    final isWav =
        audioBytes.length >= 12 &&
        String.fromCharCodes(audioBytes.sublist(0, 4)) == 'RIFF';
    final extension = isWav ? 'wav' : 'mp3';
    final outputPath = '${tempDirectory.path}/tts_output.$extension';
    final file = File(outputPath);
    await file.writeAsBytes(audioBytes, flush: true);
    await _player.stop();
    await _player.play(DeviceFileSource(file.path));
  }

  @override
  Widget build(BuildContext context) {
    final translationState = ref.watch(translationProvider);
    final themeMode = ref.watch(themeModeProvider);
    final palette = context.palette;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.gradientStart, palette.gradientMid],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                role: widget.role,
                accent: _accent,
                themeMode: themeMode,
                onReset: _isBusy
                    ? null
                    : () => ref.read(roleProvider.notifier).clearRole(),
                onToggleTheme: () =>
                    ref.read(themeModeProvider.notifier).cycleThemeMode(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _WorkspaceHeader(
                        role: widget.role,
                        accent: _accent,
                        title: _isTrader
                            ? 'Trader workspace'
                            : 'Tourist workspace',
                        subtitle: _isTrader
                            ? 'Speak Nepali to fill the form, then tap Translate.'
                            : 'Type or speak, then translate when ready.',
                      ),
                      const SizedBox(height: 16),
                      _QuickPhraseStrip(
                        role: widget.role,
                        accent: _accent,
                        enabled: !_isBusy,
                        onPhraseTap: _pickPhrase,
                      ),
                      const SizedBox(height: 16),
                      _ComposerCard(
                        accent: _accent,
                        controller: _sourceController,
                        role: widget.role,
                        enabled: !_isBusy,
                        onTranslate: _translateText,
                      ),
                      const SizedBox(height: 12),
                      if (translationState.isLoading || _isBusy)
                        _BusyBanner(
                          message: _isRecording
                              ? 'Listening and transcribing...'
                              : 'Contacting server...',
                          accent: _accent,
                        ),
                      if (translationState.error != null)
                        _StatusBanner(
                          message: translationState.error!,
                          color: palette.errorColor,
                        ),
                      if (translationState.result != null) ...[
                        const SizedBox(height: 8),
                        _ResultCard(
                          accent: _accent,
                          role: widget.role,
                          result: translationState.result!,
                          onPlay: _playAudio,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _MicBar(
                accent: _accent,
                isRecording: _isRecording,
                enabled: !_isBusy,
                label: widget.role.prompt,
                hint: _isTrader
                    ? 'Mic fills the form only'
                    : 'Mic for quick text input',
                onTap: _toggleRecording,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

IconData _themeModeIcon(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => Icons.brightness_auto_rounded,
    ThemeMode.light => Icons.light_mode_rounded,
    ThemeMode.dark => Icons.dark_mode_rounded,
  };
}

String _themeModeTooltip(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => 'Theme: system',
    ThemeMode.light => 'Theme: light',
    ThemeMode.dark => 'Theme: dark',
  };
}

class _TopBar extends StatelessWidget {
  final ThemeMode themeMode;
  final VoidCallback? onReset;
  final VoidCallback onToggleTheme;
  final UserRole role;
  final Color accent;

  const _TopBar({
    required this.role,
    required this.accent,
    required this.themeMode,
    required this.onReset,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(role.icon, size: 16, color: accent, semanticLabel: role.label),
                const SizedBox(width: 6),
                Text(
                  role.chipLabel,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onToggleTheme,
            icon: Icon(_themeModeIcon(themeMode), size: 20),
            color: palette.textSecondary,
            tooltip: _themeModeTooltip(themeMode),
          ),
          IconButton(
            onPressed: onReset,
            icon: const Icon(Icons.swap_horiz_rounded, size: 20),
            color: palette.textSecondary,
            tooltip: 'Switch role',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Workspace header
// ---------------------------------------------------------------------------

class _WorkspaceHeader extends StatelessWidget {
  final UserRole role;
  final Color accent;
  final String title;
  final String subtitle;

  const _WorkspaceHeader({
    required this.role,
    required this.accent,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final directionLabel = role == UserRole.tourist ? 'EN > NE' : 'NE > EN';
    return AppCard(
      accent: accent,
      showBorder: false,
      shadowOpacity: 0.22,
      gradient: LinearGradient(
        colors: [
          accent.withValues(alpha: 0.95),
          accent.withValues(alpha: 0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Icon(role.icon, size: 22, color: Colors.white, semanticLabel: role.label),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Text(
              directionLabel,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick phrase strip (horizontal scroll)
// ---------------------------------------------------------------------------

class _QuickPhraseStrip extends StatelessWidget {
  final UserRole role;
  final Color accent;
  final bool enabled;
  final Future<void> Function(QuickPhrase phrase) onPhraseTap;

  const _QuickPhraseStrip({
    required this.role,
    required this.accent,
    required this.enabled,
    required this.onPhraseTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final phrases = role == UserRole.tourist ? touristQuickPhrases : traderQuickPhrases;
    final sectionLabel = role == UserRole.tourist ? 'Quick phrases' : 'Seller shortcuts';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              sectionLabel,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${phrases.length}',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: phrases.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final phrase = phrases[index];
              final label = role == UserRole.tourist ? phrase.english : phrase.nepali;
              return GestureDetector(
                onTap: enabled ? () => onPhraseTap(phrase) : null,
                child: AnimatedOpacity(
                  opacity: enabled ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: palette.surfaceCard,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: accent.withValues(alpha: 0.18)),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(phrase.icon, size: 14, color: accent),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: palette.textPrimary,
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
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Composer card
// ---------------------------------------------------------------------------

class _ComposerCard extends StatelessWidget {
  final Color accent;
  final TextEditingController controller;
  final UserRole role;
  final bool enabled;
  final Future<void> Function(String text) onTranslate;

  const _ComposerCard({
    required this.accent,
    required this.controller,
    required this.role,
    required this.enabled,
    required this.onTranslate,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final directionLabel = role == UserRole.tourist ? 'EN  >  NE' : 'NE  >  EN';

    return AppCard(
      accent: accent,
      borderOpacity: 0.14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                role == UserRole.tourist ? 'Input desk' : 'Seller form',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: palette.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  directionLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            role == UserRole.trader
                ? 'Speak Nepali in Devanagari. Transcript stays here until you translate.'
                : 'Type your text or use the mic below, then translate when ready.',
            style: GoogleFonts.manrope(fontSize: 12, color: palette.textSecondary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            style: GoogleFonts.manrope(color: palette.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: role == UserRole.trader
                  ? 'उदाहरण: यो अन्तिम मूल्य हो'
                  : role.prompt,
              hintStyle: GoogleFonts.manrope(
                color: palette.textSecondary.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              filled: true,
              fillColor: palette.surfaceCardAlt,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: enabled ? () => onTranslate(controller.text.trim()) : null,
              icon: const Icon(Icons.translate_rounded, size: 18),
              label: Text(
                role == UserRole.trader ? 'Translate form' : 'Translate',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: accent.withValues(alpha: 0.38),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status / error banner
// ---------------------------------------------------------------------------

class _StatusBanner extends StatelessWidget {
  final String message;
  final Color color;

  const _StatusBanner({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      accent: color,
      fillColor: color.withValues(alpha: 0.08),
      borderOpacity: 0.2,
      radius: AppRadius.md,
      withShadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.manrope(color: color, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Busy / loading banner
// ---------------------------------------------------------------------------

class _BusyBanner extends StatelessWidget {
  final String message;
  final Color accent;

  const _BusyBanner({required this.message, required this.accent});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      accent: accent,
      fillColor: accent.withValues(alpha: 0.07),
      borderOpacity: 0.14,
      radius: AppRadius.md,
      withShadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.manrope(
                color: context.palette.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result card
// ---------------------------------------------------------------------------

class _LatencyChip extends StatelessWidget {
  final String label;
  final dynamic ms;
  final Color accent;

  const _LatencyChip({required this.label, required this.ms, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (ms == null || (ms is num && ms == 0)) return const SizedBox.shrink();
    final msValue = ms is num ? ms.toStringAsFixed(0) : '$ms';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label ${msValue}ms',
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: accent.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Color accent;
  final UserRole role;
  final TranslationResult result;
  final Future<void> Function(String audioB64) onPlay;

  const _ResultCard({
    required this.accent,
    required this.role,
    required this.result,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, (1 - value) * 20), child: child),
        );
      },
      child: AppCard(
        accent: accent,
        fillColor: accent.withValues(alpha: 0.06),
        withShadow: false,
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 16, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    'Translation result',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    role == UserRole.tourist ? 'EN > NE' : 'NE > EN',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: accent.withValues(alpha: 0.7),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),

            // Source text
            if (result.sourceText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: palette.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.sourceText,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        color: palette.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

            // Divider with direction arrow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Divider(color: accent.withValues(alpha: 0.15), height: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      size: 14,
                      color: accent.withValues(alpha: 0.5),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: accent.withValues(alpha: 0.15), height: 1),
                  ),
                ],
              ),
            ),

            // Translated text
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.outputLabel,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: palette.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    result.translatedText,
                    style: GoogleFonts.notoSansDevanagari(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  if (result.romanizedText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      result.romanizedText,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: palette.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Play button + latency chips
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Row(
                children: [
                  if (result.audioB64.isNotEmpty)
                    FilledButton.icon(
                      onPressed: () => onPlay(result.audioB64),
                      icon: const Icon(Icons.volume_up_rounded, size: 16),
                      label: Text(
                        'Play',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        _LatencyChip(label: 'ASR', ms: result.latencyMs['asr'], accent: accent),
                        _LatencyChip(label: 'NMT', ms: result.latencyMs['translate'], accent: accent),
                        _LatencyChip(label: 'TTS', ms: result.latencyMs['tts'], accent: accent),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mic bar (bottom)
// ---------------------------------------------------------------------------

class _MicBar extends StatefulWidget {
  final Color accent;
  final bool isRecording;
  final bool enabled;
  final String label;
  final String hint;
  final VoidCallback onTap;

  const _MicBar({
    required this.accent,
    required this.isRecording,
    required this.enabled,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  @override
  State<_MicBar> createState() => _MicBarState();
}

class _MicBarState extends State<_MicBar> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: palette.surfaceCard.withValues(alpha: 0.6),
        border: Border(
          top: BorderSide(color: widget.accent.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              widget.isRecording ? 'Recording  -  tap to stop' : widget.label,
              key: ValueKey(widget.isRecording),
              style: GoogleFonts.manrope(
                color: widget.isRecording ? Colors.red.shade400 : palette.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.hint,
            style: GoogleFonts.manrope(color: palette.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: widget.enabled ? widget.onTap : null,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.isRecording)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final t = _pulseController.value;
                        return Opacity(
                          opacity: (1 - t) * 0.4,
                          child: Transform.scale(
                            scale: 1.0 + t * 0.65,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: widget.isRecording ? 82 : 70,
                    height: widget.isRecording ? 82 : 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: !widget.enabled
                            ? [Colors.grey.shade400, Colors.grey.shade600]
                            : widget.isRecording
                            ? [Colors.red.shade400, Colors.red.shade700]
                            : [widget.accent, widget.accent.withValues(alpha: 0.75)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isRecording ? Colors.red : widget.accent)
                              .withValues(alpha: widget.enabled ? 0.38 : 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
