import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

/// Centralized service for haptic feedback and sound effects
/// Manages audio player pooling for overlapping sounds
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  // Audio player pool for overlapping sounds
  final List<AudioPlayer> _playerPool = [];
  final int _poolSize = 5;
  int _currentPlayerIndex = 0;

  // Preloaded audio sources map
  final Map<String, String> _audioSources = {};
  
  // Volume control
  double _volume = 1.0;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;

  /// Initialize the service and preload all audio files
  Future<void> initialize() async {
    // Initialize player pool
    for (int i = 0; i < _poolSize; i++) {
      _playerPool.add(AudioPlayer());
      
    }

    for (int i = 0; i < _poolSize; i++) {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop); // Don't auto-release
      _playerPool.add(player);
    }

    // Preload all audio files here
    // Add your audio files to assets/sounds/ and declare them in pubspec.yaml
    _audioSources['notification'] = 'sounds/notification.wav';
    _audioSources['notif-short'] = 'sounds/notif-short.wav';
    _audioSources['tap'] = 'sounds/tap.wav';

    
    // Preload all sources into cache
    for (final source in _audioSources.values) {
      try {
        await _playerPool[0].setSource(AssetSource(source));
      } catch (e) {
        print('Failed to preload audio: $source - $e');
      }
    }
  }

  /// Play a sound effect by key
  Future<void> playSound(String soundKey, {double volumeScale = 1.0}) async {
    if (!_soundEnabled) return;
    
    if (!_audioSources.containsKey(soundKey)) {
      print('Sound key not found: $soundKey');
      return;
    }

    try {
      // Get next player from pool (round-robin)
      final player = _playerPool[_currentPlayerIndex];
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _poolSize;
      await player.stop();
      // Set volume
      final volume = volumeScale * _volume;
      await player.setVolume(volume);

      // Play sound
      await player.play(AssetSource(_audioSources[soundKey]!));
      print("Played $soundKey");
    } catch (e) {
      print('Error playing sound $soundKey: $e');
    }
  }

  /// Trigger haptic feedback
  Future<void> haptic(HapticType type) async {
    if (!_hapticsEnabled) return;

    try {
      switch (type) {
        case HapticType.light:
          await HapticFeedback.lightImpact();
          break;
        case HapticType.medium:
          await HapticFeedback.mediumImpact();
          break;
        case HapticType.heavy:
          await HapticFeedback.heavyImpact();
          break;
        case HapticType.selection:
          await HapticFeedback.selectionClick();
          break;
        case HapticType.vibrate:
          await HapticFeedback.vibrate();
          break;
      }
    } catch (e) {
      print('Error triggering haptic: $e');
    }
  }

  /// Combined feedback - sound + haptic
  Future<void> feedback({
    String? sound,
    HapticType? haptic,
    double volume = 1.0,
  }) async {
    final futures = <Future>[];
    
    if (sound != null) {
      futures.add(playSound(sound, volumeScale: volume));
    }
    
    if (haptic != null) {
      futures.add(this.haptic(haptic));
    }

    await Future.wait(futures);
  }

  // === Quick access methods for common feedback patterns ===

  /// Light tap feedback (UI elements)
  Future<void> tap() => feedback(
    sound: 'tap',
    haptic: HapticType.light,
  );

  /// Button press feedback
  Future<void> buttonPress() => feedback(
    sound: 'button_press',
    haptic: HapticType.medium,
  );

  /// Success feedback
  Future<void> success() => feedback(
    sound: 'success',
    haptic: HapticType.medium,
  );

  /// Error feedback
  Future<void> error() => feedback(
    sound: 'error',
    haptic: HapticType.heavy,
  );

  /// Toggle feedback
  Future<void> toggle(bool isOn) => feedback(
    sound: isOn ? 'toggle_on' : 'toggle_off',
    haptic: HapticType.light,
  );

  /// Swipe/scroll feedback
  Future<void> swipe() => feedback(
    sound: 'swipe',
    haptic: HapticType.selection,
  );

  /// Pop/appear feedback
  Future<void> pop() => feedback(
    sound: 'pop',
    haptic: HapticType.light,
  );

  /// Notification feedback
  Future<void> notification() => feedback(
    sound: 'notification',
    haptic: HapticType.medium,
  );

  // === Settings ===

  /// Set master volume (0.0 to 1.0)
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  /// Enable/disable sounds
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  /// Enable/disable haptics
  void setHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
  }

  /// Get current volume
  double get volume => _volume;

  /// Check if sound is enabled
  bool get soundEnabled => _soundEnabled;

  /// Check if haptics is enabled
  bool get hapticsEnabled => _hapticsEnabled;

  /// Add a new sound to the library at runtime
  void registerSound(String key, String assetPath) {
    _audioSources[key] = assetPath;
  }

  /// Cleanup resources
  Future<void> dispose() async {
    for (final player in _playerPool) {
      await player.dispose();
    }
    _playerPool.clear();
  }
}

/// Haptic feedback types
enum HapticType {
  light,      // Light tap
  medium,     // Medium impact
  heavy,      // Heavy impact
  selection,  // Selection click
  vibrate,    // Generic vibration
}