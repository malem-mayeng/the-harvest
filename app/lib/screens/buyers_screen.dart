import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import 'buyer_detail_screen.dart';

/// Screen showing the list of all buyers.
class BuyersScreen extends ConsumerWidget {
  const BuyersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buyersAsync = ref.watch(buyerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyers'),
      ),
      body: buyersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                const SizedBox(height: 12),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 18, color: AppTheme.textMedium),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(buyerListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (buyers) {
          if (buyers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 80,
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Buyers Yet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Buyers will appear here when you add a sale.',
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

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: buyers.length,
            itemBuilder: (context, index) {
              final buyer = buyers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.only(
                    left: 20,
                    top: 8,
                    bottom: 8,
                    right: 8,
                  ),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    child: Text(
                      buyer.buyerName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  title: Text(
                    buyer.buyerName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      buyer.buyerCode,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit buyer
                      IconButton(
                        icon: const Icon(Icons.edit, size: 22),
                        color: AppTheme.primaryGreen,
                        tooltip: 'Edit Name',
                        onPressed: () => _showEditBuyerDialog(context, ref, buyer),
                      ),
                      // Delete buyer
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 22),
                        color: AppTheme.errorRed,
                        tooltip: 'Delete Buyer',
                        onPressed: () => _confirmDeleteBuyer(context, ref, buyer),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppTheme.textLight,
                        size: 18,
                      ),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BuyerDetailScreen(buyer: buyer),
                      ),
                    );
                    // Refresh after returning
                    ref.invalidate(buyerListProvider);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditBuyerDialog(BuildContext context, WidgetRef ref, buyer) async {
    final controller = TextEditingController(text: buyer.buyerName);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Buyer Name', style: TextStyle(fontSize: 22)),
        content: TextField(
          controller: controller,
          style: const TextStyle(fontSize: 18),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Buyer Name',
            hintText: 'Enter new name',
          ),
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
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      await ref.read(buyerServiceProvider).updateBuyerName(
            buyer.id!,
            controller.text.trim(),
          );
      ref.invalidate(buyerListProvider);
    }

    controller.dispose();
  }

  void _confirmDeleteBuyer(BuildContext context, WidgetRef ref, buyer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppTheme.errorRed, size: 28),
            const SizedBox(width: 8),
            const Text('Delete Buyer?', style: TextStyle(fontSize: 22)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Delete "${buyer.buyerName}"?\n\n'
              'This will permanently delete ALL sales and payment records for this buyer.\n\n'
              'This action cannot be undone.',
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
      await ref.read(buyerServiceProvider).deleteBuyerWithSales(buyer.id!);
      ref.invalidate(buyerListProvider);
      ref.invalidate(pendingSalesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${buyer.buyerName} deleted',
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: AppTheme.textMedium,
          ),
        );
      }
    }
  }
}
