class TranslationResult {
  final String sourceText;
  final String translatedText;
  final String romanizedText;
  final String audioB64;
  final Map<String, dynamic> latencyMs;
  final Map<String, dynamic> backend;

  const TranslationResult({
    required this.sourceText,
    required this.translatedText,
    required this.romanizedText,
    required this.audioB64,
    required this.latencyMs,
    required this.backend,
  });

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      sourceText: json['source_text'] as String? ?? '',
      translatedText: json['translated_text'] as String? ?? '',
      romanizedText: json['romanized_text'] as String? ?? '',
      audioB64: json['audio_b64'] as String? ?? '',
      latencyMs: Map<String, dynamic>.from(json['latency_ms'] as Map? ?? {}),
      backend: Map<String, dynamic>.from(json['backend'] as Map? ?? {}),
    );
  }
}
