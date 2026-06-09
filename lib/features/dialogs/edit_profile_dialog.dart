import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';

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
  static const _ageKey = 'profile_age';
  static const _genderKey = 'profile_gender';

  final _picker = ImagePicker();

  String _name = 'Alex Rivera';
  String _email = 'alex@workout.dev';
  String? _avatarPath;
  double _weightKg = 75.0;
  double _heightCm = 178.0;
  int _age = 28;
  String _gender = 'male';

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<String> _genderOptions = ['male', 'female', 'other'];
  final Map<String, String> _genderLabels = {
    'male': 'Male',
    'female': 'Female',
    'other': 'Other',
  };

  String get _initials {
    final parts = _name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _name = prefs.getString(_nameKey) ?? 'Alex Rivera';
      _email = prefs.getString(_emailKey) ?? 'alex@workout.dev';
      _avatarPath = prefs.getString(_avatarKey);
      _weightKg = prefs.getDouble(_weightKey) ?? 75.0;
      _heightCm = prefs.getDouble(_heightKey) ?? 178.0;
      _age = prefs.getInt(_ageKey) ?? 28;
      _gender = prefs.getString(_genderKey) ?? 'male';

      _nameController.text = _name;
      _emailController.text = _email;
      _weightController.text = _weightKg.toStringAsFixed(1);
      _heightController.text = _heightCm.toStringAsFixed(0);
      _ageController.text = _age.toString();
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, _nameController.text.trim());
    await prefs.setString(_emailKey, _emailController.text.trim());
    await prefs.setDouble(
        _weightKey, double.tryParse(_weightController.text) ?? 75.0);
    await prefs.setDouble(
        _heightKey, double.tryParse(_heightController.text) ?? 178.0);
    await prefs.setInt(_ageKey, int.tryParse(_ageController.text) ?? 28);
    await prefs.setString(_genderKey, _gender);
    if (_avatarPath != null) {
      await prefs.setString(_avatarKey, _avatarPath!);
    } else {
      await prefs.remove(_avatarKey);
    }

    if (mounted) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
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
      setState(() => _avatarPath = xFile.path);
    }
  }

  void _showImagePicker() {
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
            const Text(
              'Change Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _imageSourceButton(
                  ctx,
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                _imageSourceButton(
                  ctx,
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_avatarPath != null)
                  _imageSourceButton(
                    ctx,
                    icon: Icons.delete_outline_rounded,
                    label: 'Remove',
                    color: Theme.of(context).colorScheme.error,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() => _avatarPath = null);
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textSecondary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
                        radius: 56,
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage: _avatarPath != null
                            ? FileImage(File(_avatarPath!))
                            : null,
                        child: _avatarPath == null
                            ? Text(
                                _initials,
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
                          child: Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Full Name ──
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: AppTheme.textSecondary(context),
                  ),
                  filled: true,
                  fillColor: AppTheme.subtleFill(context, 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: AppTheme.textPrimary(context)),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // ── Email ──
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: AppTheme.textSecondary(context),
                  ),
                  filled: true,
                  fillColor: AppTheme.subtleFill(context, 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: AppTheme.textPrimary(context)),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // ── Weight & Height ──
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: InputDecoration(
                        labelText: 'Weight (kg)',
                        prefixIcon: Icon(
                          Icons.monitor_weight_outlined,
                          color: AppTheme.textSecondary(context),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: AppTheme.subtleFill(context, 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(color: AppTheme.textPrimary(context)),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: InputDecoration(
                        labelText: 'Height (cm)',
                        prefixIcon: Icon(
                          Icons.straighten_outlined,
                          color: AppTheme.textSecondary(context),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: AppTheme.subtleFill(context, 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(color: AppTheme.textPrimary(context)),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Age ──
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'Age',
                  prefixIcon: Icon(
                    Icons.cake_outlined,
                    color: AppTheme.textSecondary(context),
                  ),
                  filled: true,
                  fillColor: AppTheme.subtleFill(context, 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: AppTheme.textPrimary(context)),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // ── Gender ──
              Text(
                'Gender',
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: _genderOptions.map((g) {
                  return ButtonSegment(
                    value: g,
                    label: Text(_genderLabels[g]!),
                  );
                }).toList(),
                selected: {_gender},
                onSelectionChanged: (selected) {
                  setState(() => _gender = selected.first);
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: colorScheme.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Save button ──
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _saveProfile,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
