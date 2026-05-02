import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import 'manage_items_screen.dart';

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
          // Manage Items
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.list_alt_rounded,
                  color: AppTheme.primaryGreen,
                  size: 28,
                ),
              ),
              title: const Text(
                'Manage Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Add, remove or update items and their unit prices.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textMedium),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppTheme.textLight),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageItemsScreen()),
              ),
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
                const SizedBox(height: 8),
                const Text(
                  'Crafted with ♥ by Malem Mayengbam',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
