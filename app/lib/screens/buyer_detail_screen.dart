import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/buyer.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/sale_card.dart';
import 'add_sale_screen.dart';

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
                Column(
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
                      onMarkPaid: sale.isPending
                          ? () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text(
                                    'Mark as Paid?',
                                    style: TextStyle(fontSize: 22),
                                  ),
                                  content: Text(
                                    'Mark ₹${sale.dueAmount.toStringAsFixed(0)} as fully paid?',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel', style: TextStyle(fontSize: 18)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.successGreen,
                                      ),
                                      child: const Text('Yes, Paid', style: TextStyle(fontSize: 18)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref
                                    .read(saleServiceProvider)
                                    .markSaleAsPaid(sale.id!);
                                ref.invalidate(buyerSalesProvider(buyer.id!));
                                ref.invalidate(pendingSalesProvider);
                              }
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
}
