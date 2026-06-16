import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/directional_icon.dart';
import '../../l10n/app_localizations.dart';
import '../../services/workout_storage_service.dart' show dateKey;

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  static const _nameKey = 'profile_name';
  static const _emailKey = 'profile_email';
  static const _avatarKey = 'profile_avatar_path';
  static const _weightKey = 'profile_weight_kg';
  static const _heightKey = 'profile_height_cm';
  static const _dobKey = 'profile_dob';
  static const _genderKey = 'profile_gender';

  final _picker = ImagePicker();

  String? _name;
  String? _email;
  String? _avatarPath;
  double? _weightKg;
  double? _heightCm;
  DateTime? _dateOfBirth;
  String _gender = 'male';

  bool _isDirty = false;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  late final TextEditingController _dobController;
  final _formKey = GlobalKey<FormState>();

  Map<String, String> _genderLabels(AppLocalizations l10n) => {
    'male': l10n.dialog_male,
    'female': l10n.dialog_female,
    'other': 'Mentally unstable',
  };
  final Map<String, IconData> _genderIcons = {
    'male': Icons.male,
    'female': Icons.female,
    'other': Icons.psychology,
  };

  String? get _initials {
    final parts = _name?.split(' ');
    if (parts != null && parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts != null && parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return null;
  }

  int get _calculatedAge {
    if (_dateOfBirth == null) return 0;
    final now = DateTime.now();
    int age = now.year - _dateOfBirth!.year;
    if (now.month < _dateOfBirth!.month ||
        (now.month == _dateOfBirth!.month && now.day < _dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  double? get _bmi {
    final w = _weightKg;
    final h = _heightCm;
    if (w == null || h == null || w <= 0 || h <= 0) return null;
    final heightM = h / 100;
    return w / (heightM * heightM);
  }

  String _bmiCategory(AppLocalizations l10n) {
    final b = _bmi;
    if (b == null) return '';
    if (b < 18.5) return l10n.dialog_underweight;
    if (b < 25) return l10n.dialog_normal;
    if (b < 30) return l10n.dialog_overweight;
    return l10n.dialog_obese;
  }

  Color _bmiColor(BuildContext context) {
    final b = _bmi;
    if (b == null) return AppTheme.textSecondary(context);
    if (b < 18.5) return AppTheme.hydrationBlue;
    if (b < 25) return AppTheme.achievementGreen;
    if (b < 30) return AppTheme.stepsOrange;
    return Theme.of(context).colorScheme.error;
  }

  @override
  void initState() {
    super.initState();
    _dobController = TextEditingController();
    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _weightController.addListener(_onFieldChanged);
    _heightController.addListener(_onFieldChanged);
    _loadProfile();
  }

  void _onFieldChanged() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _nameController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _weightController.removeListener(_onFieldChanged);
    _heightController.removeListener(_onFieldChanged);
    setState(() {
      _name = prefs.getString(_nameKey);
      _email = prefs.getString(_emailKey);
      _avatarPath = prefs.getString(_avatarKey);
      _weightKg = prefs.getDouble(_weightKey);
      _heightCm = prefs.getDouble(_heightKey);
      _gender = prefs.getString(_genderKey) ?? 'male';

      final dobStr = prefs.getString(_dobKey);
      _dateOfBirth = dobStr != null ? DateTime.tryParse(dobStr) : null;

      _nameController.text = _name ?? '';
      _emailController.text = _email ?? '';
      _weightController.text = _weightKg?.toStringAsFixed(1) ?? '';
      _heightController.text = _heightCm?.toStringAsFixed(0) ?? '';
      _dobController.text = _dateOfBirth != null
          ? DateFormat.yMMMd().format(_dateOfBirth!)
          : '';
      _isDirty = false;
    });
    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _weightController.addListener(_onFieldChanged);
    _heightController.addListener(_onFieldChanged);
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context);
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_nameKey, _nameController.text.trim()),
        prefs.setString(_emailKey, _emailController.text.trim()),
        prefs.setDouble(
            _weightKey, double.tryParse(_weightController.text) ?? 0),
        prefs.setDouble(
            _heightKey, double.tryParse(_heightController.text) ?? 0),
        if (_dateOfBirth != null) ...[
          prefs.setString(
              _dobKey, dateKey(_dateOfBirth!)),
          prefs.setInt('profile_age', _calculatedAge),
        ] else ...[
          prefs.remove(_dobKey),
          prefs.remove('profile_age'),
        ],
        prefs.setString(_genderKey, _gender),
        if (_avatarPath != null)
          prefs.setString(_avatarKey, _avatarPath!)
        else
          prefs.remove(_avatarKey),
      ]);

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dialog_failedToSave(e.toString())),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (xFile != null && mounted) {
      setState(() {
        _avatarPath = xFile.path;
        _isDirty = true;
      });
    }
  }

  void _showImagePicker() {
    final l10n = AppLocalizations.of(context);
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.subtleFill(context, 0.30),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.dialog_changePhoto,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _imageSourceButton(
                  ctx,
                  icon: Icons.camera_alt_rounded,
                  label: l10n.dialog_camera,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                _imageSourceButton(
                  ctx,
                  icon: Icons.photo_library_rounded,
                  label: l10n.dialog_gallery,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_avatarPath != null)
                  _imageSourceButton(
                    ctx,
                    icon: Icons.delete_outline_rounded,
                    label: l10n.dialog_removePhoto,
                    color: Theme.of(context).colorScheme.error,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        _avatarPath = null;
                        _isDirty = true;
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageSourceButton(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 28),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.subtleFill(ctx, 0.08),
            foregroundColor: color ?? AppTheme.textPrimary(ctx),
            fixedSize: const Size(56, 56),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: color ?? AppTheme.textSecondary(ctx),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.day,
    );
    if (picked != null && mounted) {
      final age = _calculateAgeFrom(picked);
      if (age < 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dialog_minAgeError),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (age > 120) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dialog_verifyDob),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      setState(() {
        _dateOfBirth = picked;
        _dobController.text = DateFormat.yMMMd().format(picked);
        _isDirty = true;
      });
    }
  }

  int _calculateAgeFrom(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<bool> _onWillPop() async {
    final l10n = AppLocalizations.of(context);
    if (!_isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(l10n.dialog_unsavedChanges),
        content: Text(l10n.dialog_unsavedChangesBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.dialog_keepEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.dialog_discard),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    IconData? prefixIcon,
    String? suffixText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon,
              color: AppTheme.textSecondary(context), size: 20)
          : null,
      suffixText: suffixText,
      suffixStyle: TextStyle(color: AppTheme.textTertiary(context)),
      filled: true,
      fillColor: AppTheme.subtleFill(context, isDark ? 0.05 : 0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _weightController.removeListener(_onFieldChanged);
    _heightController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _emailController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.dialog_editProfile,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon:
                DirectionalIcon(icon: Icons.arrow_back, color: AppTheme.textSecondary(context)),
            onPressed: () async {
              if (_isDirty) {
                final shouldPop = await _onWillPop();
                if (shouldPop && context.mounted) {
                  Navigator.of(context).pop();
                }
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar ──
                Center(
                  child: GestureDetector(
                    onTap: _showImagePicker,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 64,
                          backgroundColor: colorScheme.primaryContainer,
                          backgroundImage: _avatarPath != null
                              ? FileImage(File(_avatarPath!))
                              : null,
                          child: _avatarPath == null && _initials != null
                              ? Text(
                                  _initials!,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.cardColor(context),
                                width: 3,
                              ),
                            ),
                            child: Semantics(
                              label: l10n.dialog_changePhoto,
                              child: Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    l10n.dialog_tapToSelect,
                    style: TextStyle(
                      color: AppTheme.textTertiary(context),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Full Name ──
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration(
                    context,
                    label: l10n.dialog_fullName,
                    hint: l10n.dialog_enterNameHint,
                    prefixIcon: Icons.person_outline,
                  ),
                  style: TextStyle(color: AppTheme.textPrimary(context)),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.dialog_required;
                    if (v.trim().length < 2) return l10n.dialog_enterValidName;
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ── Email ──
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration(
                    context,
                    label: l10n.dialog_email,
                    hint: 'your@email.com',
                    prefixIcon: Icons.email_outlined,
                  ),
                  style: TextStyle(color: AppTheme.textPrimary(context)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.dialog_required;
                    final emailRegex =
                        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(v.trim())) {
                      return l10n.dialog_enterValidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ── Date of Birth ──
                TextFormField(
                  readOnly: true,
                  controller: _dobController,
                  decoration: _inputDecoration(
                    context,
                    label: l10n.dialog_dateOfBirth,
                    hint: l10n.dialog_tapToSelect,
                    prefixIcon: Icons.calendar_today_outlined,
                  ),
                  style: TextStyle(color: AppTheme.textPrimary(context)),
                  onTap: _pickDate,
                ),
                if (_calculatedAge > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      l10n.dialog_ageDisplay(_calculatedAge),
                      style: TextStyle(
                        color: AppTheme.textTertiary(context),
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // ── Weight & Height ──
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        decoration: _inputDecoration(
                          context,
                          label: l10n.dialog_weight,
                          hint: l10n.dialog_weightHint,
                          prefixIcon: Icons.monitor_weight_outlined,
                          suffixText: 'kg',
                        ),
                        style:
                            TextStyle(color: AppTheme.textPrimary(context)),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return l10n.dialog_required;
                          final val = double.tryParse(v);
                          if (val == null) return l10n.dialog_enterNumber;
                          if (val < 20 || val > 300) {
                            return l10n.dialog_weightRange;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        decoration: _inputDecoration(
                          context,
                          label: l10n.dialog_height,
                          hint: l10n.dialog_heightHint,
                          prefixIcon: Icons.straighten_outlined,
                          suffixText: 'cm',
                        ),
                        style:
                            TextStyle(color: AppTheme.textPrimary(context)),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return l10n.dialog_required;
                          final val = double.tryParse(v);
                          if (val == null) return l10n.dialog_enterNumber;
                          if (val < 50 || val > 250) {
                            return l10n.dialog_heightRange;
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                // ── BMI ──
                AnimatedSize(
                  duration: AppTheme.kAnimMedium,
                  curve: AppTheme.kEaseOut,
                  child: _bmi != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.subtleFill(context, 0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.monitor_heart_outlined,
                                        color: _bmiColor(context), size: 20),
                                    const SizedBox(width: 10),
                                    Text(l10n.dialog_bodyMassIndex,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary(
                                                context))),
                                    const Spacer(),
                                    Text(
                                      _bmi!.toStringAsFixed(1),
                                      style: TextStyle(
                                        color: AppTheme.textPrimary(context),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _bmiCategory(l10n),
                                      style: TextStyle(
                                        color: _bmiColor(context),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (_bmi! / 40).clamp(0.0, 1.0),
                                    backgroundColor:
                                        AppTheme.subtleFill(context, 0.1),
                                    color: _bmiColor(context),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(l10n.dialog_underweight,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                AppTheme.textTertiary(context))),
                                    const Spacer(),
                                    Text(l10n.dialog_normal,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                AppTheme.textTertiary(context))),
                                    const Spacer(),
                                    Text(l10n.dialog_obese,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                AppTheme.textTertiary(context))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // ── Gender ──
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dialog_gender,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height:8),
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(flex: 2, child: _buildGenderChip(context, l10n, 'male')),
                                const SizedBox(width: 8),
                                Expanded(flex: 2, child: _buildGenderChip(context, l10n, 'female')),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: _buildGenderChip(context, l10n, 'other'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Save button ──
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.dialog_saveChanges,
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderChip(BuildContext context, AppLocalizations l10n, String key) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _gender == key;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _gender = key;
            _isDirty = true;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: AppTheme.kAnimFast,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_genderIcons[key], size: 18,
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(
                _genderLabels(l10n)[key]!,
                style: TextStyle(
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
