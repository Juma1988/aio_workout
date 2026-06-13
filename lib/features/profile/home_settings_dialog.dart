import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';

/// Home visibility section identifiers.
enum HomeSection {
  steps,
  achievements,
  hydration,
  weightTrend,
  thisWeek;

  String get prefKey => 'home_show_$name';
  String get label {
    switch (this) {
      case HomeSection.steps:
        return 'Steps';
      case HomeSection.achievements:
        return 'Achievements';
      case HomeSection.hydration:
        return 'Hydration';
      case HomeSection.weightTrend:
        return 'Weight Trend';
      case HomeSection.thisWeek:
        return 'This Week';
    }
  }

  IconData get icon {
    switch (this) {
      case HomeSection.steps:
        return Icons.directions_walk_rounded;
      case HomeSection.achievements:
        return Icons.emoji_events_rounded;
      case HomeSection.hydration:
        return Icons.water_drop_rounded;
      case HomeSection.weightTrend:
        return Icons.monitor_weight_rounded;
      case HomeSection.thisWeek:
        return Icons.bar_chart_rounded;
    }
  }

  Color get color {
    switch (this) {
      case HomeSection.steps:
        return AppTheme.stepsOrange;
      case HomeSection.achievements:
        return AppTheme.achievementGreen;
      case HomeSection.hydration:
        return AppTheme.hydrationBlue;
      case HomeSection.weightTrend:
        return AppTheme.weightPurple;
      case HomeSection.thisWeek:
        return const Color(0xFF6366F1);
    }
  }
}

/// Loads the visibility for all home sections from SharedPreferences.
/// Returns `true` for each section by default.
Future<Map<HomeSection, bool>> loadHomeSectionVisibility() async {
  final prefs = await SharedPreferences.getInstance();
  return {
    for (final section in HomeSection.values)
      section: prefs.getBool(section.prefKey) ?? true,
  };
}

/// Saves the visibility for a single home section.
Future<void> saveHomeSectionVisibility(HomeSection section, bool visible) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(section.prefKey, visible);
}

// ── Steps per click persistence ──

const _stepsPerClickKey = 'steps_per_click';
const _hydrationMLPerClickKey = 'hydration_ml_per_click';

Future<int> loadStepsPerClick() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_stepsPerClickKey) ?? 200;
}

Future<void> saveStepsPerClick(int value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_stepsPerClickKey, value);
}

Future<int> loadHydrationMLPerClick() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_hydrationMLPerClickKey) ?? 250;
}

Future<void> saveHydrationMLPerClick(int value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_hydrationMLPerClickKey, value);
}

/// A bottom-sheet dialog that lets the user show/hide sections on the home screen.
///
/// Opens from the Profile → Preferences → Home Setting tile.
void showHomeSettingsDialog(
  BuildContext context, {
  VoidCallback? onSettingsChanged,
}) {
  HapticFeedback.lightImpact();

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _HomeSettingsSheet(onSettingsChanged: onSettingsChanged),
  );
}

class _HomeSettingsSheet extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const _HomeSettingsSheet({this.onSettingsChanged});

  @override
  State<_HomeSettingsSheet> createState() => _HomeSettingsSheetState();
}

class _HomeSettingsSheetState extends State<_HomeSettingsSheet> {
  Map<HomeSection, bool> _visibility = {};
  int _stepsPerClick = 200;
  int _hydrationMLPerClick = 250;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      loadHomeSectionVisibility(),
      loadStepsPerClick(),
      loadHydrationMLPerClick(),
    ]);
    if (mounted) {
      setState(() {
        _visibility = results[0] as Map<HomeSection, bool>;
        _stepsPerClick = results[1] as int;
        _hydrationMLPerClick = results[2] as int;
        _loaded = true;
      });
    }
  }

  Future<void> _toggle(HomeSection section, bool value) async {
    await saveHomeSectionVisibility(section, value);
    if (mounted) {
      setState(() => _visibility[section] = value);
      widget.onSettingsChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.subtleFill(context, 0.30),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Icon(
            Icons.palette_outlined,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Appearance',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Show or hide sections on your home dashboard',
            style: TextStyle(
              color: AppTheme.textTertiary(context),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          if (!_loaded)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          else
            ...HomeSection.values.map(
              (section) => _buildToggleRow(context, section),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildToggleRow(BuildContext context, HomeSection section) {
    final visible = _visibility[section] ?? true;
    final hasGear = section == HomeSection.steps || section == HomeSection.hydration;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: section.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(section.icon, color: section.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              section.label,
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (hasGear) ...[
            _buildGearButton(context, section),
            const SizedBox(width: 4),
          ],
          Switch.adaptive(
            value: visible,
            activeTrackColor: section.color.withValues(alpha: 0.5),
            activeThumbColor: section.color,
            onChanged: (value) => _toggle(section, value),
          ),
        ],
      ),
    );
  }

  Widget _buildGearButton(BuildContext context, HomeSection section) {

    final isSteps = section == HomeSection.steps;
    final currentValue = isSteps ? _stepsPerClick : _hydrationMLPerClick;
    final min = isSteps ? 100 : 200;
    final max = 1000;
    final unit = isSteps ? 'steps' : 'mL';
    final icon = isSteps ? Icons.directions_walk_rounded : Icons.water_drop_rounded;
    final hint = isSteps ? '100-1000' : '200-1000 mL';

    return Semantics(
      label: 'Configure ${section.label.toLowerCase()} per tap',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final result = await showIncrementConfigDialog(
            context,
            title: isSteps ? 'Steps Per Tap' : 'Hydration Per Tap',
            currentValue: currentValue,
            min: min,
            max: max,
            icon: icon,
            color: section.color,
            unit: unit,
            hint: hint,
          );
          if (result != null && mounted) {
            setState(() {
              if (isSteps) {
                _stepsPerClick = result;
              } else {
                _hydrationMLPerClick = result;
              }
            });
            if (isSteps) {
              await saveStepsPerClick(result);
            } else {
              await saveHydrationMLPerClick(result);
            }
            widget.onSettingsChanged?.call();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            Icons.settings_outlined,
            size: 20,
            color: AppTheme.textTertiary(context),
          ),
        ),
      ),
    );
  }
}

// ── Increment config dialog ──

Future<int?> showIncrementConfigDialog(
  BuildContext context, {
  required String title,
  required int currentValue,
  required int min,
  required int max,
  required IconData icon,
  required Color color,
  required String unit,
  required String hint,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _IncrementConfigDialog(
      title: title,
      currentValue: currentValue,
      min: min,
      max: max,
      icon: icon,
      color: color,
      unit: unit,
      hint: hint,
    ),
  );
}

class _IncrementConfigDialog extends StatefulWidget {
  final String title;
  final int currentValue;
  final int min;
  final int max;
  final IconData icon;
  final Color color;
  final String unit;
  final String hint;

  const _IncrementConfigDialog({
    required this.title,
    required this.currentValue,
    required this.min,
    required this.max,
    required this.icon,
    required this.color,
    required this.unit,
    required this.hint,
  });

  @override
  State<_IncrementConfigDialog> createState() => _IncrementConfigDialogState();
}

class _IncrementConfigDialogState extends State<_IncrementConfigDialog> {
  late int _value;
  late TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _value = widget.currentValue.clamp(widget.min, widget.max);
    _controller = TextEditingController(text: _value.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commitText() {
    final parsed = int.tryParse(_controller.text);
    if (parsed != null) {
      setState(() {
        _value = parsed.clamp(widget.min, widget.max);
        _editing = false;
        _controller.text = _value.toString();
      });
    } else {
      setState(() {
        _editing = false;
        _controller.text = _value.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(widget.icon, color: widget.color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            // ── Value display / text field ──
            Semantics(
              label: 'Configure ${widget.title} value',
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _editing = true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.subtleFill(context, 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _editing
                          ? widget.color
                          : Colors.transparent,
                    ),
                  ),
                  child: _editing
                      ? TextField(
                          controller: _controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          autofocus: true,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: widget.color,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (_) => _commitText(),
                          onTapOutside: (_) => _commitText(),
                        )
                      : Text(
                          '${_value.toStringAsFixed(0)} ${widget.unit}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // ── Slider ──
            Row(
              children: [
                Text(
                  widget.min.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary(context),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _value.toDouble(),
                    min: widget.min.toDouble(),
                    max: widget.max.toDouble(),
                    divisions: widget.max - widget.min,
                    activeColor: widget.color,
                    onChanged: (v) {
                      setState(() {
                        _value = v.round();
                        _controller.text = _value.toString();
                      });
                    },
                  ),
                ),
                Text(
                  widget.max.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.hint,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textTertiary(context),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_value),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
