import '../models/item_entry.dart';
import '../repositories/item_repository.dart';

/// Business logic for the unified item list (names + price memory).
class ItemService {
  final ItemRepository _repository;

  ItemService(this._repository);

  Future<List<ItemEntry>> getAllItems() => _repository.getAll();

  Future<List<String>> getAllItemNames() => _repository.getAllNames();

  Future<double> getPriceForItem(String itemName) => _repository.getPrice(itemName);

  /// Save/update the unit price for an item. Ignored if price is 0 or less.
  Future<void> savePriceForItem(String itemName, double price) =>
      _repository.upsertPrice(itemName, price);

  Future<void> addCustomItem(String name, {double price = 0, String priceUnit = 'kg'}) =>
      _repository.addCustomItem(name, price: price, priceUnit: priceUnit);

  Future<void> updateItem(int id, {String? name, double? price, String? priceUnit}) =>
      _repository.updateItem(id, name: name, price: price, priceUnit: priceUnit);

  Future<void> reorderItems(List<int> orderedIds) =>
      _repository.reorderItems(orderedIds);

  Future<void> deleteItem(int id) => _repository.deleteItem(id);
}
