import 'dart:math';

import 'package:flutter/material.dart';

import '../core/calls.dart';
import '../services/fx.dart';
import '../services/settings.dart';
import 'controls.dart';
import 'look.dart';

const _presets = {8000: 'Relaxed', 5500: 'Normal', 3500: 'Quick'};

/// Speed presets plus a slider for any time between calls.
class SpeedControl extends StatelessWidget {
  const SpeedControl({super.key, required this.value, required this.onChanged, this.allowManual = true});
  final int value;
  final ValueChanged<int> onChanged;
  final bool allowManual;

  @override
  Widget build(BuildContext context) {
    final options = {..._presets, if (allowManual) Speed.manual: "I'll tap"};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Segments<int>(options: options, value: value, onChanged: onChanged),
        if (value != Speed.manual)
          _SliderRow(
            label: 'Seconds between numbers',
            value: value.toDouble(),
            min: Speed.min.toDouble(),
            max: Speed.max.toDouble(),
            divisions: (Speed.max - Speed.min) ~/ Speed.step,
            readout: '${(value / 1000).toStringAsFixed(1)} s',
            onChanged: (v) => onChanged(v.round()),
          ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.readout,
    required this.onChanged,
    this.divisions,
  });
  final String label;
  final double value, min, max;
  final int? divisions;
  final String readout;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: readout,
            semanticFormatterCallback: (_) => '$label: $readout',
            activeColor: Palette.ticketRed,
            inactiveColor: Palette.ink.withValues(alpha: .25),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 64,
          child: Text(
            readout,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Palette.ink),
          ),
        ),
      ],
    );
  }
}

/// The caller's voice: on/off, which voice, what it says, speed, pitch, repeat and a test.
class VoiceSettingsPanel extends StatefulWidget {
  const VoiceSettingsPanel({super.key, required this.settings, required this.fx});
  final Settings settings;
  final Fx fx;

  @override
  State<VoiceSettingsPanel> createState() => _VoiceSettingsPanelState();
}

class _VoiceSettingsPanelState extends State<VoiceSettingsPanel> {
  List<VoiceOption> _voices = const [];

  VoiceSettings get _v => widget.settings.voice;

  @override
  void initState() {
    super.initState();
    widget.fx.voices().then((v) {
      if (mounted) setState(() => _voices = v);
    });
  }

  void _change(VoidCallback update, {bool reapply = false}) {
    setState(update);
    widget.settings.save();
    if (reapply) widget.fx.applyVoice();
  }

  @override
  Widget build(BuildContext context) {
    final chosen = _voices.where((o) => o.name == _v.voiceName && o.locale == _v.voiceLocale).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: CheckToggle(label: "Caller's voice", value: _v.on, onChanged: (on) => _change(() => _v.on = on)),
        ),
        const SizedBox(height: 8),
        if (_voices.isNotEmpty) ...[
          const FieldLabel('Voice'),
          DropdownButtonFormField<VoiceOption?>(
            initialValue: chosen,
            isExpanded: true,
            dropdownColor: Palette.paper,
            style: const TextStyle(color: Palette.ink, fontSize: 15),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white.withValues(alpha: .6),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Palette.ink, width: 2)),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Automatic (Indian or British English)')),
              for (final o in _voices)
                DropdownMenuItem(
                  value: o,
                  child: Text(o.label, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (o) => _change(() {
              _v.voiceName = o?.name;
              _v.voiceLocale = o?.locale;
            }, reapply: true),
          ),
          const SizedBox(height: 12),
        ],
        const FieldLabel('What the caller says'),
        Segments<CallStyle>(
          options: {for (final s in CallStyle.values) s: s.label},
          value: _v.style,
          onChanged: (s) => _change(() => _v.style = s),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Says ${_v.style.example}',
            style: TextStyle(fontSize: 13, color: Palette.ink.withValues(alpha: .75)),
          ),
        ),
        const SizedBox(height: 12),
        const FieldLabel('Speaking speed'),
        _SliderRow(
          label: 'Speaking speed',
          value: _v.rate,
          min: VoiceSettings.minRate,
          max: VoiceSettings.maxRate,
          divisions: 18,
          readout: '${_v.rate.toStringAsFixed(2)}×',
          onChanged: (r) => _change(() => _v.rate = r, reapply: true),
        ),
        const FieldLabel('Voice pitch'),
        _SliderRow(
          label: 'Voice pitch',
          value: _v.pitch,
          min: VoiceSettings.minPitch,
          max: VoiceSettings.maxPitch,
          divisions: 20,
          readout: _v.pitch < .95
              ? 'Deeper'
              : _v.pitch > 1.05
              ? 'Higher'
              : 'Normal',
          onChanged: (p) => _change(() => _v.pitch = p, reapply: true),
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            CheckToggle(
              label: 'Say each number twice',
              value: _v.repeat,
              onChanged: (r) => _change(() => _v.repeat = r),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Palette.ink, foregroundColor: Palette.paper),
              onPressed: () => widget.fx.say(_v.speechFor(Random().nextInt(90) + 1), force: true),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Test voice'),
            ),
          ],
        ),
      ],
    );
  }
}

/// A bottom sheet with the caller's speed and voice, usable mid-game.
Future<void> showCallerSettings(
  BuildContext context, {
  required Settings settings,
  required Fx fx,
  required int Function() speed,
  required ValueChanged<int> onSpeed,
  bool allowManual = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.paper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('The caller', textAlign: TextAlign.center, style: cardTitle),
                const SizedBox(height: 14),
                const FieldLabel('Calling speed'),
                SpeedControl(value: speed(), allowManual: allowManual, onChanged: (ms) => setState(() => onSpeed(ms))),
                const SizedBox(height: 14),
                VoiceSettingsPanel(settings: settings, fx: fx),
                const SizedBox(height: 14),
                BigButton(label: 'Done', onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
