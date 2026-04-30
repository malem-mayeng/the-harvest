import '../models/payment.dart';
import '../models/sale.dart';
import '../repositories/payment_repository.dart';
import '../repositories/sale_repository.dart';

/// Business logic for sale operations.
class SaleService {
  final SaleRepository _repository;
  final PaymentRepository _paymentRepository;

  SaleService(this._repository, this._paymentRepository);

  /// Create a new sale record.
  /// Quantity and totalAmount can be 0 (optional fields).
  /// Automatically calculates due amount, clamped to 0.
  Future<Sale> createSale({
    required int buyerId,
    required String itemName,
    required String unitType,
    double quantity = 0,
    double totalAmount = 0,
    double advancePaid = 0,
    required DateTime saleDate,
    String? notes,
  }) async {
    final totalPaid = advancePaid;
    final dueAmount = (totalAmount - totalPaid).clamp(0.0, double.infinity);
    final status = dueAmount <= 0 ? 'paid' : 'pending';

    final sale = Sale(
      buyerId: buyerId,
      itemName: itemName,
      unitType: unitType,
      quantity: quantity,
      totalAmount: totalAmount,
      advancePaid: advancePaid,
      totalPaid: totalPaid,
      dueAmount: dueAmount,
      saleDate: saleDate,
      status: status,
      notes: notes,
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
    double quantity = 0,
    double totalAmount = 0,
    double advancePaid = 0,
    required DateTime saleDate,
    String? notes,
  }) async {
    final existingSale = await _repository.getById(saleId);
    if (existingSale == null) return;

    // Recalculate: total_paid = new advance + sum of existing payments
    final payments = await _paymentRepository.getBySaleId(saleId);
    final paymentsSum = payments.fold<double>(0, (sum, p) => sum + p.amount);
    final totalPaid = advancePaid + paymentsSum;
    final dueAmount = (totalAmount - totalPaid).clamp(0.0, double.infinity);
    final status = dueAmount <= 0 ? 'paid' : 'pending';

    final updatedSale = existingSale.copyWith(
      buyerId: buyerId,
      itemName: itemName,
      unitType: unitType,
      quantity: quantity,
      totalAmount: totalAmount,
      advancePaid: advancePaid,
      totalPaid: totalPaid,
      dueAmount: dueAmount,
      saleDate: saleDate,
      status: status,
      notes: notes,
      updatedAt: DateTime.now(),
    );

    await _repository.update(updatedSale);
  }

  /// Add a payment to a sale. Updates total_paid and due_amount.
  /// Auto-marks as paid if due reaches 0.
  Future<void> addPayment({
    required int saleId,
    required double amount,
    String? notes,
    DateTime? paymentDate,
  }) async {
    final sale = await _repository.getById(saleId);
    if (sale == null) return;

    // Insert payment record
    final payment = Payment(
      saleId: saleId,
      amount: amount,
      paymentDate: paymentDate ?? DateTime.now(),
      notes: notes,
    );
    await _paymentRepository.insert(payment);

    // Update sale totals
    final newTotalPaid = sale.totalPaid + amount;
    final newDue = (sale.totalAmount - newTotalPaid).clamp(0.0, double.infinity);
    final newStatus = newDue <= 0 ? 'paid' : 'pending';

    await _repository.updatePaymentTotals(
      saleId: saleId,
      totalPaid: newTotalPaid,
      dueAmount: newDue,
      status: newStatus,
    );
  }

  /// Mark a sale as complete (settled). Sets due to 0, status to paid.
  /// Does NOT change total_paid — it stays at whatever was actually paid.
  Future<void> markSaleAsComplete(int saleId, {String? notes}) async {
    await _repository.markAsPaid(saleId);
    // If there are settlement notes, update the sale notes
    if (notes != null && notes.trim().isNotEmpty) {
      final sale = await _repository.getById(saleId);
      if (sale != null) {
        final existingNotes = sale.notes ?? '';
        final separator = existingNotes.isNotEmpty ? '\n' : '';
        final updatedNotes = '$existingNotes${separator}Settlement: $notes';
        await _repository.update(sale.copyWith(
          notes: updatedNotes,
          updatedAt: DateTime.now(),
        ));
      }
    }
  }

  /// Delete a sale and all its associated payments.
  Future<void> deleteSale(int saleId) async {
    await _paymentRepository.deleteBySaleId(saleId);
    await _repository.delete(saleId);
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

  /// Get a single sale by id.
  Future<Sale?> getSaleById(int saleId) {
    return _repository.getById(saleId);
  }
}
