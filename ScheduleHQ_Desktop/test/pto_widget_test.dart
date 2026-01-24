import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:schedulehq_desktop/database/app_database.dart';

// Note: TimeOffPage was removed - time off management is now consolidated into ApprovalQueuePage
// These tests need to be rewritten to work with the new page structure

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    await AppDatabase.instance.init(dbPath: ':memory:');
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  // TODO: Rewrite these tests to use ApprovalQueuePage
  // The old TimeOffPage calendar view was removed and replaced with the
  // approval queue which has Pending/Approved/Denied tabs
  
  test('placeholder - PTO widget tests need rewriting', () {
    // TimeOffPage was consolidated into ApprovalQueuePage
    // Test the new approval flow instead
    expect(true, isTrue);
  });
}
