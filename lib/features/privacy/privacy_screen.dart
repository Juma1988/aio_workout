import 'package:flutter/material.dart';

/// A custom-built privacy policy screen for AIO Workout.
///
/// This screen explains exactly what data the app collects, how it's stored,
/// and how users can control or delete their data. Written specifically for
/// this app — not a generic template.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _sectionHeader(context, 'Last Updated: July 2026'),
          const SizedBox(height: 8),
          _paragraph(
            context,
            'This Privacy Policy explains how AIO Workout ("we", "our", or "the app") '
            'collects, uses, stores, and protects your personal data. We built this app '
            'with your privacy as a priority — all your fitness data stays on your device '
            'by default, and you are in full control.',
          ),

          _divider(context),
          _sectionHeader(context, '1. What Data We Collect'),
          _subsectionHeader(context, 'Data You Provide Manually'),
          _bullet(context, 'Profile name and age — for personalizing your workout experience'),
          _bullet(context, 'Weight entries — for tracking weight trends over time'),
          _bullet(context, 'Hydration (water) intake logs — entered by you throughout the day'),
          _bullet(context, 'Workout details — exercises performed, sets, reps, weights used, and duration'),
          _bullet(context, 'Rest timer preference — your chosen rest period between sets'),
          _bullet(context, 'Step per tap and hydration per tap settings — for quick-log convenience'),
          _bullet(context, 'Home section visibility toggles — which sections you want to see on the home screen'),
          _size(context, 8),
          _subsectionHeader(context, 'Data Collected Automatically'),
          _bullet(context, 'Daily step count — read from device motion sensors (with your permission)'),
          _bullet(context, 'Workout dates and times — when you start and complete a workout session'),
          _bullet(context, 'Program progress — your current week and day in the workout program'),
          _bullet(context, 'Achievement progress — badges and milestones you unlock'),
          _bullet(context, 'Theme preference — whether you use light mode, dark mode, or follow system'),
          _size(context, 8),
          _subsectionHeader(context, 'Data from Your Device'),
          _bullet(context, 'Profile photo — taken with your camera or chosen from your photo library ONLY when you explicitly pick one. We never access your camera or photos without your direct action.'),
          _bullet(context, 'Language preference — your chosen app language (English or বাংলা)'),

          _divider(context),
          _sectionHeader(context, '2. How We Collect Your Data'),
          _paragraph(
            context,
            '• Manual input: You type or tap to log workouts, weight, water intake, and settings.\n'
            '• Motion sensors: Step counting uses the device accelerometer. This data never leaves your phone.\n'
            '• Camera & gallery: Only accessed when you tap "Take Photo" or "Choose from Gallery" for your profile picture.\n'
            '• App storage: All data is stored locally on your device using SharedPreferences (the standard local key-value storage provided by your device).',
          ),

          _divider(context),
          _sectionHeader(context, '3. Where Your Data Is Stored'),
          _paragraph(
            context,
            'ALL your data stays on your device. We do NOT have servers, cloud storage, or online databases. '
            'Specifically:\n\n'
            '• Workout history, weight logs, hydration data → stored in SharedPreferences (local key-value storage)\n'
            '• Settings, preferences, theme choice → stored in SharedPreferences\n'
            '• Profile photo → stored as a file in the app\'s private directory on your device\n'
            '• Step count → calculated from sensors and stored temporarily; daily totals saved to the database\n\n'
            'No data is uploaded anywhere. Your fitness journey stays private to your phone.',
          ),

          _divider(context),
          _sectionHeader(context, '4. How We Use Your Data'),
          _paragraph(
            context,
            'Your data is used ONLY for these purposes:\n\n'
            '• To display your workout history, progress charts, and statistics on screen\n'
            '• To calculate achievements and badges based on your activity\n'
            '• To send you reminder notifications (only if you opt in)\n'
            '• To personalize your experience (theme, language, home layout)\n\n'
            'We do NOT:\n'
            '• Sell your data\n'
            '• Share your data with third parties\n'
            '• Use your data for advertising\n'
            '• Analyze your data for any purpose beyond serving you',
          ),

          _divider(context),
          _sectionHeader(context, '5. Third-Party Services'),
          _paragraph(
            context,
            'This app uses the following third-party packages, which operate entirely on your device:\n\n'
            '• flutter_local_notifications — shows reminder notifications on your phone\n'
            '• image_picker — lets you choose a profile photo from your camera or gallery\n'
            '• shared_preferences — stores your settings locally\n'
            '• url_launcher — opens links in your browser when you tap them\n'
            '• shared_preferences — local key-value storage for all workout, health, and settings data\n\n'
            'None of these packages transmit your data off your device. They run locally.',
          ),

          _divider(context),
          _sectionHeader(context, '6. Permissions We Request'),
          _paragraph(
            context,
            'The app may request these permissions. Each is optional and you can revoke them anytime:\n\n'
            '• Activity Recognition (Android) — for step counting. Without this, steps are not tracked.\n'
            '• Notifications (Android 13+) — for workout reminders and hydration alerts.\n'
            '• Camera — for taking a profile photo. Only used when you explicitly tap the camera button.\n'
            '• Photos/Media (iOS) — for choosing a profile picture from your gallery.\n'
            '• Motion (iOS) — for step counting via the motion coprocessor.',
          ),

          _divider(context),
          _sectionHeader(context, '7. Your Control Over Your Data'),
          _paragraph(
            context,
            'You can at any time:\n\n'
            '• View your data — all your information is visible within the app screens\n'
            '• Edit your profile — change your name, photo, or preferences anytime\n'
            '• Delete your data — use the "Reset All Data" option in Settings > Reset to erase everything\n'
            '• Revoke permissions — go to your device Settings > Apps > AIO Workout > Permissions\n'
            '• Uninstall the app — this removes all locally stored data from your device',
          ),

          _divider(context),
          _sectionHeader(context, '8. Children\'s Privacy'),
          _paragraph(
            context,
            'This app is not directed at children under 13 (or under 16 in the EU/UK). '
            'We do not knowingly collect personal information from children. '
            'If you believe a child has provided data through this app, please contact us so we can remove it.',
          ),

          _divider(context),
          _sectionHeader(context, '9. Changes to This Policy'),
          _paragraph(
            context,
            'If we update this Privacy Policy, the "Last Updated" date at the top will change. '
            'Since the app is offline-only, significant changes may be communicated through an in-app notice.',
          ),

          _divider(context),
          _sectionHeader(context, '10. Contact Us'),
          _paragraph(
            context,
            'If you have questions about this Privacy Policy or your data, you can reach us:\n\n'
            '• By opening the app → Profile → Help & Feedback\n'
            '• Or by emailing the developer at the address listed in the Play Store listing',
          ),

          const SizedBox(height: 30),
          Center(
            child: Text(
              '© ${DateTime.now().year} AIO Workout. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _subsectionHeader(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget _paragraph(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _size(BuildContext context, double height) {
    return SizedBox(height: height);
  }
}
