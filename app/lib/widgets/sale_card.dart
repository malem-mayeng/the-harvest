import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../theme/app_theme.dart';

/// A card widget to display a sale record with status indicator.
class SaleCard extends StatelessWidget {
  final Sale sale;
  final bool showBuyerName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMarkPaid;
  final VoidCallback? onAddPayment;

  const SaleCard({
    super.key,
    required this.sale,
    this.showBuyerName = false,
    this.onEdit,
    this.onDelete,
    this.onMarkPaid,
    this.onAddPayment,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isPending = sale.isPending;

    return Card(
      elevation: 3,
      shadowColor: AppTheme.cardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPending
              ? AppTheme.pendingOrange.withValues(alpha: 0.2)
              : AppTheme.paidGreen.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
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
                    sale.quantity > 0
                        ? '${sale.quantity} ${sale.unitType}'
                        : '—',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDetail(
                    'Total',
                    sale.totalAmount > 0
                        ? '₹${sale.totalAmount.toStringAsFixed(0)}'
                        : '—',
                  ),
                ),
                Expanded(
                  child: _buildDetail('Advance', '₹${sale.advancePaid.toStringAsFixed(0)}'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Due row with Pay button inline
            Row(
              children: [
                Expanded(
                  child: _buildDetail(
                    'Paid',
                    '₹${sale.totalPaid.toStringAsFixed(0)}',
                    valueColor: AppTheme.paidGreen,
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _buildDetail(
                          'Due',
                          '₹${sale.dueAmount.toStringAsFixed(0)}',
                          valueColor: isPending ? AppTheme.pendingOrange : AppTheme.paidGreen,
                          isBold: true,
                        ),
                      ),
                      // Pay button with border
                      if (onAddPayment != null && isPending)
                        SizedBox(
                          height: 34,
                          child: OutlinedButton.icon(
                            onPressed: onAddPayment,
                            icon: const Icon(Icons.payments, size: 16),
                            label: const Text('Pay', style: TextStyle(fontSize: 14)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1565C0),
                              side: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Notes snippet
            if (sale.notes != null && sale.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.notes, size: 16, color: AppTheme.textLight),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      sale.notes!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMedium,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Action buttons: Edit (left) | All Clear (center) | Delete (right)
            if (onEdit != null || onDelete != null ||
                (onMarkPaid != null && isPending)) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Edit — far left
                  if (onEdit != null)
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 20),
                      label: const Text('Edit', style: TextStyle(fontSize: 16)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  const Spacer(),
                  // All Clear — center
                  if (onMarkPaid != null && isPending)
                    SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmAllClear(context),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('All Clear'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Delete — far right
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 22),
                      color: AppTheme.errorRed,
                      tooltip: 'Delete',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Confirmation popup for "All Clear" — Yes is focused/prominent.
  void _confirmAllClear(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as All Clear?', style: TextStyle(fontSize: 22)),
        content: Text(
          'Settle this payment?\nRemaining due: ₹${sale.dueAmount.toStringAsFixed(0)}\n\nThis will mark the sale as fully paid.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            autofocus: true,
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
            child: const Text('Yes, All Clear', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      onMarkPaid?.call();
    }
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
