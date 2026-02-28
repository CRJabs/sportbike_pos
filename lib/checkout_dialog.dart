import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'cart_provider.dart';
import 'database_service.dart';

class CheckoutDialog extends ConsumerStatefulWidget {
  const CheckoutDialog({super.key});

  @override
  ConsumerState<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends ConsumerState<CheckoutDialog> {
  String _selectedPaymentMethod = 'cash'; // Default payment method
  bool _isLoading = false;

  final currencyFormatter =
      NumberFormat.currency(symbol: '₱', decimalDigits: 2);

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);

    try {
      final cartItems = ref.read(cartProvider);
      final subtotal = ref.read(cartSubtotalProvider);
      final vat = ref.read(cartVatProvider);
      final grandTotal = ref.read(cartTotalProvider);

      // Call the Supabase RPC via our database service
      await ref.read(databaseProvider).checkout(
            subtotal: subtotal,
            vatAmount: vat,
            grandTotal: grandTotal,
            paymentType: _selectedPaymentMethod,
            cartItems: cartItems,
          );

      if (!mounted) return;

      // Success Reset Phase
      ref.invalidate(detailedBikesProvider); // Refresh the Motorcycles table
      ref.invalidate(
          detailedAccessoriesProvider); // Refresh the Accessories table
      ref.read(cartProvider.notifier).clearCart(); // 1. Empty the cart
      ref.invalidate(
          inventoryProvider); // 2. Force the grid to fetch fresh stock numbers

      Navigator.of(context).pop(true); // Close the dialog and return success
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Checkout failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final grandTotal = ref.watch(cartTotalProvider);

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Complete Payment',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // Total Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: const Color(0xFF252525),
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  const Text('Amount Due',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(currencyFormatter.format(grandTotal),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 36,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text('Payment Method',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Payment Options
            Row(
              children: [
                _buildPaymentOption('Cash', 'cash', Icons.money),
                const SizedBox(width: 12),
                _buildPaymentOption(
                    'Bank Transfer', 'bank_transfer', Icons.account_balance),
                const SizedBox(width: 12),
                _buildPaymentOption(
                    'Financing', 'financing', Icons.real_estate_agent),
              ],
            ),
            const SizedBox(height: 40),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm & Pay',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String label, String value, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPaymentMethod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : const Color(0xFF252525),
            border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  size: 28),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
