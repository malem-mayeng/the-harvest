import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/buyer.dart';
import '../models/sale.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/buyer_search_field.dart';

/// Screen for adding a new sale or editing an existing one.
class AddSaleScreen extends ConsumerStatefulWidget {
  /// If provided, the form is in edit mode for this sale.
  final Sale? existingSale;

  const AddSaleScreen({super.key, this.existingSale});

  @override
  ConsumerState<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends ConsumerState<AddSaleScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form state
  Buyer? _selectedBuyer;
  String _newBuyerName = '';
  late DateTime _saleDate;
  String? _selectedItem;
  String _customItem = '';
  String _selectedUnitType = 'weight';
  final _quantityController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _advancePaidController = TextEditingController();
  final _notesController = TextEditingController();
  final _kgController = TextEditingController();
  final _gramsController = TextEditingController();
  final _unitPriceController = TextEditingController();
  double _dueAmount = 0;
  bool _isSaving = false;

  // Default items + dynamic custom items
  List<String> _allItems = ['Grass', 'Rohu', 'Silver', 'Hurubai', 'Common', 'Ukabi', 'Ngakup', 'Vegetables', 'Other'];

  bool get _isEditing => widget.existingSale != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFromExisting();
    } else {
      _saleDate = DateTime.now();
    }
    _loadItems();
  }

  Future<void> _loadItems() async {
    final names = await ref.read(itemServiceProvider).getAllItemNames();
    if (mounted) {
      setState(() {
        _allItems = [...names, 'Other'];
        if (_isEditing) {
          final sale = widget.existingSale!;
          if (_allItems.contains(sale.itemName)) {
            _selectedItem = sale.itemName;
          } else {
            _selectedItem = 'Other';
          }
        }
      });
    }
  }

  void _populateFromExisting() {
    final sale = widget.existingSale!;
    _saleDate = sale.saleDate;

    // Check if item is in defaults first; custom items loaded async
    const defaultItems = ['Grass', 'Rohu', 'Silver', 'Hurubai', 'Common', 'Ukabi', 'Ngakup', 'Vegetables'];
    if (defaultItems.contains(sale.itemName)) {
      _selectedItem = sale.itemName;
    } else if (sale.itemName == 'Other') {
      _selectedItem = 'Other';
    } else {
      _selectedItem = 'Other';
      _customItem = sale.itemName;
    }

    _selectedUnitType = sale.unitType;
    if (sale.quantity > 0) {
      if (sale.unitType == 'weight') {
        final kg = sale.quantity.floor();
        final grams = ((sale.quantity - kg) * 1000).round();
        _kgController.text = kg.toString();
        if (grams > 0) _gramsController.text = grams.toString();
      } else {
        _quantityController.text = sale.quantity.toString();
      }
    }
    if (sale.totalAmount > 0) {
      _totalAmountController.text = sale.totalAmount.toStringAsFixed(0);
    }
    if (sale.advancePaid > 0) {
      _advancePaidController.text = sale.advancePaid.toStringAsFixed(0);
    }
    _notesController.text = sale.notes ?? '';
    _dueAmount = sale.dueAmount;

    // Load buyer info
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final buyerService = ref.read(buyerServiceProvider);
      final buyer = await buyerService.getBuyerById(sale.buyerId);
      if (buyer != null && mounted) {
        setState(() => _selectedBuyer = buyer);
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _totalAmountController.dispose();
    _advancePaidController.dispose();
    _notesController.dispose();
    _kgController.dispose();
    _gramsController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  /// Called whenever unit price or quantity changes — fills Total Amount.
  void _calculateTotal() {
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0;
    if (unitPrice <= 0) {
      _calculateDue();
      return;
    }
    final double quantity;
    if (_selectedUnitType == 'weight') {
      final kg = double.tryParse(_kgController.text) ?? 0;
      final grams = double.tryParse(_gramsController.text) ?? 0;
      quantity = kg + grams / 1000;
    } else {
      quantity = double.tryParse(_quantityController.text) ?? 0;
    }
    if (quantity > 0) {
      final total = unitPrice * quantity;
      _totalAmountController.text = total.toStringAsFixed(0);
    }
    _calculateDue();
  }

  void _calculateDue() {
    final total = double.tryParse(_totalAmountController.text) ?? 0;
    final advance = double.tryParse(_advancePaidController.text) ?? 0;
    setState(() {
      _dueAmount = (total - advance).clamp(0, double.infinity);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryGreen,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _saleDate = picked);
    }
  }

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate buyer
    if (!_isEditing && _selectedBuyer == null && _newBuyerName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or enter a buyer name', style: TextStyle(fontSize: 16)),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final buyerService = ref.read(buyerServiceProvider);
      final saleService = ref.read(saleServiceProvider);
      final itemService = ref.read(itemServiceProvider);

      // Get or create buyer
      final buyer = _isEditing
          ? _selectedBuyer!
          : (_selectedBuyer ?? await buyerService.createBuyer(_newBuyerName));

      // Determine item name
      final itemName = _selectedItem == 'Other' ? _customItem.trim() : (_selectedItem ?? '');

      // Save custom item if "Other" was used
      if (_selectedItem == 'Other' && itemName.isNotEmpty) {
        await itemService.addCustomItem(itemName);
        ref.invalidate(itemListProvider);
      }

      // Persist unit price if provided (never overwrites with 0)
      final unitPrice = double.tryParse(_unitPriceController.text) ?? 0;
      if (unitPrice > 0 && itemName.isNotEmpty) {
        await itemService.savePriceForItem(itemName, unitPrice);
      }

      final double quantity;
      if (_selectedUnitType == 'weight') {
        final kg = double.tryParse(_kgController.text) ?? 0;
        final grams = double.tryParse(_gramsController.text) ?? 0;
        quantity = kg + grams / 1000;
      } else {
        quantity = double.tryParse(_quantityController.text) ?? 0;
      }
      final totalAmount = double.tryParse(_totalAmountController.text) ?? 0;
      final advancePaid = double.tryParse(_advancePaidController.text) ?? 0;
      final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

      if (_isEditing) {
        await saleService.editSale(
          saleId: widget.existingSale!.id!,
          buyerId: buyer.id!,
          itemName: itemName,
          unitType: _selectedUnitType,
          quantity: quantity,
          totalAmount: totalAmount,
          advancePaid: advancePaid,
          saleDate: _saleDate,
          notes: notes,
        );
      } else {
        await saleService.createSale(
          buyerId: buyer.id!,
          itemName: itemName,
          unitType: _selectedUnitType,
          quantity: quantity,
          totalAmount: totalAmount,
          advancePaid: advancePaid,
          saleDate: _saleDate,
          notes: notes,
        );
      }

      // Invalidate providers to refresh lists
      ref.invalidate(buyerListProvider);
      ref.invalidate(pendingSalesProvider);
      ref.invalidate(itemListProvider);
      if (_selectedBuyer != null) {
        ref.invalidate(buyerSalesProvider(_selectedBuyer!.id!));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Sale updated!' : 'Sale saved!',
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: const TextStyle(fontSize: 16)),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Sale' : 'Add Sale'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Buyer ──────────────────────────────
            const _SectionLabel('Buyer'),
            if (_isEditing)
              // Read-only buyer name in edit mode
              InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person, size: 24),
                  filled: true,
                ),
                child: Text(
                  _selectedBuyer?.buyerName ?? 'Loading...',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textMedium,
                  ),
                ),
              )
            else
              BuyerSearchField(
                initialBuyer: _selectedBuyer,
                onBuyerSelected: (buyer) {
                  setState(() {
                    _selectedBuyer = buyer;
                    _newBuyerName = '';
                  });
                },
                onNewBuyerName: (name) {
                  setState(() {
                    _selectedBuyer = null;
                    _newBuyerName = name;
                  });
                },
              ),

            const SizedBox(height: 20),

            // ── Date ───────────────────────────────
            const _SectionLabel('Date'),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today, size: 24),
                ),
                child: Text(
                  dateFormat.format(_saleDate),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Item ───────────────────────────────
            const _SectionLabel('Item Sold'),
            Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final menuWidth = screenWidth * 0.70;
                // Center menu under the full-width button (button = screenWidth - 40 padding)
                final buttonWidth = screenWidth - 40;
                final menuOffsetX = (buttonWidth - menuWidth) / 2;
                return DropdownButtonFormField2<String>(
                  value: _selectedItem,
                  hint: const Text('Select item', style: TextStyle(fontSize: 18, color: AppTheme.textLight)),
                  style: const TextStyle(fontSize: 18, color: AppTheme.textDark),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.inventory_2, size: 24),
                  ),
                  items: _allItems.map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 18)),
                  )).toList(),
                  onChanged: (value) {
                    setState(() => _selectedItem = value);
                    if (value != null && value != 'Other') {
                      ref.read(itemServiceProvider).getPriceForItem(value).then((price) {
                        if (mounted) {
                          _unitPriceController.text = price > 0 ? price.toStringAsFixed(0) : '';
                          _calculateTotal();
                        }
                      });
                    } else {
                      _unitPriceController.clear();
                      _calculateTotal();
                    }
                  },
                  validator: (val) => val == null ? 'Please select an item' : null,
                  dropdownStyleData: DropdownStyleData(
                    width: menuWidth,
                    offset: Offset(menuOffsetX, 0),
                    maxHeight: 380,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    scrollbarTheme: ScrollbarThemeData(
                      radius: const Radius.circular(8),
                      thumbVisibility: WidgetStateProperty.all(true),
                    ),
                  ),
                  menuItemStyleData: const MenuItemStyleData(
                    height: 52,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                  ),
                );
              },
            ),

            if (_selectedItem == 'Other') ...[
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _customItem,
                onChanged: (val) => _customItem = val,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Custom Item Name',
                  hintText: 'Enter item name',
                ),
                validator: (val) {
                  if (_selectedItem == 'Other' &&
                      (val == null || val.trim().isEmpty)) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 20),

            // ── Unit Type ──────────────────────────
            const _SectionLabel('Unit Type'),
            Row(
              children: [
                Expanded(
                  child: _UnitToggle(
                    label: 'Weight',
                    icon: Icons.scale,
                    isSelected: _selectedUnitType == 'weight',
                    onTap: () => setState(() => _selectedUnitType = 'weight'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _UnitToggle(
                    label: 'Count',
                    icon: Icons.numbers,
                    isSelected: _selectedUnitType == 'count',
                    onTap: () => setState(() => _selectedUnitType = 'count'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Quantity ────────────────────────────
            const _SectionLabel('Quantity'),
            if (_selectedUnitType == 'weight')
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _kgController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (_) => _calculateTotal(),
                            style: const TextStyle(fontSize: 20),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.scale, size: 24),
                              hintText: '0',
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 8, top: 4),
                          child: Text('kg', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textMedium)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _gramsController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (_) => _calculateTotal(),
                            style: const TextStyle(fontSize: 20),
                            decoration: const InputDecoration(
                              hintText: '0',
                            ),
                            validator: (val) {
                              final g = int.tryParse(val ?? '');
                              if (g != null && g > 999) return 'Max 999g';
                              return null;
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 8, top: 4),
                          child: Text('g', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textMedium)),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                onChanged: (_) => _calculateTotal(),
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.production_quantity_limits, size: 24),
                  suffixText: 'pcs',
                  suffixStyle: TextStyle(fontSize: 16, color: AppTheme.textMedium),
                  hintText: '0',
                ),
              ),

            const SizedBox(height: 20),

            // ── Unit Price ────────────────────────────
            const _SectionLabel('Unit Price ₹'),
            TextFormField(
              controller: _unitPriceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              onChanged: (_) => _calculateTotal(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.price_change_outlined, size: 24),
                prefixText: '₹ ',
                prefixStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                hintText: 'Per kg / per piece',
              ),
            ),

            const SizedBox(height: 20),

            // ── Total Amount ─────────────────────────
            const _SectionLabel('Total Amount ₹'),
            TextFormField(
              controller: _totalAmountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              onChanged: (_) => _calculateDue(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.currency_rupee, size: 24),
                prefixText: '₹ ',
                prefixStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                hintText: 'Leave blank if unknown',
              ),
              // No validator — field is optional
            ),

            const SizedBox(height: 20),

            // ── Advance Paid ───────────────────────
            const _SectionLabel('Advance Paid (₹)'),
            TextFormField(
              controller: _advancePaidController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              onChanged: (_) => _calculateDue(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.payments, size: 24),
                prefixText: '₹ ',
                prefixStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                hintText: '0',
              ),
            ),

            const SizedBox(height: 20),

            // ── Due Amount (computed) ──────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _dueAmount > 0
                    ? AppTheme.pendingOrange.withValues(alpha: 0.1)
                    : AppTheme.successGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _dueAmount > 0 ? AppTheme.pendingOrange : AppTheme.successGreen,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Due Amount',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    '₹ ${_dueAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _dueAmount > 0 ? AppTheme.pendingOrange : AppTheme.successGreen,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Notes ──────────────────────────────
            const _SectionLabel('Notes'),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.notes, size: 24),
                ),
                hintText: 'e.g., Mixed veg — cabbage, beans, carrots',
                hintStyle: TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 32),

            // ── Buttons ────────────────────────────
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSale,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, size: 24),
              label: Text(_isEditing ? 'Update Record' : 'Save Record'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// Section label for form fields.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryGreenDark,
        ),
      ),
    );
  }
}

/// Toggle button for unit type selection.
class _UnitToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitToggle({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.textLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textMedium,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
