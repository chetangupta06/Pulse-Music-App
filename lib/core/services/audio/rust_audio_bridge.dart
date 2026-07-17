class RustAudioBridge {
  const RustAudioBridge();

  Map<String, double> profileForPreset(String preset) {
    return <String, double>{
      '32Hz': preset.contains('Bass') ? 3 : 1,
      '64Hz': preset.contains('Bass') ? 4 : 1.5,
      '125Hz': preset.contains('Warmth') ? 2.5 : 1,
      '250Hz': 1,
      '500Hz': 0.5,
      '1kHz': 0,
      '2kHz': 1,
      '4kHz': 2,
      '8kHz': 2.5,
      '16kHz': 1.5,
    };
  }

  double detectSilenceThreshold({required bool karaokeMode}) {
    return karaokeMode ? 0.12 : 0.08;
  }
}
