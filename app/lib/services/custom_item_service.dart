import '../repositories/custom_item_repository.dart';

/// Business logic for custom item operations.
class CustomItemService {
  final CustomItemRepository _repository;

  CustomItemService(this._repository);

  /// Add a custom item name (ignores duplicates).
  Future<void> addItem(String name) async {
    if (name.trim().isEmpty) return;
    await _repository.insert(name.trim());
  }

  /// Get all custom item names.
  Future<List<String>> getAllItems() {
    return _repository.getAll();
  }

  /// Delete all custom items (reset to defaults: Fish, Vegetables).
  Future<void> resetToDefaults() async {
    await _repository.deleteAll();
  }
}
