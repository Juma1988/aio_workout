import 'package:flutter_test/flutter_test.dart';
import 'package:aio_workout/data/workout_log.dart';
import 'package:aio_workout/services/workout_storage_service.dart';

void main() {
  // ─── dateKey ───────────────────────────────────────────────────────────────

  group('dateKey()', () {
    test('returns YYYY-MM-DD format', () {
      final date = DateTime(2026, 7, 5);
      expect(dateKey(date), '2026-07-05');
    });

    test('pads single-digit month and day with zeros', () {
      final date = DateTime(2026, 1, 3);
      expect(dateKey(date), '2026-01-03');
    });

    test('handles December correctly', () {
      final date = DateTime(2026, 12, 25);
      expect(dateKey(date), '2026-12-25');
    });

    test('handles year boundary', () {
      final date = DateTime(2025, 1, 1);
      expect(dateKey(date), '2025-01-01');
    });
  });

  // ─── isRestDay ────────────────────────────────────────────────────────────

  group('isRestDay()', () {
    test('day 4 is a rest day', () {
      expect(isRestDay(4), isTrue);
    });

    test('day 7 is a rest day', () {
      expect(isRestDay(7), isTrue);
    });

    test('day 1 is not a rest day', () {
      expect(isRestDay(1), isFalse);
    });

    test('day 3 is not a rest day', () {
      expect(isRestDay(3), isFalse);
    });

    test('day 5 is not a rest day', () {
      expect(isRestDay(5), isFalse);
    });
  });

  // ─── getFocusForDay ───────────────────────────────────────────────────────

  group('getFocusForDay()', () {
    test('rest days return "Rest Day"', () {
      expect(getFocusForDay(1, 4), 'Rest Day');
      expect(getFocusForDay(5, 7), 'Rest Day');
    });

    test('week 1 day 1 returns Core Foundation', () {
      expect(getFocusForDay(1, 1), 'Core Foundation');
    });

    test('week 2 day 2 returns Upper Body Basics', () {
      expect(getFocusForDay(2, 2), 'Upper Body Basics');
    });

    test('week 3 day 3 returns Lower Body Foundation', () {
      expect(getFocusForDay(3, 3), 'Lower Body Foundation');
    });
  });

  // ─── ProgramProgress ──────────────────────────────────────────────────────

  group('ProgramProgress', () {
    group('advance()', () {
      test('advances day by 1 within a week', () {
        final progress = const ProgramProgress(currentWeek: 1, currentDay: 1);
        final advanced = progress.advance();
        expect(advanced.currentWeek, 1);
        expect(advanced.currentDay, 2);
      });

      test('wraps to next week on day 7', () {
        final progress = const ProgramProgress(currentWeek: 1, currentDay: 7);
        final advanced = progress.advance();
        expect(advanced.currentWeek, 2);
        expect(advanced.currentDay, 1);
      });

      test('multiple advances work correctly', () {
        var progress = const ProgramProgress(currentWeek: 1, currentDay: 1);
        for (int i = 0; i < 6; i++) {
          progress = progress.advance();
        }
        // After 6 advances: day 1→2→3→4→5→6→7
        expect(progress.currentWeek, 1);
        expect(progress.currentDay, 7);
      });

      test('7th advance rolls over to week 2', () {
        var progress = const ProgramProgress(currentWeek: 1, currentDay: 1);
        for (int i = 0; i < 7; i++) {
          progress = progress.advance();
        }
        expect(progress.currentWeek, 2);
        expect(progress.currentDay, 1);
      });

      test('preserves lastAdvanceDate', () {
        final progress = const ProgramProgress(
          currentWeek: 1,
          currentDay: 1,
          lastAdvanceDate: '2026-07-05',
        );
        final advanced = progress.advance();
        expect(advanced.lastAdvanceDate, '2026-07-05');
      });
    });

    group('serialization', () {
      test('round-trip toJson/fromJson preserves all fields', () {
        final original = ProgramProgress(
          currentWeek: 3,
          currentDay: 5,
          lastAdvanceDate: '2026-07-05',
        );
        final json = original.toJson();
        final restored = ProgramProgress.fromJson(json);
        expect(restored.currentWeek, original.currentWeek);
        expect(restored.currentDay, original.currentDay);
        expect(restored.lastAdvanceDate, original.lastAdvanceDate);
      });

      test('fromJson handles null lastAdvanceDate', () {
        final result = ProgramProgress.fromJson({'currentWeek': 2, 'currentDay': 3});
        expect(result.currentWeek, 2);
        expect(result.currentDay, 3);
        expect(result.lastAdvanceDate, isNull);
      });

      test('fromJson uses defaults for missing keys', () {
        final result = ProgramProgress.fromJson({});
        expect(result.currentWeek, 1);
        expect(result.currentDay, 1);
        expect(result.lastAdvanceDate, isNull);
      });
    });
  });

  // ─── WorkoutSession ───────────────────────────────────────────────────────

  group('WorkoutSession', () {
    final sampleExercise = CompletedExercise(
      exerciseUuid: 'ex-1',
      exerciseName: 'Push Up',
      setsCompleted: 3,
      repsCompleted: 12,
    );

    final sampleSession = WorkoutSession(
      uuid: 'ws-1',
      date: DateTime(2026, 7, 5, 10, 30),
      weekNumber: 1,
      dayNumber: 2,
      focus: 'Upper Body Basics',
      durationSeconds: 1800,
      exercises: [sampleExercise],
      plannedExerciseUuids: ['ex-1', 'ex-2'],
      steps: 500,
      hydrationLiters: 0.5,
      achievementsUnlocked: ['ach-1'],
    );

    test('totalSets sums exercises correctly', () {
      expect(sampleSession.totalSets, 3);
    });

    test('totalSets with multiple exercises', () {
      final session = WorkoutSession(
        uuid: 'ws-2',
        date: DateTime(2026, 7, 5),
        weekNumber: 1,
        dayNumber: 2,
        focus: 'Full Body',
        durationSeconds: 3600,
        exercises: [
          const CompletedExercise(
            exerciseUuid: 'ex-1', exerciseName: 'Push Up',
            setsCompleted: 3, repsCompleted: 10,
          ),
          const CompletedExercise(
            exerciseUuid: 'ex-2', exerciseName: 'Squat',
            setsCompleted: 4, repsCompleted: 8,
          ),
          const CompletedExercise(
            exerciseUuid: 'ex-3', exerciseName: 'Pull Up',
            setsCompleted: 2, repsCompleted: 6,
          ),
        ],
      );
      expect(session.totalSets, 9); // 3 + 4 + 2
    });

    test('completedUuids returns set of exercise UUIDs', () {
      expect(sampleSession.completedUuids, {'ex-1'});
    });

    group('serialization', () {
      test('round-trip toJson/fromJson preserves all fields', () {
        final json = sampleSession.toJson();
        final restored = WorkoutSession.fromJson(json);

        expect(restored.uuid, sampleSession.uuid);
        expect(restored.weekNumber, sampleSession.weekNumber);
        expect(restored.dayNumber, sampleSession.dayNumber);
        expect(restored.focus, sampleSession.focus);
        expect(restored.durationSeconds, sampleSession.durationSeconds);
        expect(restored.steps, sampleSession.steps);
        expect(restored.hydrationLiters, sampleSession.hydrationLiters);
        expect(restored.achievementsUnlocked, sampleSession.achievementsUnlocked);
        expect(restored.notes, sampleSession.notes);
        expect(restored.exercises.length, sampleSession.exercises.length);
        expect(restored.exercises.first.exerciseName, 'Push Up');
        expect(restored.exercises.first.setsCompleted, 3);
      });

      test('fromJson handles missing optional fields with defaults', () {
        final json = {
          'uuid': 'ws-3',
          'date': '2026-07-05T10:00:00.000',
          'weekNumber': 1,
          'dayNumber': 1,
          'focus': 'Core',
          'durationSeconds': 1200,
          'exercises': [],
        };
        final result = WorkoutSession.fromJson(json);
        expect(result.plannedExerciseUuids, isEmpty);
        expect(result.steps, 0);
        expect(result.hydrationLiters, 0.0);
        expect(result.achievementsUnlocked, isEmpty);
        expect(result.notes, isNull);
      });
    });
  });

  // ─── CompletedExercise ────────────────────────────────────────────────────

  group('CompletedExercise', () {
    group('serialization', () {
      test('round-trip toJson/fromJson preserves all fields', () {
        final original = const CompletedExercise(
          exerciseUuid: 'ex-1',
          exerciseName: 'Push Up',
          setsCompleted: 3,
          repsCompleted: 12,
          durationSeconds: 60,
        );
        final json = original.toJson();
        final restored = CompletedExercise.fromJson(json);
        expect(restored.exerciseUuid, original.exerciseUuid);
        expect(restored.exerciseName, original.exerciseName);
        expect(restored.setsCompleted, original.setsCompleted);
        expect(restored.repsCompleted, original.repsCompleted);
        expect(restored.durationSeconds, original.durationSeconds);
      });

      test('fromJson handles null repsCompleted and durationSeconds', () {
        final json = {
          'exerciseUuid': 'ex-1',
          'exerciseName': 'Push Up',
          'setsCompleted': 3,
        };
        final result = CompletedExercise.fromJson(json);
        expect(result.repsCompleted, isNull);
        expect(result.durationSeconds, isNull);
      });
    });
  });
}
