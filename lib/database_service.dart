import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_database_service.dart';
import 'models.dart';

final databaseProvider = Provider((ref) => DatabaseService());

final inventoryProvider = FutureProvider<List<Product>>((ref) async {
  return await ref.read(databaseProvider).fetchLocalPosInventory();
});

final detailedBikesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await LocalDatabaseService().getLocalBikes();
});

final detailedAccessoriesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await LocalDatabaseService().getLocalAccessories();
});

final dashboardStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return await ref.read(databaseProvider).fetchOfflineDashboardStats();
});

final recentTransactionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(databaseProvider).fetchOfflineRecentTransactions();
});

class DatabaseService {
  final _supabase = Supabase.instance.client;
  final _localDb = LocalDatabaseService();

  Future<List<Product>> fetchLocalPosInventory() async {
    final bikesData = await _localDb.getLocalBikes(onlyInStock: true);
    final accData = await _localDb.getLocalAccessories();

    List<Product> products = [];

    for (var row in bikesData) {
      products.add(Product(
        id: row['vin_number'],
        name: row['brand'] ?? 'Unknown',
        subtitle: '${row['model_name']} - ${row['color']}',
        price: (row['base_price'] as num).toDouble(),
        isBike: true,
        stock: 1,
        imageUrl: row['image_url'] ?? row['model_image'],
      ));
    }

    for (var row in accData) {
      products.add(Product(
        id: row['sku'],
        name: row['product_name'] ?? 'Gear',
        subtitle: row['variant_name'],
        price: (row['price'] as num).toDouble(),
        isBike: false,
        stock: row['stock_quantity'] as int,
        imageUrl: row['image_url'],
      ));
    }

    return products;
  }

  Future<Map<String, dynamic>> fetchOfflineDashboardStats() async {
    final db = await _localDb.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

    final results = await db
        .query('sync_queue', where: 'created_at >= ?', whereArgs: [startOfDay]);

    double totalRevenue = 0;
    for (var row in results) {
      final payload = jsonDecode(row['payload'] as String);
      totalRevenue += (payload['grandTotal'] as num).toDouble();
    }

    return {
      'revenueToday': totalRevenue,
      'ordersToday': results.length,
      'averageOrder': results.isEmpty ? 0.0 : totalRevenue / results.length,
    };
  }

  Future<List<Map<String, dynamic>>> fetchOfflineRecentTransactions() async {
    final db = await _localDb.database;
    final results =
        await db.query('sync_queue', orderBy: 'created_at DESC', limit: 10);

    return results.map((row) {
      final payload = jsonDecode(row['payload'] as String);
      return {
        'id': row['receipt_id'],
        'created_at': row['created_at'],
        'grand_total': payload['grandTotal'],
        'payment_type': payload['paymentType'],
      };
    }).toList();
  }

  // ==========================================
  // ONLINE ADMIN WRITES (WITH OFFLINE FALLBACKS)
  // ==========================================

  Future<String?> uploadImage(String fileName, Uint8List fileBytes) async {
    try {
      final filePath =
          'inventory/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await _supabase.storage.from('product-images').uploadBinary(
          filePath, fileBytes,
          fileOptions: const FileOptions(upsert: true));
      return _supabase.storage.from('product-images').getPublicUrl(filePath);
    } catch (e) {
      throw Exception(
          'You must be online to upload new images. Try saving without an image.');
    }
  }

  Future<void> addMotorcycle(
      {required String vin,
      required String engineNo,
      required String modelId,
      required String color,
      String? imageUrl}) async {
    final db = await _localDb.database;
    await db.insert(
      'bikes',
      {
        'vin_number': vin,
        'model_id': modelId,
        'engine_number': engineNo,
        'color': color,
        'status': 'in_stock',
        'image_url': imageUrl
      },
      // conflictAlgorithm: ConflictAlgorithm.replace
    );

    try {
      final bikeData = {
        'vin_number': vin,
        'engine_number': engineNo,
        'model_id': modelId,
        'color': color,
        'status': 'in_stock'
      };
      if (imageUrl != null) bikeData['image_url'] = imageUrl;
      await _supabase.from('bikes').insert(bikeData);
    } catch (e) {
      print('Offline: Bike added locally.');
    }
    _localDb.startAutoSync();
  }

  Future<void> updateMotorcycle(
      {required String vin,
      required String modelId,
      required String status,
      required double price,
      String? imageUrl}) async {
    final db = await _localDb.database;
    await db.update('bikes', {'status': status},
        where: 'vin_number = ?', whereArgs: [vin]);
    await db.update('bike_models', {'base_price': price},
        where: 'id = ?', whereArgs: [modelId]);

    try {
      final bikeUpdates = <String, dynamic>{'status': status};
      if (imageUrl != null) bikeUpdates['image_url'] = imageUrl;
      await _supabase.from('bikes').update(bikeUpdates).eq('vin_number', vin);
      await _supabase
          .from('bike_models')
          .update({'base_price': price}).eq('id', modelId);
    } catch (e) {
      print('Offline: Bike edit saved locally.');
    }
    _localDb.startAutoSync();
  }

  Future<void> addAccessory(
      {required String sku,
      required String productId,
      required String variantName,
      required double price,
      required int stock,
      String? imageUrl}) async {
    final db = await _localDb.database;
    await db.insert(
      'product_variants',
      {
        'sku': sku,
        'product_id': productId,
        'variant_name': variantName,
        'price': price,
        'stock_quantity': stock,
        'image_url': imageUrl,
        'product_name': 'Accessory'
      },
      // conflictAlgorithm: ConflictAlgorithm.replace
    );

    try {
      final data = {
        'sku': sku,
        'product_id': productId,
        'variant_name': variantName,
        'price': price,
        'stock_quantity': stock
      };
      if (imageUrl != null) data['image_url'] = imageUrl;
      await _supabase.from('product_variants').upsert(data);
    } catch (e) {
      print('Offline: Accessory added locally.');
    }
    _localDb.startAutoSync();
  }

  Future<void> updateAccessory(
      {required String sku,
      required double price,
      required int stock,
      String? imageUrl}) async {
    // FIXED: Explicitly defined as <String, dynamic> so it accepts both numbers and the image String
    final updates = <String, dynamic>{'price': price, 'stock_quantity': stock};
    if (imageUrl != null) updates['image_url'] = imageUrl;

    final db = await _localDb.database;
    await db.update('product_variants', updates,
        where: 'sku = ?', whereArgs: [sku]);

    try {
      await _supabase.from('product_variants').update(updates).eq('sku', sku);
    } catch (e) {
      print('Offline: Accessory edit saved locally.');
    }
    _localDb.startAutoSync();
  }
}
