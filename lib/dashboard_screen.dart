import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final transactionsAsync = ref.watch(recentTransactionsProvider);

    final currencyFormatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormatter = DateFormat('MMM dd, yyyy - hh:mm a');

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analytics Dashboard',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const Text('Real-time overview of today\'s performance',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),

          // --- KPI CARDS ROW ---
          statsAsync.when(
            loading: () => const SizedBox(
                height: 120,
                child: Center(
                    child: CircularProgressIndicator(color: Colors.red))),
            error: (e, _) => SizedBox(
                height: 120,
                child: Center(
                    child: Text('Error loading stats: $e',
                        style: const TextStyle(color: Colors.red)))),
            data: (stats) {
              return Row(
                children: [
                  _buildKpiCard(
                      context,
                      'Revenue Today',
                      currencyFormatter.format(stats['revenueToday']),
                      Icons.attach_money,
                      Colors.greenAccent),
                  const SizedBox(width: 16),
                  _buildKpiCard(
                      context,
                      'Orders Today',
                      stats['ordersToday'].toString(),
                      Icons.receipt_long,
                      Colors.blueAccent),
                  const SizedBox(width: 16),
                  _buildKpiCard(
                      context,
                      'Average Order Value',
                      currencyFormatter.format(stats['averageOrder']),
                      Icons.analytics_outlined,
                      Colors.purpleAccent),
                ],
              );
            },
          ),

          const SizedBox(height: 32),
          const Text('Recent Transactions',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 16),

          // --- RECENT TRANSACTIONS TABLE ---
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: transactionsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.red)),
                error: (e, _) => Center(
                    child: Text('Error loading transactions: $e',
                        style: const TextStyle(color: Colors.red))),
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const Center(
                        child: Text('No transactions yet today.',
                            style: TextStyle(color: Colors.grey)));
                  }

                  return SingleChildScrollView(
                    child: DataTable(
                      headingTextStyle:
                          const TextStyle(color: Colors.grey, fontSize: 12),
                      dataTextStyle:
                          const TextStyle(color: Colors.white, fontSize: 13),
                      columns: const [
                        DataColumn(label: Text('Date & Time')),
                        DataColumn(label: Text('Receipt ID')),
                        DataColumn(label: Text('Payment Method')),
                        DataColumn(label: Text('Total Amount')),
                      ],
                      rows: transactions.map((tx) {
                        // Shorten the UUID for cleaner display
                        final shortId =
                            tx['id'].toString().substring(0, 8).toUpperCase();
                        final paymentType = tx['payment_type']
                            .toString()
                            .replaceAll('_', ' ')
                            .toUpperCase();
                        final date = DateTime.parse(tx['created_at']).toLocal();

                        return DataRow(cells: [
                          DataCell(Text(dateFormatter.format(date))),
                          DataCell(Text('#$shortId',
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold))),
                          DataCell(_buildPaymentBadge(paymentType)),
                          DataCell(Text(
                              currencyFormatter.format(tx['grand_total']),
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold))),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildKpiCard(BuildContext context, String title, String value,
      IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(String method) {
    Color color = Colors.grey;
    if (method.contains('CASH')) color = Colors.green;
    if (method.contains('BANK')) color = Colors.blue;
    if (method.contains('FINANCE')) color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(method,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
