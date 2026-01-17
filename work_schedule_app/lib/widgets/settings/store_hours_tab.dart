import 'package:flutter/material.dart';
import '../../database/store_hours_dao.dart';
import '../../models/store_hours.dart';

class StoreHoursTab extends StatefulWidget {
  const StoreHoursTab({super.key});

  @override
  State<StoreHoursTab> createState() => _StoreHoursTabState();
}

class _StoreHoursTabState extends State<StoreHoursTab> {
  final StoreHoursDao _dao = StoreHoursDao();
  StoreHours? _storeHours;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final hours = await _dao.getStoreHours();
    if (mounted) {
      setState(() {
        _storeHours = hours;
        _isLoading = false;
      });
    }
  }

  List<String> _generateTimeOptions() {
    final times = <String>[];
    // Generate times from 12:00 AM to 11:30 PM in 30-minute increments
    for (int hour = 0; hour < 24; hour++) {
      times.add('${hour.toString().padLeft(2, '0')}:00');
      times.add('${hour.toString().padLeft(2, '0')}:30');
    }
    return times;
  }

  String _formatTimeForDisplay(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final suffix = hour < 12 ? 'AM' : 'PM';
    return '$h:$minute $suffix';
  }

  Future<void> _updateOpenTime(String? newTime) async {
    if (newTime == null || _storeHours == null) return;
    final updated = _storeHours!.copyWith(openTime: newTime);
    await _dao.updateStoreHours(updated);
    setState(() {
      _storeHours = updated;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store open time updated'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateCloseTime(String? newTime) async {
    if (newTime == null || _storeHours == null) return;
    final updated = _storeHours!.copyWith(closeTime: newTime);
    await _dao.updateStoreHours(updated);
    setState(() {
      _storeHours = updated;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store close time updated'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resetToDefaults() async {
    final defaults = StoreHours.defaults();
    await _dao.updateStoreHours(defaults);
    setState(() {
      _storeHours = defaults;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store hours reset to defaults'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final timeOptions = _generateTimeOptions();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.store, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Store Operating Hours',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These times are used to display "Op" (Open) and "CL" (Close) labels in the schedule instead of showing the full time.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Store Opens',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _storeHours?.openTime,
                                  isExpanded: true,
                                  items: timeOptions.map((time) {
                                    return DropdownMenuItem(
                                      value: time,
                                      child: Text(_formatTimeForDisplay(time)),
                                    );
                                  }).toList(),
                                  onChanged: _updateOpenTime,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Displayed as "Op" in schedule cells',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Store Closes',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _storeHours?.closeTime,
                                  isExpanded: true,
                                  items: timeOptions.map((time) {
                                    return DropdownMenuItem(
                                      value: time,
                                      child: Text(_formatTimeForDisplay(time)),
                                    );
                                  }).toList(),
                                  onChanged: _updateCloseTime,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Displayed as "CL" in schedule cells',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.preview, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Preview',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPreviewCell('Op', _formatTimeForDisplay(_storeHours?.openTime ?? '04:30')),
                      const SizedBox(width: 16),
                      const Icon(Icons.arrow_forward, color: Colors.grey),
                      const SizedBox(width: 16),
                      _buildPreviewCell('CL', _formatTimeForDisplay(_storeHours?.closeTime ?? '01:00')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              onPressed: _resetToDefaults,
              icon: const Icon(Icons.restore),
              label: const Text('Reset to Defaults (4:30 AM - 1:00 AM)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCell(String label, String time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
