import '../models/buyer.dart';
import '../repositories/buyer_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/sale_repository.dart';

/// Business logic for buyer operations.
class BuyerService {
  final BuyerRepository _repository;
  final SaleRepository _saleRepository;
  final PaymentRepository _paymentRepository;

  BuyerService(this._repository, this._saleRepository, this._paymentRepository);

  /// Get all buyers.
  Future<List<Buyer>> getAllBuyers() {
    return _repository.getAll();
  }

  /// Search buyers by name.
  Future<List<Buyer>> searchBuyers(String query) {
    if (query.trim().isEmpty) return _repository.getAll();
    return _repository.searchByName(query);
  }

  /// Create a new buyer with auto-generated code.
  /// Returns the newly created Buyer with its id.
  Future<Buyer> createBuyer(String name) async {
    final code = await _repository.getNextBuyerCode();
    final buyer = Buyer(
      buyerCode: code,
      buyerName: name.trim(),
    );
    final id = await _repository.insert(buyer);
    return buyer.copyWith(id: id);
  }

  /// Get a buyer by id.
  Future<Buyer?> getBuyerById(int id) {
    return _repository.getById(id);
  }

  /// Update a buyer's name.
  Future<void> updateBuyerName(int buyerId, String newName) async {
    await _repository.updateName(buyerId, newName);
  }

  /// Delete a buyer and all associated sales and payments.
  /// Order: payments → sales → buyer (to respect foreign keys).
  Future<void> deleteBuyerWithSales(int buyerId) async {
    await _paymentRepository.deleteByBuyerId(buyerId);
    await _saleRepository.deleteByBuyerId(buyerId);
    await _repository.delete(buyerId);
  }
}
