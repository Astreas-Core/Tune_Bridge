import 'package:flutter/material.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/neumorphic.dart';
import 'package:tune_bridge/core/services/audio_player_service.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  late final AudioPlayerService _audioService;
  bool _enabled = true;
  String _selectedPreset = 'Standard';
  bool _isLoading = true;

  // We operate in dB (-15 to 15 usually). API uses mB (-1500 to 1500).
  List<double> _bands = [0, 0, 0, 0, 0];
  List<String> _bandLabels = ['60Hz', '230Hz', '910Hz', '4kHz', '14kHz'];

  // Presets in dB
  final Map<String, List<double>> _presets = {
    'Standard': [0, 0, 0, 0, 0],
    'Bass Boost': [6, 4, 0, 0, -2],
    'Rock': [4, 3, -2, 3, 5],
    'Pop': [-2, 2, 4, 2, -1],
    'Vocal': [-4, -2, 4, 5, 3],
    'Custom': [0, 0, 0, 0, 0],
  };

  @override
  void initState() {
    super.initState();
    _audioService = getIt<AudioPlayerService>();
    _initEqualizer();
  }

  Future<void> _initEqualizer() async {
    try {
      final freqs = await _audioService.getCenterBandFreqs();
      if (freqs.isNotEmpty) {
        // Convert mHz to Hz/kHz
        _bandLabels = freqs.map((mHz) {
          final hz = mHz ~/ 1000;
          if (hz >= 1000) {
            return '${(hz / 1000).toStringAsFixed(1).replaceAll('.0', '')}kHz';
          }
          return '${hz}Hz';
        }).toList();

        // Get Current Levels (mB -> dB)
        final List<double> currentLevels = [];
        for (int i = 0; i < freqs.length; i++) {
          final levelMb = await _audioService.getBandLevel(i);
          currentLevels.add(levelMb / 100);
        }
        
        if (mounted) {
          setState(() {
            _bands = currentLevels;
            _isLoading = false;
            // Best guess preset
            if (_bands.every((v) => v == 0)) {
              _selectedPreset = 'Standard';
            } else {
              _selectedPreset = 'Custom';
            }
          });
        }
      } else {
         if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Equalizer init error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      if (preset != 'Custom') {
        final presetValues = _presets[preset]!;
        for (int i = 0; i < _bands.length; i++) {
          if (i < presetValues.length) {
            _bands[i] = presetValues[i];
            _audioService.setBandLevel(i, (_bands[i] * 100).round());
          }
        }
      }
    });
  }

  void _updateBand(int index, double value) {
    setState(() {
      _bands[index] = value;
      _selectedPreset = 'Custom';
    });
    _audioService.setBandLevel(index, (value * 100).round());
  }

  void _toggleEnabled(bool val) {
    setState(() => _enabled = val);
    _audioService.setEqualizerEnabled(val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Neumorphic.background,
      appBar: AppBar(
        backgroundColor: Neumorphic.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Neumorphic.iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'EQUALIZER',
          style: TextStyle(
            color: Neumorphic.textDark,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          Switch(
            value: _enabled,
            activeTrackColor: Neumorphic.accent.withValues(alpha: 0.5),
            activeThumbColor: Neumorphic.accent,
            onChanged: _isLoading ? null : _toggleEnabled,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: Neumorphic.accent))
        : Column(
        children: [
          const SizedBox(height: 20),
          
          // Preset Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Text('Preset:', style: TextStyle(color: Neumorphic.textMedium)),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: Neumorphic.inset(radius: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPreset,
                        isExpanded: true,
                        dropdownColor: Neumorphic.cardBg,
                        icon: Icon(Icons.arrow_drop_down_rounded, color: Neumorphic.accent),
                        style: TextStyle(
                          color: _enabled ? Neumorphic.textDark : Neumorphic.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                        items: _presets.keys.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: _enabled ? (val) {
                          if (val != null) _applyPreset(val);
                        } : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // EQ Sliders
          if (_bands.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Play music to enable Equalizer',
                  style: TextStyle(color: Neumorphic.textMedium),
                ),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(_bands.length, (index) {
                  return _BandSlider(
                    value: _bands[index],
                    label: _bandLabels.length > index ? _bandLabels[index] : '',
                    enabled: _enabled,
                    onChanged: (val) => _updateBand(index, val),
                  );
                }),
              ),
            ),

          const Spacer(),
        ],
      ),
    );
  }
}

class _BandSlider extends StatelessWidget {
  final double value;
  final String label;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _BandSlider({
    required this.value,
    required this.label,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${value > 0 ? '+' : ''}${value.toInt()}dB',
          style: TextStyle(
            color: enabled ? Neumorphic.textMedium : Neumorphic.textLight.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                activeTrackColor: enabled ? Neumorphic.accent : Neumorphic.textLight.withValues(alpha: 0.3),
                inactiveTrackColor: Neumorphic.insetBg,
                thumbColor: enabled ? Neumorphic.cardBg : Neumorphic.textLight,
                overlayColor: Neumorphic.accent.withValues(alpha: 0.1),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 4),
                trackShape: const RoundedRectSliderTrackShape(),
              ),
              child: Slider(
                value: value,
                min: -15,
                max: 15,
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: TextStyle(
            color: enabled ? Neumorphic.textDark : Neumorphic.textLight.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
