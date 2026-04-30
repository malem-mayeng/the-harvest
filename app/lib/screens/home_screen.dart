import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/big_button.dart';
import 'add_sale_screen.dart';
import 'buyers_screen.dart';
import 'pending_payments_screen.dart';

/// Home screen with 3 large navigation buttons.
/// Designed for simple, one-hand operation by elderly users.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // App header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.agriculture,
                      size: 56,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'The Harvest',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreenDark,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sales Record Book',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textMedium,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Navigation buttons
            BigButton(
              label: 'Add Sale',
              icon: Icons.add_shopping_cart,
              backgroundColor: AppTheme.primaryGreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddSaleScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            BigButton(
              label: 'Buyers',
              icon: Icons.people,
              backgroundColor: const Color(0xFF1565C0),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BuyersScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            BigButton(
              label: 'Pending Payments',
              icon: Icons.access_time_filled,
              backgroundColor: AppTheme.pendingOrange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PendingPaymentsScreen()),
                );
              },
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
