import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/buyer.dart';
import '../models/payment.dart';
import '../models/sale.dart';
import '../models/item_entry.dart';
import '../repositories/buyer_repository.dart';
import '../repositories/custom_item_repository.dart';
import '../repositories/item_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/sale_repository.dart';
import '../services/buyer_service.dart';
import '../services/custom_item_service.dart';
import '../services/item_service.dart';
import '../services/sale_service.dart';

// ── Database ──────────────────────────────────────────────

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

// ── Repositories ──────────────────────────────────────────

final buyerRepositoryProvider = Provider<BuyerRepository>((ref) {
  return BuyerRepository(ref.read(databaseHelperProvider));
});

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepository(ref.read(databaseHelperProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.read(databaseHelperProvider));
});

final customItemRepositoryProvider = Provider<CustomItemRepository>((ref) {
  return CustomItemRepository(ref.read(databaseHelperProvider));
});

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(ref.read(databaseHelperProvider));
});

// ── Services ──────────────────────────────────────────────

final buyerServiceProvider = Provider<BuyerService>((ref) {
  return BuyerService(
    ref.read(buyerRepositoryProvider),
    ref.read(saleRepositoryProvider),
    ref.read(paymentRepositoryProvider),
  );
});

final saleServiceProvider = Provider<SaleService>((ref) {
  return SaleService(
    ref.read(saleRepositoryProvider),
    ref.read(paymentRepositoryProvider),
  );
});

final customItemServiceProvider = Provider<CustomItemService>((ref) {
  return CustomItemService(ref.read(customItemRepositoryProvider));
});

final itemServiceProvider = Provider<ItemService>((ref) {
  return ItemService(ref.read(itemRepositoryProvider));
});

// ── State Providers ───────────────────────────────────────

/// All buyers list — auto-refreshable.
final buyerListProvider = FutureProvider<List<Buyer>>((ref) {
  return ref.read(buyerServiceProvider).getAllBuyers();
});

/// All pending (unpaid) sales — auto-refreshable.
final pendingSalesProvider = FutureProvider<List<Sale>>((ref) {
  return ref.read(saleServiceProvider).getPendingSales();
});

/// Sales for a specific buyer — family provider keyed by buyerId.
final buyerSalesProvider = FutureProvider.family<List<Sale>, int>((ref, buyerId) {
  return ref.read(saleServiceProvider).getSalesByBuyer(buyerId);
});

/// Payment history for a specific buyer — family provider keyed by buyerId.
final paymentHistoryProvider = FutureProvider.family<List<Payment>, int>((ref, buyerId) {
  return ref.read(paymentRepositoryProvider).getByBuyerId(buyerId);
});

/// Payments for a specific sale — family provider keyed by saleId.
final salePaymentsProvider = FutureProvider.family<List<Payment>, int>((ref, saleId) {
  return ref.read(paymentRepositoryProvider).getBySaleId(saleId);
});

/// Custom item names list — auto-refreshable.
final customItemListProvider = FutureProvider<List<String>>((ref) {
  return ref.read(customItemServiceProvider).getAllItems();
});

/// Full item list (all entries with price) — auto-refreshable.
final itemListProvider = FutureProvider<List<ItemEntry>>((ref) {
  return ref.read(itemServiceProvider).getAllItems();
});
