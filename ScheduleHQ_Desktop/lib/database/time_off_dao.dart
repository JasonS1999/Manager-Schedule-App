import 'package:sqflite/sqflite.dart';
import 'app_database.dart';
import '../models/time_off_entry.dart';
import '../services/auto_sync_service.dart';

class TimeOffDao {
  Future<Database> get _db async => AppDatabase.instance.db;

  // ------------------------------------------------------------
  // GET ALL TIME OFF (expands multi-day entries)
  // ------------------------------------------------------------
  Future<List<TimeOffEntry>> getAllTimeOff() async {
    final db = await _db;
    final result = await db.query('time_off', orderBy: 'date ASC');
    
    // Expand multi-day entries into individual entries for each day
    final List<TimeOffEntry> expandedEntries = [];
    for (final row in result) {
      final entry = TimeOffEntry.fromMap(row);
      
      if (entry.endDate != null && entry.endDate != entry.date) {
        // Multi-day entry - expand to individual days
        final dayCount = entry.endDate!.difference(entry.date).inDays + 1;
        final hoursPerDay = dayCount > 0 ? (entry.hours / dayCount).round() : entry.hours;
        
        // Use calendar day iteration to avoid DST issues
        var currentDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
        final endDateNormalized = DateTime(entry.endDate!.year, entry.endDate!.month, entry.endDate!.day);
        
        while (!currentDate.isAfter(endDateNormalized)) {
          expandedEntries.add(TimeOffEntry(
            id: entry.id,
            employeeId: entry.employeeId,
            date: currentDate,
            endDate: entry.endDate,
            timeOffType: entry.timeOffType,
            hours: hoursPerDay > 0 ? hoursPerDay : 8,
            vacationGroupId: entry.vacationGroupId,
            isAllDay: entry.isAllDay,
            startTime: entry.startTime,
            endTime: entry.endTime,
          ));
          currentDate = DateTime(currentDate.year, currentDate.month, currentDate.day + 1);
        }
      } else {
        // Single-day entry
        expandedEntries.add(entry);
      }
    }
    
    return expandedEntries;
  }

  // ------------------------------------------------------------
  // GET ALL TIME OFF RAW (without expanding, for editing/deletion)
  // ------------------------------------------------------------
  Future<List<TimeOffEntry>> getAllTimeOffRaw() async {
    final db = await _db;
    final result = await db.query('time_off', orderBy: 'date ASC');
    return result.map((row) => TimeOffEntry.fromMap(row)).toList();
  }

  // ------------------------------------------------------------
  // GET ALL TIME OFF FOR A MONTH (expands date ranges)
  // ------------------------------------------------------------
  Future<List<TimeOffEntry>> getAllTimeOffForMonth(int year, int month) async {
    final db = await _db;

    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);

    // Query entries where:
    // 1. Single-day entries: date is within the month
    // 2. Multi-day entries: date range overlaps with the month
    final result = await db.query(
      'time_off',
      where: '''
        (endDate IS NULL AND date >= ? AND date <= ?) OR
        (endDate IS NOT NULL AND date <= ? AND endDate >= ?)
      ''',
      whereArgs: [
        monthStart.toIso8601String(),
        monthEnd.toIso8601String(),
        monthEnd.toIso8601String(),
        monthStart.toIso8601String(),
      ],
      orderBy: 'date ASC',
    );

    // Expand multi-day entries into individual entries for each day
    final List<TimeOffEntry> expandedEntries = [];
    for (final row in result) {
      final entry = TimeOffEntry.fromMap(row);
      
      if (entry.endDate != null && entry.endDate != entry.date) {
        // Multi-day entry - expand to individual days
        final dayCount = entry.endDate!.difference(entry.date).inDays + 1;
        final hoursPerDay = dayCount > 0 ? (entry.hours / dayCount).round() : entry.hours;
        
        // Use calendar day iteration to avoid DST issues
        var currentDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
        final endDateNormalized = DateTime(entry.endDate!.year, entry.endDate!.month, entry.endDate!.day);
        
        while (!currentDate.isAfter(endDateNormalized)) {
          // Only include days that fall within the requested month
          if (currentDate.year == year && currentDate.month == month) {
            expandedEntries.add(TimeOffEntry(
              id: entry.id,
              employeeId: entry.employeeId,
              date: currentDate,
              endDate: entry.endDate, // Keep reference to original end date
              timeOffType: entry.timeOffType,
              hours: hoursPerDay > 0 ? hoursPerDay : 8,
              vacationGroupId: entry.vacationGroupId,
              isAllDay: entry.isAllDay,
              startTime: entry.startTime,
              endTime: entry.endTime,
            ));
          }
          // Move to next calendar day (avoids DST issues)
          currentDate = DateTime(currentDate.year, currentDate.month, currentDate.day + 1);
        }
      } else {
        // Single-day entry
        expandedEntries.add(entry);
      }
    }

    return expandedEntries;
  }

  // ------------------------------------------------------------
  // INSERT
  // ------------------------------------------------------------
  Future<int> insertTimeOff(TimeOffEntry entry) async {
    final db = await _db;
    final id = await db.insert('time_off', entry.toMap());
    
    // Notify auto-sync service of the change
    AutoSyncService.instance.onTimeOffDataChanged();
    
    return id;
  }

  // ------------------------------------------------------------
  // UPDATE
  // ------------------------------------------------------------
  Future<int> updateTimeOff(TimeOffEntry entry) async {
    final db = await _db;
    if (entry.id == null) throw Exception("Missing ID");
    final result = await db.update(
      'time_off',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
    
    // Notify auto-sync service of the change
    AutoSyncService.instance.onTimeOffDataChanged();
    
    return result;
  }

  // ------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------
  Future<int> deleteTimeOff(int id) async {
    final db = await _db;
    final result = await db.delete(
      'time_off',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // Notify auto-sync service of the change
    AutoSyncService.instance.onTimeOffDataChanged();
    
    return result;
  }

  // ------------------------------------------------------------
  // DELETE VACATION GROUP
  // ------------------------------------------------------------
  Future<int> deleteVacationGroup(String groupId) async {
    final db = await _db;
    final result = await db.delete(
      'time_off',
      where: 'vacationGroupId = ?',
      whereArgs: [groupId],
    );
    
    // Notify auto-sync service of the change
    AutoSyncService.instance.onTimeOffDataChanged();
    
    return result;
  }

  // ------------------------------------------------------------
  // CHECK FOR EXISTING TIME OFF IN RANGE
  // ------------------------------------------------------------
  Future<bool> hasTimeOffInRange(int employeeId, DateTime start, DateTime end) async {
    final db = await _db;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM time_off
      WHERE employeeId = ?
        AND date >= ?
        AND date <= ?
    ''', [employeeId, start.toIso8601String(), end.toIso8601String()]);

    final total = result.first['total'] as num?;
    return (total?.toInt() ?? 0) > 0;
  }

  // ------------------------------------------------------------
  // GET ENTRIES BY VACATION GROUP
  // ------------------------------------------------------------
  Future<List<TimeOffEntry>> getEntriesByGroup(String groupId) async {
    final db = await _db;
    final result = await db.query(
      'time_off',
      where: 'vacationGroupId = ?',
      whereArgs: [groupId],
      orderBy: 'date ASC',
    );

    return result.map((row) => TimeOffEntry.fromMap(row)).toList();
  }

  // ------------------------------------------------------------
  // PTO HOURS USED IN RANGE
  // ------------------------------------------------------------
  Future<int> getPtoUsedInRange(
      int employeeId, DateTime start, DateTime end) async {
    final db = await _db;

    final result = await db.rawQuery('''
      SELECT SUM(hours) AS total
      FROM time_off
      WHERE employeeId = ?
        AND date >= ?
        AND date <= ?
        AND timeOffType = 'pto'
    ''', [
      employeeId,
      start.toIso8601String(),
      end.toIso8601String(),
    ]);

    final total = result.first['total'] as num?;
    return total?.toInt() ?? 0;
  }

  // ------------------------------------------------------------
  // GET ENTRIES IN RANGE (for overlap details)
  // ------------------------------------------------------------
  Future<List<TimeOffEntry>> getTimeOffInRange(int employeeId, DateTime start, DateTime end) async {
    final db = await _db;

    final result = await db.query(
      'time_off',
      where: 'employeeId = ? AND date >= ? AND date <= ?',
      whereArgs: [employeeId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date ASC',
    );

    return result.map((row) => TimeOffEntry.fromMap(row)).toList();
  }
}
