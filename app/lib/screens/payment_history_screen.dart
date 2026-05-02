import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/buyer.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// Screen showing payment history for a specific buyer.
/// Displays all payment transactions + initial advance payments, newest first.
class PaymentHistoryScreen extends ConsumerWidget {
  final Buyer buyer;

  const PaymentHistoryScreen({super.key, required this.buyer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentHistoryProvider(buyer.id!));
    final salesAsync = ref.watch(buyerSalesProvider(buyer.id!));
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('₹ History — ${buyer.buyerName}'),
      ),
      body: paymentsAsync.when(
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
                onPressed: () => ref.invalidate(paymentHistoryProvider(buyer.id!)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (payments) {
          // Also get sales to show advance payments as first entries
          return salesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            ),
            error: (error, _) => const Center(
              child: Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
            ),
            data: (sales) {
              // Build combined list: advances + payments
              final List<_HistoryEntry> entries = [];

              // Add advance payments from sales
              for (final sale in sales) {
                if (sale.advancePaid > 0) {
                  entries.add(_HistoryEntry(
                    date: sale.saleDate,
                    amount: sale.advancePaid,
                    type: 'Advance',
                    itemName: sale.itemName,
                    notes: null,
                  ));
                }
              }

              // Add subsequent payments
              for (final payment in payments) {
                entries.add(_HistoryEntry(
                  date: payment.paymentDate,
                  amount: payment.amount,
                  type: 'Payment',
                  itemName: payment.itemName ?? 'Unknown',
                  notes: payment.notes,
                ));
              }

              // Sort newest first
              entries.sort((a, b) => b.date.compareTo(a.date));

              if (entries.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
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
                          'No payment history yet',
                          style: TextStyle(fontSize: 20, color: AppTheme.textMedium),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Calculate total received
              final totalReceived = entries.fold<double>(
                0,
                (sum, e) => sum + e.amount,
              );

              return Column(
                children: [
                  // Summary banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.paidGreen.withValues(alpha: 0.08),
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.paidGreen.withValues(alpha: 0.2),
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
                              'Total Received',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.textMedium,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹ ${totalReceived.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.paidGreen,
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
                            color: AppTheme.paidGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${entries.length} transactions',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.paidGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Transaction list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final isAdvance = entry.type == 'Advance';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: isAdvance
                                  ? AppTheme.accentAmber.withValues(alpha: 0.15)
                                  : AppTheme.paidGreen.withValues(alpha: 0.15),
                              child: Icon(
                                isAdvance ? Icons.arrow_downward : Icons.payments,
                                color: isAdvance ? AppTheme.accentAmber : AppTheme.paidGreen,
                                size: 22,
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.type,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isAdvance ? AppTheme.accentAmber : AppTheme.paidGreen,
                                  ),
                                ),
                                Text(
                                  '₹${entry.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      entry.itemName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textMedium,
                                      ),
                                    ),
                                    Text(
                                      dateFormat.format(entry.date),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                                if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    entry.notes!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textMedium,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Internal helper class for combined payment history entries.
class _HistoryEntry {
  final DateTime date;
  final double amount;
  final String type; // 'Advance' or 'Payment'
  final String itemName;
  final String? notes;

  _HistoryEntry({
    required this.date,
    required this.amount,
    required this.type,
    required this.itemName,
    this.notes,
  });
}
