import 'package:flutter/material.dart';

class SiteDetailsPage extends StatelessWidget {
  final Map<String, dynamic> siteData;

  const SiteDetailsPage({Key? key, required this.siteData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lat = siteData['lat'];
    final lng = siteData['lng'];

    return Scaffold(
      appBar: AppBar(
        title: Text(siteData['name'] ?? 'Site Details'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card with site name & location
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              color: const Color(0xFF1976D2),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      siteData['name'] ?? 'Unknown Site',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (lat != null && lng != null)
                      Row(
                        children: [
                          const Icon(Icons.location_pin, color: Colors.white70),
                          const SizedBox(width: 8),
                          Text(
                            '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Details List
            ...siteData.entries.where((e) => e.key != 'name' && e.key != 'lat' && e.key != 'lng').map((entry) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ListTile(
                  leading: Icon(
                    _getIconForKey(entry.key),
                    color: const Color(0xFF1976D2),
                  ),
                  title: Text(
                    _formatKey(entry.key),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(entry.value.toString()),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Helper to format key names nicely
  String _formatKey(String key) {
    return key.replaceAll('_', ' ').replaceFirst(key[0], key[0].toUpperCase());
  }

  // Simple icon selector for known keys
  IconData _getIconForKey(String key) {
    key = key.toLowerCase();
    if (key.contains('id')) return Icons.badge;
    if (key.contains('name')) return Icons.label;
    if (key.contains('location') || key.contains('lat') || key.contains('lng')) return Icons.location_on;
    if (key.contains('bcch')) return Icons.wifi_tethering;
    if (key.contains('cid')) return Icons.cell_tower;
    if (key.contains('azimuth')) return Icons.explore;
    return Icons.info_outline;
  }
}
