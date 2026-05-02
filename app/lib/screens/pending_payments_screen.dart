import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/sale_card.dart';

/// Screen showing only unpaid/pending sale records.
class PendingPaymentsScreen extends ConsumerWidget {
  const PendingPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingSalesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Payments'),
      ),
      body: pendingAsync.when(
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
                onPressed: () => ref.invalidate(pendingSalesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (sales) {
          if (sales.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: AppTheme.successGreen.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'All Payments Clear!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No pending payments at the moment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Calculate total pending
          final totalDue = sales.fold<double>(0, (sum, s) => sum + s.dueAmount);

          return Column(
            children: [
              // Summary banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.pendingOrange.withValues(alpha: 0.08),
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.pendingOrange.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Pending',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textMedium,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹ ${totalDue.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.pendingOrange,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.pendingOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${sales.length} records',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.pendingOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Pending sales list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    return SaleCard(
                      sale: sale,
                      showBuyerName: true,
                      onAddPayment: () => _showAddPaymentDialog(context, ref, sale),
                      onMarkPaid: (notes) async {
                        await ref.read(saleServiceProvider).markSaleAsComplete(
                              sale.id!,
                              notes: notes,
                            );
                        ref.invalidate(pendingSalesProvider);
                        ref.invalidate(buyerListProvider);
                      },
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
                'Buyer: ${sale.buyerName ?? 'Unknown'}\nCurrent due: ₹${sale.dueAmount.toStringAsFixed(0)}',
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
        ref.invalidate(pendingSalesProvider);
        ref.invalidate(buyerListProvider);
      }
    }

    amountController.dispose();
    notesController.dispose();
  }

}
