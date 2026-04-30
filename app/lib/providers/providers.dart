import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/buyer.dart';
import '../models/sale.dart';
import '../repositories/buyer_repository.dart';
import '../repositories/sale_repository.dart';
import '../services/buyer_service.dart';
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

// ── Services ──────────────────────────────────────────────

final buyerServiceProvider = Provider<BuyerService>((ref) {
  return BuyerService(ref.read(buyerRepositoryProvider));
});

final saleServiceProvider = Provider<SaleService>((ref) {
  return SaleService(ref.read(saleRepositoryProvider));
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
