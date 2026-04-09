import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// ── Events ─────────────────────────────────────────────────────────────────

sealed class PurchaseEvent {}

final class PurchaseSuccess extends PurchaseEvent {
  final String productId;
  final int starsAwarded;
  PurchaseSuccess({required this.productId, required this.starsAwarded});
}

final class PurchaseFailure extends PurchaseEvent {
  final String message;
  PurchaseFailure(this.message);
}

final class PurchaseCanceled extends PurchaseEvent {}

// ── Service ────────────────────────────────────────────────────────────────

/// Manages the in-app purchase lifecycle.
///
/// Call [initialize] once at app startup (before [runApp]) and add to the
/// Provider tree so UI can watch [products] and [isPurchasing].
///
/// Listen to [events] for success/failure notifications — both the Get Stars
/// sheet and the root app widget subscribe so the balance is refreshed even
/// when the sheet has been dismissed.
class PurchaseService extends ChangeNotifier {
  static final instance = PurchaseService._();
  PurchaseService._();

  // Product IDs — must match App Store Connect and Google Play Console.
  static const Set<String> productIds = {
    'com.tecbreak.beerpongcompanion.stars_200',
    'com.tecbreak.beerpongcompanion.stars_600',
    'com.tecbreak.beerpongcompanion.stars_1500',
    'com.tecbreak.beerpongcompanion.supporter_pack',
  };

  static const String supporterPackId = 'com.tecbreak.beerpongcompanion.supporter_pack';

  static const Map<String, int> _starAmounts = {
    'com.tecbreak.beerpongcompanion.stars_200': 200,
    'com.tecbreak.beerpongcompanion.stars_600': 600,
    'com.tecbreak.beerpongcompanion.stars_1500': 1500,
    'com.tecbreak.beerpongcompanion.supporter_pack': 300,
  };

  final _eventController = StreamController<PurchaseEvent>.broadcast();

  /// Broadcast stream of purchase outcomes. Subscribe in both the sheet (for
  /// snackbar feedback) and the root widget (to keep balance fresh).
  Stream<PurchaseEvent> get events => _eventController.stream;

  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isPurchasing = false;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  /// Store-supplied product list, sorted cheapest-first.
  List<ProductDetails> get products => List.unmodifiable(_products);

  /// False when the store is unreachable (e.g. no network, unsupported platform).
  bool get isAvailable => _isAvailable;

  /// True while a purchase is in flight (payment sheet open or receipt
  /// being validated). Use to disable the buy buttons.
  bool get isPurchasing => _isPurchasing;

  /// Stars awarded for a given product ID.
  static int starsForProduct(String productId) =>
      _starAmounts[productId] ?? 0;

  /// Must be called once at app startup, before [runApp].
  Future<void> initialize() async {
    _isAvailable = await InAppPurchase.instance.isAvailable();
    if (!_isAvailable) {
      debugPrint('PurchaseService: store not available');
      return;
    }

    _purchaseSub = InAppPurchase.instance.purchaseStream.listen(
      _handleUpdate,
      onError: (Object e) =>
          debugPrint('PurchaseService: stream error — $e'),
    );

    await _loadProducts();

    // Deliver any purchases that completed while the app was terminated.
    await InAppPurchase.instance.restorePurchases();
  }

  Future<void> _loadProducts() async {
    final response =
        await InAppPurchase.instance.queryProductDetails(productIds);
    if (response.error != null) {
      debugPrint('PurchaseService: product query error — ${response.error}');
    }
    _products = response.productDetails
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    notifyListeners();
  }

  /// Initiates a consumable purchase. The store's native payment sheet is
  /// shown; the result arrives asynchronously via [events].
  Future<void> buy(ProductDetails product) async {
    if (_isPurchasing || !_isAvailable) return;
    _isPurchasing = true;
    notifyListeners();
    final param = PurchaseParam(productDetails: product);
    if (product.id == supporterPackId) {
      await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
    } else {
      await InAppPurchase.instance.buyConsumable(purchaseParam: param);
    }
    // _isPurchasing is reset in _handleUpdate once the stream fires.
  }

  /// Restores non-consumable purchases (required by App Store guidelines).
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    await InAppPurchase.instance.restorePurchases();
  }

  void _handleUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break; // payment in progress — nothing to do
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _validateAndCredit(purchase);
        case PurchaseStatus.error:
          _isPurchasing = false;
          notifyListeners();
          _eventController.add(
            PurchaseFailure(purchase.error?.message ?? 'Purchase failed'),
          );
          if (purchase.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchase);
          }
        case PurchaseStatus.canceled:
          _isPurchasing = false;
          notifyListeners();
          _eventController.add(PurchaseCanceled());
      }
    }
  }

  Future<void> _validateAndCredit(PurchaseDetails purchase) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('validatePurchase');
      final result = await callable.call<Map<Object?, Object?>>({
        'productId': purchase.productID,
        'transactionId': purchase.purchaseID,
        'receiptData': purchase.verificationData.serverVerificationData,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });

      final data = Map<String, dynamic>.from(result.data);
      final starsAwarded =
          (data['starsAwarded'] as num?)?.toInt() ??
          _starAmounts[purchase.productID] ??
          0;

      _eventController.add(
        PurchaseSuccess(productId: purchase.productID, starsAwarded: starsAwarded),
      );
    } on FirebaseFunctionsException catch (e) {
      debugPrint('PurchaseService: validation error — ${e.message}');
      _eventController.add(PurchaseFailure(e.message ?? 'Validation failed'));
    } catch (e) {
      debugPrint('PurchaseService: unexpected error — $e');
      _eventController.add(PurchaseFailure('Something went wrong'));
    } finally {
      _isPurchasing = false;
      notifyListeners();
      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    _eventController.close();
    super.dispose();
  }
}
