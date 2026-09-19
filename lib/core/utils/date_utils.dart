library;

/// Date utility functions shared across the app.

/// Returns the local date as a YYYY-MM-DD string, avoiding timezone ambiguity.
String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Checks if a day is a rest day (day 7 of the week).
bool isRestDay(int day) => day == 7;