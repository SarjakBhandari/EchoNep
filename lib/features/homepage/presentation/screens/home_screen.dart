import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:echo_nep/core/models/quick_phrase.dart';
import 'package:echo_nep/core/models/translation_result.dart';
import 'package:echo_nep/core/models/user_role.dart';
import 'package:echo_nep/core/providers/role_provider.dart';
import 'package:echo_nep/core/providers/translation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

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
    final sourceText = widget.role == UserRole.tourist
        ? phrase.english
        : phrase.nepali;
    _sourceController.text = sourceText;
    ref.read(translationProvider.notifier).clear();
  }

  Future<void> _translateText(String sourceText) async {
    if (_isBusy || sourceText.isEmpty) return;
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
                  : 'ASR failed: ${error.message ?? 'unknown error'}',
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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFCF5), Color(0xFFF5E8D8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                role: widget.role,
                accent: _accent,
                onReset: _isBusy
                    ? null
                    : () => ref.read(roleProvider.notifier).clearRole(),
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
                            ? 'Use the mic to fill the Nepali form. Translation stays locked until you press Translate.'
                            : 'Type or speak, then translate when you are ready.',
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
                      const SizedBox(height: 16),
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
                          color: Colors.red.shade700,
                        ),
                      if (translationState.result != null) ...[
                        const SizedBox(height: 16),
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
                    : 'Mic can be used for quick typing',
                onTap: _toggleRecording,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final UserRole role;
  final Color accent;
  final VoidCallback? onReset;

  const _TopBar({
    required this.role,
    required this.accent,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  role.icon, // IconData from your enum extension
                  size: 18,
                  color: accent,
                  semanticLabel: role.label,
                ),
                const SizedBox(width: 8),
                Text(
                  role.chipLabel,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onReset,
            icon: const Icon(Icons.swap_horiz_rounded),
            color: const Color(0xFF062A3A),
            tooltip: 'Reset role',
          ),
        ],
      ),
    );
  }
}

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
    final phrases = role == UserRole.tourist
        ? touristQuickPhrases
        : traderQuickPhrases;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          role == UserRole.tourist ? 'Quick phrases' : 'Seller shortcuts',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF062A3A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          role == UserRole.tourist
              ? 'Buyer-friendly phrases for fast translation.'
              : 'Seller-side phrases tailored for the trader desk.',
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: const Color(0xFF6B6B6B),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: phrases.map((phrase) {
            final label = role == UserRole.tourist
                ? phrase.english
                : phrase.nepali;

            return ActionChip(
              avatar: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.white,
                child: Icon(
                  phrase.icon, // IconData on QuickPhrase
                  size: 16,
                  color: accent,
                  semanticLabel: phrase.english,
                ),
              ),
              label: Text(
                label,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              backgroundColor: Colors.white,
              side: BorderSide(color: accent.withOpacity(0.18)),
              onPressed: enabled ? () => onPhraseTap(phrase) : null,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            );
          }).toList(),
        ),
      ],
    );
  }
}

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                role == UserRole.tourist ? 'Input desk' : 'Seller form',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF062A3A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            role == UserRole.trader
                ? 'Speak Nepali in Devanagari. The transcript stays here until you tap Translate.'
                : 'Type your text or use the mic, then translate when ready.',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: const Color(0xFF6B6B6B),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: role == UserRole.trader
                  ? 'उदाहरण: यो अन्तिम मूल्य हो'
                  : role.prompt,
              filled: true,
              fillColor: const Color(0xFFFFF7EF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: enabled
                  ? () => onTranslate(controller.text.trim())
                  : null,
              icon: const Icon(Icons.translate_rounded),
              label: Text(
                role == UserRole.trader ? 'Translate form' : 'Translate',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final Color color;

  const _StatusBanner({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(message, style: GoogleFonts.manrope(color: color)),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role.outputLabel,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5A5A5A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            result.translatedText,
            style: GoogleFonts.notoSansDevanagari(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF062A3A),
            ),
          ),
          if (result.romanizedText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              result.romanizedText,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF6B6B6B),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: result.audioB64.isEmpty
                      ? null
                      : () => onPlay(result.audioB64),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('Play'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Translate: ${result.latencyMs['translate'] ?? 0} ms · ASR: ${result.latencyMs['asr'] ?? 0} ms · TTS: ${result.latencyMs['tts'] ?? 0} ms',
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: const Color(0xFF6B6B6B),
            ),
          ),
        ],
      ),
    );
  }
}

class _MicBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              color: const Color(0xFF5A5A5A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: GoogleFonts.manrope(
              color: const Color(0xFF6B6B6B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: enabled ? onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: isRecording ? 86 : 74,
              height: isRecording ? 86 : 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: !enabled
                      ? [Colors.grey.shade500, Colors.grey.shade700]
                      : isRecording
                      ? [Colors.red.shade400, Colors.red.shade700]
                      : [accent, accent.withOpacity(0.72)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isRecording ? Colors.red : accent).withOpacity(
                      0.35,
                    ),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusyBanner extends StatelessWidget {
  final String message;
  final Color accent;

  const _BusyBanner({required this.message, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.manrope(
                color: const Color(0xFF062A3A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.95), accent.withOpacity(0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withOpacity(0.18),
            child: Icon(
              role.icon,
              size: 24,
              color: Colors.white,
              semanticLabel: role.label,
            ),
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
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 13,
                    height: 1.35,
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
