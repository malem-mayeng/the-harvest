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
  String _selectedItem = 'Fish';
  String _customItem = '';
  String _selectedUnitType = 'count';
  final _quantityController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _advancePaidController = TextEditingController();
  double _dueAmount = 0;
  bool _isSaving = false;

  final List<String> _items = ['Fish', 'Vegetables', 'Other'];

  bool get _isEditing => widget.existingSale != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFromExisting();
    } else {
      _saleDate = DateTime.now();
    }
  }

  void _populateFromExisting() {
    final sale = widget.existingSale!;
    _saleDate = sale.saleDate;

    if (_items.contains(sale.itemName)) {
      _selectedItem = sale.itemName;
    } else {
      _selectedItem = 'Other';
      _customItem = sale.itemName;
    }

    _selectedUnitType = sale.unitType;
    _quantityController.text = sale.quantity.toString();
    _totalAmountController.text = sale.totalAmount.toStringAsFixed(0);
    _advancePaidController.text = sale.advancePaid.toStringAsFixed(0);
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
    super.dispose();
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
    if (_selectedBuyer == null && _newBuyerName.trim().isEmpty) {
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

      // Get or create buyer
      final buyer = _selectedBuyer ?? await buyerService.createBuyer(_newBuyerName);

      // Determine item name
      final itemName = _selectedItem == 'Other' ? _customItem.trim() : _selectedItem;

      if (_isEditing) {
        await saleService.editSale(
          saleId: widget.existingSale!.id!,
          buyerId: buyer.id!,
          itemName: itemName,
          unitType: _selectedUnitType,
          quantity: double.parse(_quantityController.text),
          totalAmount: double.parse(_totalAmountController.text),
          advancePaid: double.tryParse(_advancePaidController.text) ?? 0,
          saleDate: _saleDate,
        );
      } else {
        await saleService.createSale(
          buyerId: buyer.id!,
          itemName: itemName,
          unitType: _selectedUnitType,
          quantity: double.parse(_quantityController.text),
          totalAmount: double.parse(_totalAmountController.text),
          advancePaid: double.tryParse(_advancePaidController.text) ?? 0,
          saleDate: _saleDate,
        );
      }

      // Invalidate providers to refresh lists
      ref.invalidate(buyerListProvider);
      ref.invalidate(pendingSalesProvider);
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
            DropdownButtonFormField<String>(
              value: _selectedItem,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.inventory_2, size: 24),
              ),
              style: const TextStyle(fontSize: 18, color: AppTheme.textDark),
              items: _items.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedItem = value!);
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
                    label: 'Count',
                    icon: Icons.numbers,
                    isSelected: _selectedUnitType == 'count',
                    onTap: () => setState(() => _selectedUnitType = 'count'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _UnitToggle(
                    label: 'Weight',
                    icon: Icons.scale,
                    isSelected: _selectedUnitType == 'weight',
                    onTap: () => setState(() => _selectedUnitType = 'weight'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Quantity ───────────────────────────
            const _SectionLabel('Quantity'),
            TextFormField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.production_quantity_limits, size: 24),
                suffixText: _selectedUnitType == 'weight' ? 'kg' : 'pcs',
                suffixStyle: const TextStyle(fontSize: 16, color: AppTheme.textMedium),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Enter quantity';
                if (double.tryParse(val) == null || double.parse(val) <= 0) {
                  return 'Enter valid quantity';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // ── Total Amount ───────────────────────
            const _SectionLabel('Total Amount (₹)'),
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
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Enter total amount';
                if (double.tryParse(val) == null || double.parse(val) <= 0) {
                  return 'Enter valid amount';
                }
                return null;
              },
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
