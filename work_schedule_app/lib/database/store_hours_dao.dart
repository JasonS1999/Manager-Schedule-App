import 'package:sqflite/sqflite.dart';
import 'app_database.dart';
import '../models/store_hours.dart';

class StoreHoursDao {
  Future<Database> get _db async => await AppDatabase.instance.db;

  /// Create the store_hours table
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS store_hours (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        openTime TEXT NOT NULL,
        closeTime TEXT NOT NULL
      )
    ''');
  }

  /// Get store hours (there should only be one row)
  Future<StoreHours> getStoreHours() async {
    final db = await _db;
    final maps = await db.query('store_hours', limit: 1);
    if (maps.isEmpty) {
      // Insert defaults if no record exists
      final defaults = StoreHours.defaults();
      await db.insert('store_hours', defaults.toMap());
      return defaults;
    }
    return StoreHours.fromMap(maps.first);
  }

  /// Update store hours
  Future<void> updateStoreHours(StoreHours hours) async {
    final db = await _db;
    final existing = await db.query('store_hours', limit: 1);
    if (existing.isEmpty) {
      await db.insert('store_hours', hours.toMap());
    } else {
      await db.update(
        'store_hours',
        hours.toMap(),
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }

  /// Insert default store hours if table is empty
  Future<void> insertDefaultsIfEmpty() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM store_hours'),
    );
    if (count == 0) {
      await db.insert('store_hours', StoreHours.defaults().toMap());
    }
  }
}
