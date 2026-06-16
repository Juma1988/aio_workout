import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart' as theme;
import '../../l10n/app_localizations.dart';
import 'widgets/help_tab.dart';
import 'widgets/feedback_form.dart';

class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key});

  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpFeedback_title),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: theme.AppTheme.textTertiary(context),
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          tabs: [
            Tab(
              icon: const Icon(Icons.help_outline, size: 20),
              text: l10n.helpFeedback_helpTab,
            ),
            Tab(
              icon: const Icon(Icons.feedback_outlined, size: 20),
              text: l10n.helpFeedback_feedbackTab,
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: TabBarView(
            controller: _tabController,
            children: const [
              HelpTab(),
              FeedbackForm(),
            ],
          ),
        ),
      ),
    );
  }
}