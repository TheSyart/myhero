import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  static bool _inited = false;
  static String? _currentBgm;

  static double bgmVolume = 0.8;
  static double sfxVolume = 1.0;

  /// 必须在游戏启动时调用
  static Future<void> init() async {
    if (_inited) return;
    try {
      await FlameAudio.audioCache.loadAll([
        'door_open.wav',
        'door_knock.wav',
        'whistle.wav',
        'sword_clash_2.wav',
        'fire_lighting.wav',
        'Goblins_Dance_(Battle).wav',
        'Goblins_Den_(Regular).wav',
        'Hurt.wav',
        'Laser_Gun.wav',
      ]);
      _inited = true;
    } catch (e) {
      debugPrint('AudioManager init error: $e');
    }
  }

  // ================== SFX ==================

  static Future<void> playSfx(String file, {double? volume}) async {
    if (!_inited) return;
    try {
      await FlameAudio.play(file, volume: volume ?? sfxVolume);
    } catch (e) {
      debugPrint('AudioManager playSfx error: $e');
    }
  }

  // ================== BGM ==================

  static Future<void> playBgm(String file, {double? volume}) async {
    if (!_inited) return;

    // 同一首就别动
    if (_currentBgm == file) return;

    try {
      await FlameAudio.bgm.stop();
      _currentBgm = file;

      await FlameAudio.bgm.play(file, volume: volume ?? bgmVolume);
    } catch (e) {
      debugPrint('AudioManager playBgm error: $e');
    }
  }

  static Future<void> stopBgm() async {
    try {
      _currentBgm = null;
      await FlameAudio.bgm.stop();
    } catch (e) {
      debugPrint('AudioManager stopBgm error: $e');
    }
  }

  static Future<void> pauseBgm() async {
    try {
      await FlameAudio.bgm.pause();
    } catch (e) {
      debugPrint('AudioManager pauseBgm error: $e');
    }
  }

  static Future<void> resumeBgm() async {
    try {
      await FlameAudio.bgm.resume();
    } catch (e) {
      debugPrint('AudioManager resumeBgm error: $e');
    }
  }

  // ================== 语义化封装 ==================

  static Future<void> playDoorOpen() => playSfx('door_open.wav');

  static Future<void> playSwordClash() => playSfx('sword_clash_2.wav');

  static Future<void> playFireLighting() => playSfx('fire_lighting.wav');

  static Future<void> startBattleBgm() => playBgm('Goblins_Dance_(Battle).wav');

  static Future<void> startRegularBgm() => playBgm('Goblins_Den_(Regular).wav');

  static Future<void> playDoorKnock() => playSfx('door_knock.wav');

  static Future<void> playWhistle() => playSfx('whistle.wav');

  static Future<void> playHurt() => playSfx('Hurt.wav');

  static Future<void> playLaserGun() => playSfx('Laser_Gun.wav');
}
