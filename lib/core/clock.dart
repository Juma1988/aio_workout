/// Abstract clock so time-dependent logic is testable.
abstract class Clock {
  const Clock();
  DateTime now();
}

/// The real system clock — delegates to [DateTime.now].
class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
