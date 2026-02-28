import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pos_screen.dart';
import 'inventory_screen.dart';
import 'dashboard_screen.dart';

// ==========================================
// 1. AUTHENTICATION STATE
// ==========================================
// This tracks who is logged in: null (guest), 'cashier', or 'admin'
final authRoleProvider = StateProvider<String?>((ref) => null);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL')!,
    anonKey: dotenv.get('SUPABASE_ANON_KEY')!,
  );

  runApp(const ProviderScope(child: MotoVaultApp()));
}

class MotoVaultApp extends StatelessWidget {
  const MotoVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotoVault POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD32F2F),
          surface: Color(0xFF1A1A1A),
        ),
        fontFamily: 'Inter',
      ),
      // The AuthRouter decides which screen to show based on the login state
      home: const AuthRouter(),
    );
  }
}

// ==========================================
// 2. THE ROUTER (Traffic Controller)
// ==========================================
class AuthRouter extends ConsumerWidget {
  const AuthRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authRoleProvider);

    if (role == 'cashier') {
      return const CashierLayout();
    } else if (role == 'admin') {
      return const AdminLayout();
    } else {
      return const LoginScreen();
    }
  }
}

// ==========================================
// 3. THE LOGIN SCREEN
// ==========================================
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('MV',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
              const SizedBox(height: 16),
              const Text('MotoVault System',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const Text('Please select your portal',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),

              // Cashier Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(authRoleProvider.notifier).state = 'cashier',
                  icon: const Icon(Icons.point_of_sale, color: Colors.white),
                  label: const Text('Login as POS Operator',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF252525),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Admin Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(authRoleProvider.notifier).state = 'admin',
                  icon: const Icon(Icons.admin_panel_settings,
                      color: Colors.white),
                  label: const Text('Login as System Admin',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 4. CASHIER LAYOUT (Strictly POS only)
// ==========================================
class CashierLayout extends ConsumerWidget {
  const CashierLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          // Simplified Top Bar
          Container(
            height: 60,
            color: const Color(0xFF141414),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('MV',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(width: 12),
                const Text('MotoVault',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const Spacer(),
                const Text('Operator', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  tooltip: 'Logout',
                  onPressed: () => ref.read(authRoleProvider.notifier).state =
                      null, // Logs user out
                ),
              ],
            ),
          ),
          // Only the POS Screen is loaded here
          const Expanded(child: PosScreen()),
        ],
      ),
    );
  }
}

// ==========================================
// 5. ADMIN LAYOUT (Inventory & Dashboard only)
// ==========================================
class AdminLayout extends ConsumerStatefulWidget {
  const AdminLayout({super.key});

  @override
  ConsumerState<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends ConsumerState<AdminLayout> {
  int _selectedIndex = 0;
  final List<Widget> _adminScreens = [
    const InventoryScreen(),
    const DashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Admin Top Navigation Bar
          Container(
            height: 60,
            color: const Color(0xFF141414),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('MV',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(width: 12),
                const Text('MotoVault',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(width: 40),

                // Admin Nav Items
                _buildNavItem(
                    0, Icons.inventory_2_outlined, 'Inventory Management'),
                _buildNavItem(1, Icons.bar_chart, 'Analytics Dashboard'),

                const Spacer(),
                const Text('Administrator',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  tooltip: 'Logout',
                  onPressed: () => ref.read(authRoleProvider.notifier).state =
                      null, // Logs user out
                ),
              ],
            ),
          ),
          // Main Admin Content Area
          Expanded(child: _adminScreens[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueGrey.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: isSelected ? Colors.blueGrey[300] : Colors.grey),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blueGrey[300] : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
