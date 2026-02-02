import 'package:shared_preferences/shared_preferences.dart';

/// 音量設定を管理するサービス
class AudioService {
  static const String _bgmVolumeKey = 'bgm_volume';
  static const String _effectsVolumeKey = 'effects_volume';
  static const String _voiceVolumeKey = 'voice_volume';
  static const String _bgmEnabledKey = 'bgm_enabled';
  static const String _effectsEnabledKey = 'effects_enabled';
  static const String _voiceEnabledKey = 'voice_enabled';

  // デフォルト値
  static const double _defaultBgmVolume = 0.5;
  static const double _defaultEffectsVolume = 0.5;
  static const double _defaultVoiceVolume = 0.5;
  static const bool _defaultBgmEnabled = true;
  static const bool _defaultEffectsEnabled = true;
  static const bool _defaultVoiceEnabled = true;

  /// BGM音量を取得
  Future<double> getBgmVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_bgmVolumeKey) ?? _defaultBgmVolume;
  }

  /// BGM音量を設定
  Future<void> setBgmVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_bgmVolumeKey, volume);
  }

  /// 効果音音量を取得
  Future<double> getEffectsVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_effectsVolumeKey) ?? _defaultEffectsVolume;
  }

  /// 効果音音量を設定
  Future<void> setEffectsVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_effectsVolumeKey, volume);
  }

  /// 音声音量を取得
  Future<double> getVoiceVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_voiceVolumeKey) ?? _defaultVoiceVolume;
  }

  /// 音声音量を設定
  Future<void> setVoiceVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_voiceVolumeKey, volume);
  }

  /// BGMが有効かどうかを取得
  Future<bool> isBgmEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bgmEnabledKey) ?? _defaultBgmEnabled;
  }

  /// BGMの有効/無効を設定
  Future<void> setBgmEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bgmEnabledKey, enabled);
  }

  /// 効果音が有効かどうかを取得
  Future<bool> isEffectsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_effectsEnabledKey) ?? _defaultEffectsEnabled;
  }

  /// 効果音の有効/無効を設定
  Future<void> setEffectsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_effectsEnabledKey, enabled);
  }

  /// 音声が有効かどうかを取得
  Future<bool> isVoiceEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_voiceEnabledKey) ?? _defaultVoiceEnabled;
  }

  /// 音声の有効/無効を設定
  Future<void> setVoiceEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceEnabledKey, enabled);
  }

  /// すべての設定をデフォルト値にリセット
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setDouble(_bgmVolumeKey, _defaultBgmVolume),
      prefs.setDouble(_effectsVolumeKey, _defaultEffectsVolume),
      prefs.setDouble(_voiceVolumeKey, _defaultVoiceVolume),
      prefs.setBool(_bgmEnabledKey, _defaultBgmEnabled),
      prefs.setBool(_effectsEnabledKey, _defaultEffectsEnabled),
      prefs.setBool(_voiceEnabledKey, _defaultVoiceEnabled),
    ]);
  }

  /// すべての音量設定を取得
  Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'bgmVolume': await getBgmVolume(),
      'effectsVolume': await getEffectsVolume(),
      'voiceVolume': await getVoiceVolume(),
      'bgmEnabled': await isBgmEnabled(),
      'effectsEnabled': await isEffectsEnabled(),
      'voiceEnabled': await isVoiceEnabled(),
    };
  }
}