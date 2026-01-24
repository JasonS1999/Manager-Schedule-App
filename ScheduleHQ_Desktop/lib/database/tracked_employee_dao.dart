import 'package:sqflite/sqflite.dart';
import 'app_database.dart';
import '../models/employee.dart';

/// DAO for managing tracked employees (employees shown in PDF stats)
class TrackedEmployeeDao {
  Future<Database> get _db async => AppDatabase.instance.db;

  /// Get all tracked employee IDs in sort order
  Future<List<int>> getTrackedEmployeeIds() async {
    final db = await _db;
    final maps = await db.query('tracked_employees', orderBy: 'sortOrder ASC');
    return maps.map((m) => m['employeeId'] as int).toList();
  }

  /// Get tracked employees with full employee data, sorted by job code
  Future<List<Employee>> getTrackedEmployees(
    List<Employee> allEmployees,
  ) async {
    final trackedIds = await getTrackedEmployeeIds();
    if (trackedIds.isEmpty) return [];

    // Filter and maintain tracked order
    final trackedMap = <int, Employee>{};
    for (final emp in allEmployees) {
      if (emp.id != null && trackedIds.contains(emp.id)) {
        trackedMap[emp.id!] = emp;
      }
    }

    // Return in sort order
    return trackedIds
        .where((id) => trackedMap.containsKey(id))
        .map((id) => trackedMap[id]!)
        .toList();
  }

  /// Set tracked employees (replaces all existing)
  Future<void> setTrackedEmployees(List<int> employeeIds) async {
    final db = await _db;
    await db.transaction((txn) async {
      // Clear existing
      await txn.delete('tracked_employees');

      // Insert new ones with sort order
      for (int i = 0; i < employeeIds.length; i++) {
        await txn.insert('tracked_employees', {
          'employeeId': employeeIds[i],
          'sortOrder': i,
        });
      }
    });
  }

  /// Add a tracked employee
  Future<void> addTrackedEmployee(int employeeId) async {
    final db = await _db;
    final existing = await getTrackedEmployeeIds();
    if (existing.contains(employeeId)) return;

    await db.insert('tracked_employees', {
      'employeeId': employeeId,
      'sortOrder': existing.length,
    });
  }

  /// Remove a tracked employee
  Future<void> removeTrackedEmployee(int employeeId) async {
    final db = await _db;
    await db.delete(
      'tracked_employees',
      where: 'employeeId = ?',
      whereArgs: [employeeId],
    );
  }

  /// Check if an employee is tracked
  Future<bool> isTracked(int employeeId) async {
    final db = await _db;
    final result = await db.query(
      'tracked_employees',
      where: 'employeeId = ?',
      whereArgs: [employeeId],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}
