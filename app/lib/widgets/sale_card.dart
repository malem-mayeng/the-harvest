import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../theme/app_theme.dart';

/// A card widget to display a sale record with status indicator.
class SaleCard extends StatelessWidget {
  final Sale sale;
  final bool showBuyerName;
  final VoidCallback? onEdit;
  final VoidCallback? onMarkPaid;

  const SaleCard({
    super.key,
    required this.sale,
    this.showBuyerName = false,
    this.onEdit,
    this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isPending = sale.isPending;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: buyer name (optional) + status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showBuyerName && sale.buyerName != null)
                        Text(
                          sale.buyerName!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      Text(
                        dateFormat.format(sale.saleDate),
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textMedium,
                          fontWeight: showBuyerName ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(isPending),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Details grid
            Row(
              children: [
                Expanded(
                  child: _buildDetail('Item', sale.itemName),
                ),
                Expanded(
                  child: _buildDetail(
                    'Qty',
                    '${sale.quantity} ${sale.unitType}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDetail('Total', '₹${sale.totalAmount.toStringAsFixed(0)}'),
                ),
                Expanded(
                  child: _buildDetail('Advance', '₹${sale.advancePaid.toStringAsFixed(0)}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildDetail(
              'Due',
              '₹${sale.dueAmount.toStringAsFixed(0)}',
              valueColor: isPending ? AppTheme.pendingOrange : AppTheme.paidGreen,
              isBold: true,
            ),

            // Action buttons
            if (onEdit != null || (onMarkPaid != null && isPending)) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 20),
                      label: const Text('Edit', style: TextStyle(fontSize: 16)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  if (onEdit != null && onMarkPaid != null && isPending)
                    const SizedBox(width: 8),
                  if (onMarkPaid != null && isPending)
                    ElevatedButton.icon(
                      onPressed: onMarkPaid,
                      icon: const Icon(Icons.check_circle, size: 20),
                      label: const Text('Mark Paid'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isPending) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isPending
            ? AppTheme.pendingOrange.withValues(alpha: 0.12)
            : AppTheme.paidGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending ? AppTheme.pendingOrange : AppTheme.paidGreen,
          width: 1.5,
        ),
      ),
      child: Text(
        isPending ? 'PENDING' : 'PAID',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isPending ? AppTheme.pendingOrange : AppTheme.paidGreen,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildDetail(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppTheme.textLight),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
