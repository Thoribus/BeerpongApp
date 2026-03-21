import 'package:shared_preferences/shared_preferences.dart';

/// Tracks daily rewarded-ad watches using SharedPreferences.
///
/// Limit: [dailyLimit] per calendar day, resetting at midnight local time.
/// State is device-local only (not synced to Firestore).
class AdRateLimiter {
  static final instance = AdRateLimiter._();
  AdRateLimiter._();

  static const int dailyLimit = 5;
  static const String _countKey = 'ad_daily_count';
  static const String _dateKey = 'ad_daily_date';

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<int> remainingToday() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDate = prefs.getString(_dateKey);
    final today = _todayString();
    if (storedDate != today) return dailyLimit;
    final count = prefs.getInt(_countKey) ?? 0;
    return (dailyLimit - count).clamp(0, dailyLimit);
  }

  Future<bool> canWatch() async => (await remainingToday()) > 0;

  Future<void> recordWatch() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final storedDate = prefs.getString(_dateKey);
    final count = storedDate == today ? (prefs.getInt(_countKey) ?? 0) : 0;
    await prefs.setString(_dateKey, today);
    await prefs.setInt(_countKey, count + 1);
  }

  /// For testing only — resets the stored count and date.
  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_countKey);
    await prefs.remove(_dateKey);
  }
}
