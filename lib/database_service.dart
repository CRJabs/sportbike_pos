import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'dart:typed_data';
// Note: If your CartItem class is in cart_provider.dart instead of models.dart,
// make sure to import 'cart_provider.dart' here as well.

// ==========================================
// 1. PROVIDERS
// ==========================================

// Provides the base DatabaseService to the app
final databaseProvider = Provider((ref) => DatabaseService());

// Provides the formatted UI-ready inventory for the POS Screen
final inventoryProvider =
    FutureProvider<Map<String, List<Product>>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.fetchInventory();
});

// Provides the raw detailed data for the Inventory Screen (Bikes)
final detailedBikesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(databaseProvider).fetchDetailedBikes();
});

// Provides the raw detailed data for the Inventory Screen (Accessories)
final detailedAccessoriesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(databaseProvider).fetchDetailedAccessories();
});

// Provides the KPI totals for today
final dashboardStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return await ref.read(databaseProvider).fetchDashboardStats();
});

// Provides the latest 10 transactions
final recentTransactionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(databaseProvider).fetchRecentTransactions();
});

// ==========================================
// 2. DATABASE SERVICE CLASS
// ==========================================

class DatabaseService {
  final _supabase = Supabase.instance.client;

  // --- POS FETCH METHODS ---

  Future<Map<String, List<Product>>> fetchInventory() async {
    // 1. Fetch Bikes
    final bikesResponse = await _supabase
        .from('bikes')
        .select(
            'vin_number, color, image_url, bike_models(brand, model_name, base_price)')
        .eq('status', 'in_stock');

    List<Product> fetchedBikes = bikesResponse.map((row) {
      final modelData = row['bike_models'];
      final color = row['color'] ?? 'Unknown Color'; // Grab the color

      return Product(
        id: row['vin_number'],
        name: modelData['brand'],
        subtitle:
            '${modelData['model_name']} - $color', // <--- Now displays: "Ninja ZX-10R - Green"
        price: (modelData['base_price'] as num).toDouble(),
        isBike: true,
        stock: 1,
        imageUrl: row['image_url'], // <--- Pulls the specific unit's photo
      );
    }).toList();

    // 2. Fetch Accessories
    final accessoriesResponse = await _supabase
        .from('product_variants')
        // ADD image_url to the select query below:
        .select(
            'id, sku, variant_name, price, stock_quantity, image_url, products(name)')
        .gt('stock_quantity', 0);

    List<Product> fetchedAccessories = accessoriesResponse.map((row) {
      final parentProduct = row['products'];
      return Product(
        id: row['id'],
        name: parentProduct['name'],
        subtitle: row['variant_name'],
        price: (row['price'] as num).toDouble(),
        isBike: false,
        stock: row['stock_quantity'] as int,
        imageUrl: row['image_url'], // <--- ADD THIS LINE
      );
    }).toList();

    return {
      'bikes': fetchedBikes,
      'accessories': fetchedAccessories,
    };
  }

  // --- CHECKOUT RPC CALL ---

  Future<void> checkout({
    required double subtotal,
    required double vatAmount,
    required double grandTotal,
    required String paymentType,
    required List<CartItem> cartItems,
  }) async {
    // Format the cart items into the JSON array our PostgreSQL RPC expects
    final List<Map<String, dynamic>> itemsPayload = cartItems
        .map((item) => {
              'id': item.product.id,
              'is_bike': item.product.isBike,
              'price': item.product.price,
              'quantity': item.quantity,
            })
        .toList();

    // Call the Supabase RPC function
    await _supabase.rpc('process_checkout', params: {
      'p_customer_id': null,
      'p_subtotal': subtotal,
      'p_vat_amount': vatAmount,
      'p_grand_total': grandTotal,
      'p_payment_type': paymentType,
      'p_cart_items': itemsPayload,
    });
  }

  // --- INVENTORY MANAGEMENT FETCH METHODS ---

  Future<List<Map<String, dynamic>>> fetchDetailedBikes() async {
    final response = await _supabase
        .from('bikes')
        // Move image_url OUT of the bike_models() block and into the main bikes table selection
        .select(
            'vin_number, engine_number, color, status, warehouse_location, image_url, bike_models(id, brand, model_name, base_price)')
        .order('vin_number', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchDetailedAccessories() async {
    final response = await _supabase
        .from('product_variants')
        .select('sku, variant_name, price, stock_quantity, products(name)')
        .order('sku', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // --- INVENTORY MANAGEMENT WRITE METHODS ---

  // --- UPDATE THIS EXISTING METHOD ---
  Future<void> updateAccessory(String sku, double price, int stock,
      {String? imageUrl}) async {
    // We create a map of updates. If an image was uploaded, we include it.
    final updates = <String, dynamic>{'price': price, 'stock_quantity': stock};

    if (imageUrl != null) {
      updates['image_url'] = imageUrl;
    }

    await _supabase.from('product_variants').update(updates).eq('sku', sku);
  }

  Future<void> updateMotorcycle({
    required String vin,
    required String modelId,
    required String status,
    required double price,
    String? imageUrl,
  }) async {
    // 1. Update the specific unit's status AND image in the 'bikes' table
    final bikeUpdates = <String, dynamic>{'status': status};
    if (imageUrl != null) {
      bikeUpdates['image_url'] = imageUrl;
    }
    await _supabase.from('bikes').update(bikeUpdates).eq('vin_number', vin);

    // 2. Update the parent model's price in the 'bike_models' table
    await _supabase
        .from('bike_models')
        .update({'base_price': price}).eq('id', modelId);
  }

  // Add a new Motorcycle to inventory
  Future<void> addMotorcycle({
    required String vin,
    required String engineNo,
    required String modelId,
    required String color,
    String? imageUrl,
  }) async {
    final bikeData = <String, dynamic>{
      'vin_number': vin,
      'engine_number': engineNo,
      'model_id': modelId,
      'color': color,
      'status': 'in_stock',
    };

    // Attach the image directly to this specific bike unit
    if (imageUrl != null) {
      bikeData['image_url'] = imageUrl;
    }

    await _supabase.from('bikes').insert(bikeData);
  }

  // Add a new Accessory/Gear to inventory
  Future<void> addAccessory({
    required String sku,
    required String productId,
    required String variantName,
    required double price,
    required int stock,
    String? imageUrl,
  }) async {
    final data = {
      'sku': sku,
      'product_id': productId,
      'variant_name': variantName,
      'price': price,
      'stock_quantity': stock,
    };

    if (imageUrl != null) {
      data['image_url'] = imageUrl;
    }

    await _supabase.from('product_variants').insert(data);
  }

  // --- ADD THIS NEW UPLOAD METHOD ---
  Future<String?> uploadImage(String fileName, Uint8List fileBytes) async {
    try {
      final filePath =
          'inventory/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await _supabase.storage.from('product-images').uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      return _supabase.storage.from('product-images').getPublicUrl(filePath);
    } catch (e) {
      // INSTEAD OF RETURNING NULL, WE THROW THE ERROR
      // This forces the red SnackBar to appear in your UI if something breaks
      throw Exception('Supabase Storage Error: $e');
    }
  }

  // --- DASHBOARD ANALYTICS METHODS ---

  Future<Map<String, dynamic>> fetchDashboardStats() async {
    // Get the start of the current day in ISO8601 format to filter Supabase records
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

    // Fetch all sales orders created today
    final response = await _supabase
        .from('sales_orders')
        .select('grand_total')
        .gte('created_at', startOfDay);

    final List orders = response as List;

    double totalRevenue = 0;
    for (var order in orders) {
      totalRevenue += (order['grand_total'] as num).toDouble();
    }

    return {
      'revenueToday': totalRevenue,
      'ordersToday': orders.length,
      'averageOrder': orders.isEmpty ? 0.0 : totalRevenue / orders.length,
    };
  }

  Future<List<Map<String, dynamic>>> fetchRecentTransactions() async {
    // Fetch the 10 most recent sales
    final response = await _supabase
        .from('sales_orders')
        .select('id, created_at, grand_total, payment_type')
        .order('created_at', ascending: false)
        .limit(10);

    return List<Map<String, dynamic>>.from(response);
  }
}
