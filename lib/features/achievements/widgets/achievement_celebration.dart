import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/directional_icon.dart';
import '../../../l10n/app_localizations.dart';
import '../models/achievement_result.dart';

class AchievementCelebration extends StatefulWidget {
  final List<AchievementResult> newAchievements;
  final int exerciseCount;
  final int durationSeconds;
  final int completedWeek;
  final String focus;
  final VoidCallback onDismiss;

  const AchievementCelebration({
    super.key,
    required this.newAchievements,
    required this.exerciseCount,
    required this.durationSeconds,
    required this.completedWeek,
    required this.focus,
    required this.onDismiss,
  });

  @override
  State<AchievementCelebration> createState() => _AchievementCelebrationState();
}

class _AchievementCelebrationState extends State<AchievementCelebration>
    with TickerProviderStateMixin {
  late final AnimationController _trophyController;
  late final AnimationController _confettiController;
  late final AnimationController _contentController;
  late final Animation<double> _trophyScale;
  late final Animation<double> _contentFade;
  late final List<_ConfettiParticle> _particles;
  final _random = Random();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _trophyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _trophyScale = CurvedAnimation(
      parent: _trophyController,
      curve: Curves.elasticOut,
    );

    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );

    _particles = List.generate(40, (_) => _ConfettiParticle(_random));

    HapticFeedback.heavyImpact();

    _trophyController.forward();
    _confettiController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _contentController.forward();
    });
  }

  @override
  void dispose() {
    _trophyController.dispose();
    _confettiController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _nextAchievement() {
    if (_currentIndex < widget.newAchievements.length - 1) {
      HapticFeedback.mediumImpact();
      setState(() {
        _currentIndex++;
        _trophyController.forward(from: 0.0);
        _contentController.forward(from: 0.0);
      });
    } else {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final achievement = widget.newAchievements[_currentIndex];
    final catColor = achievement.definition.category.color;
    final displayTitle = achievement.definition.localizedTitle(l10n);
    final displayDescription =
        achievement.definition.localizedDescription(l10n);

    return Material(
      color: Colors.black87,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: _confettiController.value,
                ),
              );
            },
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Spacer(flex: 2),
                  AnimatedBuilder(
                    animation: _trophyScale,
                    builder: (context, _) {
                      return Transform.scale(
                        scale: _trophyScale.value,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: catColor.withValues(alpha: 0.3),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            achievement.definition.category.icon,
                            color: catColor,
                            size: 48,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _contentFade,
                    child: Column(
                      children: [
                        Text(
                          'Achievement Unlocked!',
                          style: TextStyle(
                            color: catColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          displayTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            displayDescription,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 1),
                  _buildStats(),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _nextAchievement,
                            icon: _currentIndex < widget.newAchievements.length - 1
                                ? DirectionalIcon(icon: Icons.arrow_forward, size: 20)
                                : const Icon(Icons.check_circle_rounded, size: 20),
                            label: Text(
                              _currentIndex < widget.newAchievements.length - 1
                                  ? 'Next Achievement'
                                  : 'Let\'s Go!',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: catColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        if (widget.newAchievements.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${_currentIndex + 1} of ${widget.newAchievements.length}',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return FadeTransition(
      opacity: _contentFade,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statItem('${widget.exerciseCount}', 'Exercises'),
            _statItem('${widget.durationSeconds ~/ 60}min', 'Duration'),
            _statItem('W${widget.completedWeek}', 'Completed'),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ConfettiParticle {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;

  _ConfettiParticle(Random random)
      : startX = random.nextDouble(),
        startY = -0.1 - random.nextDouble() * 0.3,
        endX = random.nextDouble(),
        endY = 1.0 + random.nextDouble() * 0.3,
        size = 4 + random.nextDouble() * 6,
        rotation = random.nextDouble() * 6.28,
        rotationSpeed = 2 + random.nextDouble() * 4,
        color = [
          const Color(0xFF22C55E),
          const Color(0xFFF97316),
          const Color(0xFF3B82F6),
          const Color(0xFFA855F7),
          const Color(0xFFF59E0B),
          const Color(0xFFEF4444),
          const Color(0xFFEC4899),
          const Color(0xFFFFFFFF),
        ][random.nextInt(8)];
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final x = lerpDouble(p.startX, p.endX, progress)! * size.width;
      final y = lerpDouble(p.startY, p.endY, progress)! * size.height;
      final alpha = progress < 0.8 ? 1.0 : (1.0 - (progress - 0.8) / 0.2);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + progress * p.rotationSpeed);

      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
