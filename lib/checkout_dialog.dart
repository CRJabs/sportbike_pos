import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
// import 'package:printing/printing.dart';
// import 'package:pdf/pdf.dart';

import 'models.dart';
import 'local_database_service.dart';
// import 'receipt_generator.dart';
import 'database_service.dart';

class CheckoutDialog extends ConsumerStatefulWidget {
  final List<CartItem> items;
  const CheckoutDialog({super.key, required this.items});

  @override
  ConsumerState<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends ConsumerState<CheckoutDialog> {
  String _selectedMethod = 'CASH';
  final TextEditingController _cashGivenController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _cashGivenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    double subtotal = 0;
    for (var item in widget.items) {
      subtotal += (item.product.price * item.quantity);
    }

    double vatAmount = subtotal * 0.12;
    double grandTotal = subtotal + vatAmount;
    double cashGiven = double.tryParse(_cashGivenController.text) ?? 0.0;
    double change = cashGiven - grandTotal;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text('Complete Checkout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Order Summary',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10)),
                child: Column(
                  children: widget.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(
                                  '${item.quantity}x ${item.product.name}',
                                  style: const TextStyle(color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                          Text(
                              currencyFormatter
                                  .format(item.product.price * item.quantity),
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Subtotal:', style: TextStyle(color: Colors.grey)),
                Text(currencyFormatter.format(subtotal),
                    style: const TextStyle(color: Colors.white))
              ]),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('VAT (12%):', style: TextStyle(color: Colors.grey)),
                Text(currencyFormatter.format(vatAmount),
                    style: const TextStyle(color: Colors.white))
              ]),
              const Divider(color: Colors.white10, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('GRAND TOTAL:',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  Text(currencyFormatter.format(grandTotal),
                      style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Payment Method',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMethod,
                dropdownColor: const Color(0xFF252525),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white10)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: const [
                  DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                  DropdownMenuItem(
                      value: 'BANK_TRANSFER', child: Text('Bank Transfer')),
                  DropdownMenuItem(
                      value: 'INHOUSE_FINANCING',
                      child: Text('In-House Financing')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedMethod = value;
                      _cashGivenController.clear();
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              if (_selectedMethod == 'CASH') ...[
                TextField(
                  controller: _cashGivenController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Cash Given (₱)',
                      labelStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white10))),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Change Due:',
                        style: TextStyle(color: Colors.grey)),
                    Text(
                        change >= 0
                            ? currencyFormatter.format(change)
                            : '₱0.00',
                        style: TextStyle(
                            color: change >= 0
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          onPressed: _isProcessing || (_selectedMethod == 'CASH' && change < 0)
              ? null
              : () async {
                  setState(() => _isProcessing = true);

                  try {
                    // 1. Save directly to local SQLite Database
                    await LocalDatabaseService().saveOfflineCheckout(
                      subtotal: subtotal,
                      vatAmount: vatAmount,
                      grandTotal: grandTotal,
                      paymentType: _selectedMethod,
                      cartItems: widget.items,
                    );

                    if (!context.mounted) return;

                    // // 2. Trigger the native Windows Print Menu
                    // await Printing.layoutPdf(
                    //   name: 'Receipt_${DateTime.now().millisecondsSinceEpoch}',
                    //   onLayout: (PdfPageFormat format) async =>
                    //       ReceiptGenerator.generateReceipt(
                    //     cartItems: widget.items,
                    //     subtotal: subtotal,
                    //     vat: vatAmount,
                    //     total: grandTotal,
                    //     paymentType: _selectedMethod,
                    //   ),
                    // );

                    if (!context.mounted) return;

                    // 3. Refresh ALL tables so POS, Inventory, and Dashboard update instantly
                    ref.invalidate(inventoryProvider);
                    ref.invalidate(detailedBikesProvider);
                    ref.invalidate(detailedAccessoriesProvider);
                    ref.invalidate(dashboardStatsProvider);
                    ref.invalidate(recentTransactionsProvider);

                    Navigator.of(context).pop(true);
                  } catch (e) {
                    setState(() => _isProcessing = false);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Checkout Error: $e'),
                        backgroundColor: Colors.red));
                  }
                },
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Confirm Payment',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
