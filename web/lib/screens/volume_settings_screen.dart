import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class VolumeSettingsScreen extends StatefulWidget {
  const VolumeSettingsScreen({Key? key}) : super(key: key);

  @override
  State<VolumeSettingsScreen> createState() => _VolumeSettingsScreenState();
}

class _VolumeSettingsScreenState extends State<VolumeSettingsScreen> {
  final AudioService _audioService = AudioService();
  
  bool _isLoading = true;
  bool _bgmOn = true;
  bool _effectsOn = true;
  bool _voiceOn = true;
  
  double _bgm = 0.5;
  double _effects = 0.5;
  double _voice = 0.5;
  
  // ミュート前の値を保持
  double _prevBgm = 0.5;
  double _prevEffects = 0.5;
  double _prevVoice = 0.5;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 設定を読み込む
  Future<void> _loadSettings() async {
    final settings = await _audioService.getAllSettings();
    
    setState(() {
      _bgmOn = settings['bgmEnabled'] ?? true;
      _effectsOn = settings['effectsEnabled'] ?? true;
      _voiceOn = settings['voiceEnabled'] ?? true;
      
      _bgm = settings['bgmVolume'] ?? 0.5;
      _effects = settings['effectsVolume'] ?? 0.5;
      _voice = settings['voiceVolume'] ?? 0.5;
      
      _prevBgm = _bgm;
      _prevEffects = _effects;
      _prevVoice = _voice;
      
      _isLoading = false;
    });
  }

  /// BGMの有効/無効を切り替え
  Future<void> _toggleBgm(bool enabled) async {
    if (!enabled) {
      _prevBgm = _bgm;
      setState(() {
        _bgmOn = false;
        _bgm = 0.0;
      });
      await _audioService.setBgmVolume(0.0);
    } else {
      final restoredVolume = _prevBgm > 0 ? _prevBgm : 0.5;
      setState(() {
        _bgmOn = true;
        _bgm = restoredVolume;
      });
      await _audioService.setBgmVolume(restoredVolume);
    }
    await _audioService.setBgmEnabled(enabled);
  }

  /// 効果音の有効/無効を切り替え
  Future<void> _toggleEffects(bool enabled) async {
    if (!enabled) {
      _prevEffects = _effects;
      setState(() {
        _effectsOn = false;
        _effects = 0.0;
      });
      await _audioService.setEffectsVolume(0.0);
    } else {
      final restoredVolume = _prevEffects > 0 ? _prevEffects : 0.5;
      setState(() {
        _effectsOn = true;
        _effects = restoredVolume;
      });
      await _audioService.setEffectsVolume(restoredVolume);
    }
    await _audioService.setEffectsEnabled(enabled);
  }

  /// 音声の有効/無効を切り替え
  Future<void> _toggleVoice(bool enabled) async {
    if (!enabled) {
      _prevVoice = _voice;
      setState(() {
        _voiceOn = false;
        _voice = 0.0;
      });
      await _audioService.setVoiceVolume(0.0);
    } else {
      final restoredVolume = _prevVoice > 0 ? _prevVoice : 0.5;
      setState(() {
        _voiceOn = true;
        _voice = restoredVolume;
      });
      await _audioService.setVoiceVolume(restoredVolume);
    }
    await _audioService.setVoiceEnabled(enabled);
  }

  /// BGM音量を変更
  Future<void> _updateBgmVolume(double volume) async {
    setState(() {
      _bgm = volume;
    });
    await _audioService.setBgmVolume(volume);
  }

  /// 効果音音量を変更
  Future<void> _updateEffectsVolume(double volume) async {
    setState(() {
      _effects = volume;
    });
    await _audioService.setEffectsVolume(volume);
  }

  /// 音声音量を変更
  Future<void> _updateVoiceVolume(double volume) async {
    setState(() {
      _voice = volume;
    });
    await _audioService.setVoiceVolume(volume);
  }

  /// デフォルト値にリセット
  Future<void> _resetDefaults() async {
    await _audioService.resetToDefaults();
    await _loadSettings();
    
    // 成功メッセージを表示（必要に応じて）
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('音量設定を初期値に戻しました'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildRow({required String label, required bool enabled, required ValueChanged<bool> onToggle, required double value, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Switch(
              value: enabled,
              onChanged: onToggle,
              activeColor: Colors.blue,
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          onChanged: enabled ? onChanged : null,
          activeColor: Colors.blue,
          inactiveColor: Colors.grey[300],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '100%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('音量調整', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 18),

                    _buildRow(
                      label: 'BGM音量',
                      enabled: _bgmOn,
                      onToggle: _toggleBgm,
                      value: _bgm,
                      onChanged: _updateBgmVolume,
                    ),

                    _buildRow(
                      label: '効果音音量',
                      enabled: _effectsOn,
                      onToggle: _toggleEffects,
                      value: _effects,
                      onChanged: _updateEffectsVolume,
                    ),

                    _buildRow(
                      label: '問題オン声音量',
                      enabled: _voiceOn,
                      onToggle: _toggleVoice,
                      value: _voice,
                      onChanged: _updateVoiceVolume,
                    ),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _resetDefaults,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 4,
                        ),
                        child: const Text('初期値に戻す', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
    );
  }
}