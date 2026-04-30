import '../models/sale.dart';
import '../repositories/sale_repository.dart';

/// Business logic for sale operations.
class SaleService {
  final SaleRepository _repository;

  SaleService(this._repository);

  /// Create a new sale record.
  /// Automatically calculates due amount.
  Future<Sale> createSale({
    required int buyerId,
    required String itemName,
    required String unitType,
    required double quantity,
    required double totalAmount,
    required double advancePaid,
    required DateTime saleDate,
  }) async {
    final dueAmount = totalAmount - advancePaid;
    final status = dueAmount <= 0 ? 'paid' : 'pending';

    final sale = Sale(
      buyerId: buyerId,
      itemName: itemName,
      unitType: unitType,
      quantity: quantity,
      totalAmount: totalAmount,
      advancePaid: advancePaid,
      dueAmount: dueAmount < 0 ? 0 : dueAmount,
      saleDate: saleDate,
      status: status,
    );

    final id = await _repository.insert(sale);
    return sale.copyWith(id: id);
  }

  /// Update an existing sale record.
  /// Recalculates due amount and status.
  Future<void> editSale({
    required int saleId,
    required int buyerId,
    required String itemName,
    required String unitType,
    required double quantity,
    required double totalAmount,
    required double advancePaid,
    required DateTime saleDate,
  }) async {
    final dueAmount = totalAmount - advancePaid;
    final status = dueAmount <= 0 ? 'paid' : 'pending';

    final existingSale = await _repository.getById(saleId);
    if (existingSale == null) return;

    final updatedSale = existingSale.copyWith(
      buyerId: buyerId,
      itemName: itemName,
      unitType: unitType,
      quantity: quantity,
      totalAmount: totalAmount,
      advancePaid: advancePaid,
      dueAmount: dueAmount < 0 ? 0 : dueAmount,
      saleDate: saleDate,
      status: status,
      updatedAt: DateTime.now(),
    );

    await _repository.update(updatedSale);
  }

  /// Mark a sale as fully paid (due becomes 0, status becomes 'paid').
  Future<void> markSaleAsPaid(int saleId) async {
    await _repository.markAsPaid(saleId);
  }

  /// Get all sales for a specific buyer.
  Future<List<Sale>> getSalesByBuyer(int buyerId) {
    return _repository.getByBuyerId(buyerId);
  }

  /// Get all unpaid sale records.
  Future<List<Sale>> getPendingSales() {
    return _repository.getPendingSales();
  }
}
