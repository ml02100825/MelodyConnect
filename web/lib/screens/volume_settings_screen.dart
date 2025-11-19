import 'package:flutter/material.dart';
import '../bottom_nav.dart';

class VolumeSettingsScreen extends StatefulWidget {
  const VolumeSettingsScreen({Key? key}) : super(key: key);

  @override
  State<VolumeSettingsScreen> createState() => _VolumeSettingsScreenState();
}

class _VolumeSettingsScreenState extends State<VolumeSettingsScreen> {
  // defaults
  static const double _defaultBgm = 0.5;
  static const double _defaultEffects = 0.5;
  static const double _defaultVoice = 0.5;

  bool _bgmOn = true;
  bool _effectsOn = true;
  bool _voiceOn = true;

  double _bgm = _defaultBgm;
  double _effects = _defaultEffects;
  double _voice = _defaultVoice;
  // 保存用（ミュート前の値を保持）
  double _prevBgm = _defaultBgm;
  double _prevEffects = _defaultEffects;
  double _prevVoice = _defaultVoice;

  void _resetDefaults() {
    setState(() {
      _bgmOn = true;
      _effectsOn = true;
      _voiceOn = true;
      _bgm = _defaultBgm;
      _effects = _defaultEffects;
      _voice = _defaultVoice;
    });
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
            ),
          ],
        ),
        Slider(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: Colors.grey[700],
          inactiveColor: Colors.grey[300],
        ),
        const SizedBox(height: 8),
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: 18),

              _buildRow(
                label: 'BGM音量',
                enabled: _bgmOn,
                onToggle: (v) => setState(() {
                  // ミュートにしたら現在値を保存して 0 にする
                  if (!v) {
                    _prevBgm = _bgm;
                    _bgm = 0.0;
                  } else {
                    // ミュート解除したら保存値を復元（保存値が 0 の場合はデフォルトを使う）
                    _bgm = _prevBgm > 0 ? _prevBgm : _defaultBgm;
                  }
                  _bgmOn = v;
                }),
                value: _bgm,
                onChanged: (v) => setState(() => _bgm = v),
              ),

              _buildRow(
                label: '効果音音量',
                enabled: _effectsOn,
                onToggle: (v) => setState(() {
                  if (!v) {
                    _prevEffects = _effects;
                    _effects = 0.0;
                  } else {
                    _effects = _prevEffects > 0 ? _prevEffects : _defaultEffects;
                  }
                  _effectsOn = v;
                }),
                value: _effects,
                onChanged: (v) => setState(() => _effects = v),
              ),

              _buildRow(
                label: '問題オン声音量',
                enabled: _voiceOn,
                onToggle: (v) => setState(() {
                  if (!v) {
                    _prevVoice = _voice;
                    _voice = 0.0;
                  } else {
                    _voice = _prevVoice > 0 ? _prevVoice : _defaultVoice;
                  }
                  _voiceOn = v;
                }),
                value: _voice,
                onChanged: (v) => setState(() => _voice = v),
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
      bottomNavigationBar: BottomNavBar(
        currentIndex: 4,
        onTap: (index) {},
      ),
    );
  }
}
