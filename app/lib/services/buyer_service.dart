import '../models/buyer.dart';
import '../repositories/buyer_repository.dart';

/// Business logic for buyer operations.
class BuyerService {
  final BuyerRepository _repository;

  BuyerService(this._repository);

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
}
