import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/buyer.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/sale_card.dart';
import 'add_sale_screen.dart';
import 'payment_history_screen.dart';

/// Screen showing all sales records for a specific buyer.
class BuyerDetailScreen extends ConsumerWidget {
  final Buyer buyer;

  const BuyerDetailScreen({super.key, required this.buyer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(buyerSalesProvider(buyer.id!));

    return Scaffold(
      appBar: AppBar(
        title: Text(buyer.buyerName),
      ),
      body: Column(
        children: [
          // Buyer info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.08),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  child: Text(
                    buyer.buyerName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        buyer.buyerName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          buyer.buyerCode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Payment history button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentHistoryScreen(buyer: buyer),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long, size: 20),
                  label: const Text('₹ History'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),

          // Sales list
          Expanded(
            child: salesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(buyerSalesProvider(buyer.id!)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (sales) {
                if (sales.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: AppTheme.textLight.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No sales records yet',
                          style: TextStyle(
                            fontSize: 20,
                            color: AppTheme.textMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    return SaleCard(
                      sale: sale,
                      onEdit: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddSaleScreen(existingSale: sale),
                          ),
                        );
                        if (result == true) {
                          ref.invalidate(buyerSalesProvider(buyer.id!));
                          ref.invalidate(pendingSalesProvider);
                        }
                      },
                      onDelete: () => _confirmDeleteSale(context, ref, sale),
                      onAddPayment: sale.isPending
                          ? () => _showAddPaymentDialog(context, ref, sale)
                          : null,
                      onMarkPaid: sale.isPending
                          ? (notes) async {
                              await ref.read(saleServiceProvider).markSaleAsComplete(
                                    sale.id!,
                                    notes: notes,
                                  );
                              ref.invalidate(buyerSalesProvider(buyer.id!));
                              ref.invalidate(pendingSalesProvider);
                            }
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSale(BuildContext context, WidgetRef ref, sale) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Sale?', style: TextStyle(fontSize: 22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Delete this sale record? This cannot be undone.',
              style: TextStyle(fontSize: 18),
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
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('No', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await ref.read(saleServiceProvider).deleteSale(sale.id!);
      ref.invalidate(buyerSalesProvider(buyer.id!));
      ref.invalidate(pendingSalesProvider);
    }
  }

  void _showAddPaymentDialog(BuildContext context, WidgetRef ref, sale) async {
    final amountController = TextEditingController(
      text: sale.dueAmount.toStringAsFixed(0),
    );
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Payment', style: TextStyle(fontSize: 22)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current due: ₹${sale.dueAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 16, color: AppTheme.textMedium),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Amount Received',
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'e.g., Cash payment',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Record Payment', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final amount = double.tryParse(amountController.text) ?? 0;
      if (amount > 0) {
        final notes = notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim();
        await ref.read(saleServiceProvider).addPayment(
              saleId: sale.id!,
              amount: amount,
              notes: notes,
            );
        ref.invalidate(buyerSalesProvider(buyer.id!));
        ref.invalidate(pendingSalesProvider);
        ref.invalidate(paymentHistoryProvider(buyer.id!));
      }
    }

    amountController.dispose();
    notesController.dispose();
  }

}
