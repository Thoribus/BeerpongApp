import 'package:beerpongapp/services/purchase_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PurchaseService — static helpers', () {
    test('starsForProduct returns correct amount for each product', () {
      expect(
        PurchaseService.starsForProduct('com.tecbreak.beerpongapp.stars_200'),
        200,
      );
      expect(
        PurchaseService.starsForProduct('com.tecbreak.beerpongapp.stars_600'),
        600,
      );
      expect(
        PurchaseService.starsForProduct('com.tecbreak.beerpongapp.stars_1500'),
        1500,
      );
    });

    test('starsForProduct returns 0 for unknown product', () {
      expect(PurchaseService.starsForProduct('com.example.unknown'), 0);
    });

    test('productIds contains all three star packs', () {
      expect(
        PurchaseService.productIds,
        containsAll([
          'com.tecbreak.beerpongapp.stars_200',
          'com.tecbreak.beerpongapp.stars_600',
          'com.tecbreak.beerpongapp.stars_1500',
        ]),
      );
    });

    test('productIds has exactly three entries', () {
      expect(PurchaseService.productIds.length, 3);
    });
  });

  group('PurchaseEvent types', () {
    test('PurchaseSuccess carries productId and starsAwarded', () {
      final event = PurchaseSuccess(productId: 'stars_200', starsAwarded: 200);
      expect(event.productId, 'stars_200');
      expect(event.starsAwarded, 200);
    });

    test('PurchaseFailure carries message', () {
      final event = PurchaseFailure('Receipt invalid');
      expect(event.message, 'Receipt invalid');
    });

    test('PurchaseCanceled is instantiable', () {
      expect(PurchaseCanceled(), isA<PurchaseEvent>());
    });
  });
}
