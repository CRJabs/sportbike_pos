import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Manager Dashboard',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const Text('Overview of store performance',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),

          // KPI Cards Row
          Row(
            children: [
              _buildKpiCard(context, 'Revenue Today', '\$47,394', '+12.3%',
                  Icons.attach_money, Colors.green),
              const SizedBox(width: 16),
              _buildKpiCard(context, 'Bikes Sold', '3', '+1 today',
                  Icons.motorcycle, Colors.green),
              const SizedBox(width: 16),
              _buildKpiCard(context, 'Accessories Sold', '24', '+8 today',
                  Icons.shield, Colors.green),
              const SizedBox(width: 16),
              _buildKpiCard(context, 'Inventory Value', '\$2.4M', '48 units',
                  Icons.inventory, Colors.grey),
            ],
          ),
          const SizedBox(height: 24),

          // Bottom Section: Chart & Recent Transactions
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chart Section
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sales — Last 7 Days',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        // Mock Bar Chart
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildChartBar('Mon', 120),
                            _buildChartBar('Tue', 60),
                            _buildChartBar('Wed', 90),
                            _buildChartBar('Thu', 50),
                            _buildChartBar('Fri', 140),
                            _buildChartBar('Sat', 180),
                            _buildChartBar('Sun', 80),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Transactions Section
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recent Transactions',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView(
                            children: [
                              _buildTransaction(
                                  'Marcus Chen',
                                  'Ducati Panigale V4 + Helmet\nFinancing • 2026-02-25',
                                  '\$29,445'),
                              _buildTransaction(
                                  'Sarah Rodriguez',
                                  'Racing Jacket, Gloves, Visor\nCash • 2026-02-25',
                                  '\$560'),
                              _buildTransaction(
                                  'James Nakamura',
                                  'BMW S 1000 RR\nBank Transfer • 2026-02-24',
                                  '\$19,295'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(BuildContext context, String title, String value,
      String subtext, IconData icon, Color subtextColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
                Icon(icon,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtext, style: TextStyle(color: subtextColor, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartBar(String label, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 40,
          height: height,
          decoration: const BoxDecoration(
            color: Color(0xFFD32F2F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildTransaction(String name, String details, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(details,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12, height: 1.4)),
            ],
          ),
          Text(amount,
              style: const TextStyle(
                  color: Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
