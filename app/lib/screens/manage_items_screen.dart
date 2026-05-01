import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item_entry.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// Screen to view, add, edit, reorder, and delete items and their unit prices.
class ManageItemsScreen extends ConsumerWidget {
  const ManageItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            tooltip: 'Add Item',
            onPressed: () => _showAddItemDialog(context, ref),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('No items yet.', style: TextStyle(fontSize: 18, color: AppTheme.textMedium)),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    const Icon(Icons.drag_handle, size: 18, color: AppTheme.textLight),
                    const SizedBox(width: 6),
                    const Text(
                      'Hold and drag to reorder',
                      style: TextStyle(fontSize: 13, color: AppTheme.textLight),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  itemCount: items.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex--;
                    final reordered = [...items];
                    final moved = reordered.removeAt(oldIndex);
                    reordered.insert(newIndex, moved);
                    final orderedIds = reordered.map((e) => e.id!).toList();
                    await ref.read(itemServiceProvider).reorderItems(orderedIds);
                    ref.invalidate(itemListProvider);
                  },
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      key: ValueKey(item.id),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ItemTile(
                        item: item,
                        onEdit: () => _showEditItemDialog(context, ref, item),
                        onDelete: item.isDefault
                            ? null
                            : () => _confirmDeleteItem(context, ref, item),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String selectedUnit = 'kg';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Item', style: TextStyle(fontSize: 22)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(fontSize: 18),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Item Name'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(
                        labelText: 'Unit Price ₹',
                        prefixText: '₹ ',
                        hintText: '0',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _PriceUnitToggle(
                    value: selectedUnit,
                    onChanged: (v) => setDialogState(() => selectedUnit = v),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(fontSize: 18)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && nameController.text.trim().isNotEmpty) {
      final price = double.tryParse(priceController.text) ?? 0;
      await ref.read(itemServiceProvider).addCustomItem(
            nameController.text.trim(),
            price: price,
            priceUnit: selectedUnit,
          );
      ref.invalidate(itemListProvider);
    }

    nameController.dispose();
    priceController.dispose();
  }

  void _showEditItemDialog(BuildContext context, WidgetRef ref, ItemEntry item) async {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(
      text: item.unitPrice > 0 ? item.unitPrice.toStringAsFixed(0) : '',
    );
    String selectedUnit = item.priceUnit;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Item', style: TextStyle(fontSize: 22)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(fontSize: 18),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Item Name'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(
                        labelText: 'Unit Price ₹',
                        prefixText: '₹ ',
                        hintText: '0',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _PriceUnitToggle(
                    value: selectedUnit,
                    onChanged: (v) => setDialogState(() => selectedUnit = v),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(fontSize: 18)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final newName = nameController.text.trim();
      final newPrice = double.tryParse(priceController.text);
      await ref.read(itemServiceProvider).updateItem(
            item.id!,
            name: newName.isNotEmpty ? newName : null,
            price: newPrice,
            priceUnit: selectedUnit,
          );
      ref.invalidate(itemListProvider);
    }

    nameController.dispose();
    priceController.dispose();
  }

  void _confirmDeleteItem(BuildContext context, WidgetRef ref, ItemEntry item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item?', style: TextStyle(fontSize: 22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Remove "${item.name}" from the item list?\n\nExisting sale records are not affected.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorRed,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Yes, Delete', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              autofocus: true,
              onPressed: () => Navigator.pop(ctx, false),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('No', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await ref.read(itemServiceProvider).deleteItem(item.id!);
      ref.invalidate(itemListProvider);
    }
  }
}

/// Small kg / piece toggle used inside dialogs.
class _PriceUnitToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _PriceUnitToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggle('kg'),
          _toggle('pc'),
        ],
      ),
    );
  }

  Widget _toggle(String label) {
    final selected = value == label;
    return GestureDetector(
      onTap: () => onChanged(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : AppTheme.primaryGreen,
          ),
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final ItemEntry item;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _ItemTile({required this.item, required this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final unitLabel = item.priceUnit == 'pc' ? 'piece' : 'kg';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.isDefault
              ? AppTheme.primaryGreen.withValues(alpha: 0.2)
              : AppTheme.textLight.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Drag handle
            const Icon(Icons.drag_handle, size: 22, color: AppTheme.textLight),
            const SizedBox(width: 8),
            // Default indicator dot
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isDefault
                    ? AppTheme.primaryGreen
                    : AppTheme.textLight.withValues(alpha: 0.4),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                  ),
                  if (item.unitPrice > 0)
                    Text(
                      '₹ ${item.unitPrice.toStringAsFixed(0)} / $unitLabel',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMedium),
                    )
                  else
                    const Text(
                      'No price set',
                      style: TextStyle(fontSize: 13, color: AppTheme.textLight),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: AppTheme.primaryGreen,
              onPressed: onEdit,
              tooltip: 'Edit',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppTheme.errorRed,
                onPressed: onDelete,
                tooltip: 'Delete',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              )
            else
              const SizedBox(width: 36),
          ],
        ),
      ),
    );
  }
}
