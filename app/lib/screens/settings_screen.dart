import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// Settings screen with app configuration options.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Reset Item List
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.pendingOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.restart_alt,
                  color: AppTheme.pendingOrange,
                  size: 28,
                ),
              ),
              title: const Text(
                'Reset Item List',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Remove all custom items. Revert to defaults (Fish, Vegetables).',
                  style: TextStyle(fontSize: 14, color: AppTheme.textMedium),
                ),
              ),
              onTap: () => _confirmResetItems(context, ref),
            ),
          ),

          const SizedBox(height: 16),

          // Export (coming soon)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.textLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.file_download_outlined,
                  color: AppTheme.textLight,
                  size: 28,
                ),
              ),
              title: const Text(
                'Export Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textLight,
                ),
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Coming soon',
                  style: TextStyle(fontSize: 14, color: AppTheme.textLight),
                ),
              ),
              enabled: false,
            ),
          ),

          const SizedBox(height: 40),

          // App version info
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.agriculture,
                    size: 36,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'The Harvest',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreenDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Version 2.0.0',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textMedium,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sales Record Book for Farmers',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmResetItems(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Item List?', style: TextStyle(fontSize: 22)),
        content: const Text(
          'This will remove all custom items you\'ve added. '
          'The dropdown will revert to defaults: Fish, Vegetables.\n\n'
          'Existing sale records are not affected.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pendingOrange),
            child: const Text('Reset', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(customItemServiceProvider).resetToDefaults();
      ref.invalidate(customItemListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item list reset to defaults', style: TextStyle(fontSize: 16)),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    }
  }
}
