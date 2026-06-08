import 'package:tune_bridge/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/services/audio_player_service.dart';
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';

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
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: context.primaryColor),
              )
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: context.primaryColor,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Equalizer.',
                          style: GoogleFonts.inter(
                            color: context.textPrimaryColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 30,
                            letterSpacing: -0.8,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  GlassPanel(
                    blur: 0,
                    borderRadius: BorderRadius.circular(18),
                    color: context.surfaceColor,
                    borderColor: context.textPrimaryColor.withValues(alpha: 0.13),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enabled',
                                style: GoogleFonts.inter(
                                  color: context.textPrimaryColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                _enabled ? 'Sound tuning is active' : 'Sound tuning is off',
                                style: GoogleFonts.inter(
                                  color: context.textSecondaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _enabled,
                          activeThumbColor: context.primaryColor,
                          activeTrackColor: context.primaryColor.withValues(alpha: 0.35),
                          onChanged: _isLoading ? null : _toggleEnabled,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  GlassPanel(
                    blur: 0,
                    borderRadius: BorderRadius.circular(18),
                    color: context.surfaceColor,
                    borderColor: context.textPrimaryColor.withValues(alpha: 0.13),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.tune_rounded, color: context.primaryColor, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Preset',
                          style: GoogleFonts.inter(
                            color: context.textPrimaryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedPreset,
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(14),
                              dropdownColor: Color(0xFF141A23),
                              icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.textSecondaryColor),
                              style: GoogleFonts.inter(
                                color: _enabled ? context.textPrimaryColor : context.textSecondaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              items: _presets.keys
                                  .map(
                                    (value) => DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _enabled
                                  ? (value) {
                                      if (value != null) _applyPreset(value);
                                    }
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18),
                  if (_bands.isEmpty)
                    GlassPanel(
                      blur: 0,
                      borderRadius: BorderRadius.circular(18),
                      color: context.surfaceColor,
                      borderColor: context.textPrimaryColor.withValues(alpha: 0.13),
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        'Play music to enable equalizer bands.',
                        style: GoogleFonts.inter(
                          color: context.textSecondaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    GlassPanel(
                      blur: 0,
                      borderRadius: BorderRadius.circular(22),
                      color: context.surfaceColor,
                      borderColor: context.textPrimaryColor.withValues(alpha: 0.13),
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
                      child: SizedBox(
                        height: 310,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(_bands.length, (index) {
                            return _BandSlider(
                              value: _bands[index],
                              label: _bandLabels.length > index ? _bandLabels[index] : '',
                              enabled: _enabled,
                              onChanged: (value) => _updateBand(index, value),
                            );
                          }),
                        ),
                      ),
                    ),
                ],
              ),
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
    final sliderTheme = SliderTheme.of(context).copyWith(
      trackHeight: 5,
      activeTrackColor:
          enabled ? context.primaryColor : context.textSecondaryColor.withValues(alpha: 0.3),
      inactiveTrackColor: Color(0x33353535),
      thumbColor: enabled ? context.textPrimaryColor : context.textSecondaryColor,
      overlayColor: context.primaryColor.withValues(alpha: 0.12),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8, elevation: 2),
      trackShape: const RoundedRectSliderTrackShape(),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${value > 0 ? '+' : ''}${value.toInt()}dB',
          style: GoogleFonts.inter(
            color: enabled
                ? context.textPrimaryColor
                : context.textSecondaryColor.withValues(alpha: 0.55),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: sliderTheme,
              child: Slider(
                value: value,
                min: -15,
                max: 15,
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        Text(
          label,
          style: GoogleFonts.inter(
            color: enabled
                ? context.textPrimaryColor
                : context.textSecondaryColor.withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
