import 'package:beerpongapp/services/ad_rate_limiter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AdRateLimiter.instance.resetForTesting();
  });

  group('AdRateLimiter', () {
    test('starts with full daily allowance', () async {
      expect(await AdRateLimiter.instance.remainingToday(),
          AdRateLimiter.dailyLimit);
    });

    test('canWatch returns true when remaining > 0', () async {
      expect(await AdRateLimiter.instance.canWatch(), isTrue);
    });

    test('recordWatch decrements remaining by 1', () async {
      await AdRateLimiter.instance.recordWatch();
      expect(await AdRateLimiter.instance.remainingToday(),
          AdRateLimiter.dailyLimit - 1);
    });

    test('remaining reaches 0 after dailyLimit watches', () async {
      for (var i = 0; i < AdRateLimiter.dailyLimit; i++) {
        await AdRateLimiter.instance.recordWatch();
      }
      expect(await AdRateLimiter.instance.remainingToday(), 0);
    });

    test('canWatch returns false when limit is reached', () async {
      for (var i = 0; i < AdRateLimiter.dailyLimit; i++) {
        await AdRateLimiter.instance.recordWatch();
      }
      expect(await AdRateLimiter.instance.canWatch(), isFalse);
    });

    test('remaining never goes below 0', () async {
      for (var i = 0; i < AdRateLimiter.dailyLimit + 3; i++) {
        await AdRateLimiter.instance.recordWatch();
      }
      expect(await AdRateLimiter.instance.remainingToday(), 0);
    });

    test('count resets when stored date differs from today', () async {
      // Simulate a previous day's entry by writing directly.
      SharedPreferences.setMockInitialValues({
        'ad_daily_count': AdRateLimiter.dailyLimit,
        'ad_daily_date': '2000-01-01', // definitely not today
      });
      expect(await AdRateLimiter.instance.remainingToday(),
          AdRateLimiter.dailyLimit);
    });

    test('count is not reset when stored date is today', () async {
      await AdRateLimiter.instance.recordWatch();
      await AdRateLimiter.instance.recordWatch();
      // Remaining should still reflect today's watches.
      expect(await AdRateLimiter.instance.remainingToday(),
          AdRateLimiter.dailyLimit - 2);
    });
  });
}
