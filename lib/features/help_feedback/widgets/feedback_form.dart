import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart' as theme;
import '../../../l10n/app_localizations.dart';

enum FeedbackCategory {
  bugReport,
  featureRequest,
  generalFeedback,
  question,
}

class FeedbackForm extends StatefulWidget {
  const FeedbackForm({super.key});

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  FeedbackCategory _category = FeedbackCategory.generalFeedback;
  bool _isSending = false;
  bool _sentSuccessfully = false;

  static const _whatsappNumber = '201508454471';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nameController.text = prefs.getString('profile_name') ?? '';
      _emailController.text = prefs.getString('profile_email') ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Color _categoryColor(FeedbackCategory cat) {
    return switch (cat) {
      FeedbackCategory.bugReport => Colors.red.shade600,
      FeedbackCategory.featureRequest => theme.AppTheme.weightPurple,
      FeedbackCategory.generalFeedback => theme.AppTheme.achievementGreen,
      FeedbackCategory.question => theme.AppTheme.hydrationBlue,
    };
  }

  IconData _categoryIcon(FeedbackCategory cat) {
    return switch (cat) {
      FeedbackCategory.bugReport => Icons.bug_report_outlined,
      FeedbackCategory.featureRequest => Icons.lightbulb_outline,
      FeedbackCategory.generalFeedback => Icons.chat_bubble_outline,
      FeedbackCategory.question => Icons.help_outline,
    };
  }

  String _categoryLabel(AppLocalizations l10n, FeedbackCategory cat) {
    return switch (cat) {
      FeedbackCategory.bugReport => l10n.helpFeedback_bugReport,
      FeedbackCategory.featureRequest => l10n.helpFeedback_featureRequest,
      FeedbackCategory.generalFeedback => l10n.helpFeedback_generalFeedback,
      FeedbackCategory.question => l10n.helpFeedback_question,
    };
  }

  Future<void> _sendViaWhatsApp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    final l10n = AppLocalizations.of(context);
    final categoryEmoji = switch (_category) {
      FeedbackCategory.bugReport => '🐛',
      FeedbackCategory.featureRequest => '💡',
      FeedbackCategory.generalFeedback => '💬',
      FeedbackCategory.question => '❓',
    };

    final message = StringBuffer();
    message.writeln('📩 *AIO Workout Feedback*');
    message.writeln();
    message.writeln('📂 Category: $categoryEmoji ${_categoryLabel(l10n, _category)}');
    message.writeln('👤 Name: ${_nameController.text.trim()}');
    message.writeln('📧 Email: ${_emailController.text.trim()}');
    message.writeln();
    message.writeln('📝 ${_subjectController.text.trim()}');
    message.writeln();
    message.writeln(_messageController.text.trim());

    final encodedMessage = Uri.encodeComponent(message.toString());
    final url = Uri.parse('https://wa.me/$_whatsappNumber?text=$encodedMessage');

    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        if (mounted) {
          final fallbackUrl = Uri.parse(
              'https://api.whatsapp.com/send?phone=$_whatsappNumber&text=$encodedMessage');
          await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
        }
      }
      if (mounted) {
        setState(() {
          _sentSuccessfully = true;
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.helpFeedback_success),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            backgroundColor: theme.AppTheme.achievementGreen,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.helpFeedback_whatsappFailed),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: l10n.helpFeedback_openLink,
              onPressed: () async {
                final fallbackUrl = Uri.parse(
                    'https://api.whatsapp.com/send?phone=$_whatsappNumber');
                await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_sentSuccessfully) {
      return _buildSuccessState(context, l10n);
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Form(
      key: _formKey,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            _buildCategoryPicker(context, l10n),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: l10n.helpFeedback_name,
              hint: l10n.helpFeedback_nameHint,
              icon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.helpFeedback_required : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _emailController,
              label: l10n.helpFeedback_email,
              hint: l10n.helpFeedback_emailHint,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.helpFeedback_required;
                if (!v.contains('@') || !v.contains('.')) return l10n.helpFeedback_enterValidEmail;
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _subjectController,
              label: l10n.helpFeedback_subject,
              hint: l10n.helpFeedback_subjectHint,
              icon: Icons.title,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.helpFeedback_required : null,
            ),
            const SizedBox(height: 12),
            _buildMessageField(l10n),
            const SizedBox(height: 24),
            _buildSendButton(context, l10n),
            const SizedBox(height: 24),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildCategoryPicker(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.category_outlined, size: 18, color: theme.AppTheme.textSecondary(context)),
              const SizedBox(width: 8),
              Text(
                l10n.helpFeedback_category,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.AppTheme.textPrimary(context),
                    ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FeedbackCategory.values.map((cat) {
            final isSelected = _category == cat;
            final color = _categoryColor(cat);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _category = cat);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : theme.AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.5)
                        : theme.AppTheme.subtleFill(context, 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _categoryIcon(cat),
                      size: 16,
                      color: isSelected ? color : theme.AppTheme.textTertiary(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _categoryLabel(l10n, cat),
                      style: TextStyle(
                        color: isSelected ? color : theme.AppTheme.textSecondary(context),
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction ?? TextInputAction.next,
      validator: validator,
      style: TextStyle(
        color: theme.AppTheme.textPrimary(context),
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: theme.AppTheme.textDisabled(context)),
        prefixIcon: Icon(icon, size: 20, color: theme.AppTheme.textTertiary(context)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.AppTheme.subtleFill(context, 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.AppTheme.subtleFill(context, 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5),
        ),
        filled: true,
        fillColor: theme.AppTheme.cardColor(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildMessageField(AppLocalizations l10n) {
    return TextFormField(
      controller: _messageController,
      maxLines: 5,
      minLines: 3,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return l10n.helpFeedback_required;
        if (v.trim().length < 10) return l10n.helpFeedback_minLength(10);
        return null;
      },
      style: TextStyle(
        color: theme.AppTheme.textPrimary(context),
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: l10n.helpFeedback_message,
        hintText: l10n.helpFeedback_messageHint,
        hintStyle: TextStyle(color: theme.AppTheme.textDisabled(context)),
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.AppTheme.subtleFill(context, 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.AppTheme.subtleFill(context, 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5),
        ),
        filled: true,
        fillColor: theme.AppTheme.cardColor(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildSendButton(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: _isSending ? null : _sendViaWhatsApp,
        icon: _isSending
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : const Icon(Icons.send_rounded, size: 20),
        label: Text(
          _isSending ? l10n.helpFeedback_sending : l10n.helpFeedback_sendViaWhatsapp,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 48),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_rounded,
              size: 40,
              color: const Color(0xFF25D366),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.helpFeedback_success,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.AppTheme.textPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _sentSuccessfully = false;
                  _subjectController.clear();
                  _messageController.clear();
                  _category = FeedbackCategory.generalFeedback;
                });
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(l10n.helpFeedback_feedbackTab),
            ),
          ),
        ],
      ),
    );
  }
}