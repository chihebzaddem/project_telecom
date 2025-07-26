/*import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class DetailsPage extends StatelessWidget {
  final String id;
  final String name;
  final LatLng location;
  final List<int> angles;

  const DetailsPage({
    super.key,
    required this.id,
    required this.name,
    required this.location,
    required this.angles,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Details of $name')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: $id', style: const TextStyle(fontSize: 18)),
            Text('Name: $name', style: const TextStyle(fontSize: 18)),
            Text('Latitude: ${location.latitude}', style: const TextStyle(fontSize: 18)),
            Text('Longitude: ${location.longitude}', style: const TextStyle(fontSize: 18)),
            Text('Angles: ${angles.join(', ')}', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity, // Make button full width
            height: 50, // Fixed height for the button
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/Navigate',
                  arguments: location,
                );
              },
              child: const Text(
                'Open Map',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
*/
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class DetailsPage extends StatelessWidget {
  final Map<String, dynamic> rawData;

  const DetailsPage({super.key, required this.rawData});

  @override
  Widget build(BuildContext context) {
    // Try to get location if available
    final location = LatLng(
      double.tryParse(rawData['latitude']?.toString() ?? '') ?? 0.0,
      double.tryParse(rawData['longitude']?.toString() ?? '') ?? 0.0,
    );

    // Handle angles if provided as list
    final angles = (rawData['angles'] is List)
        ? List<int>.from(rawData['angles'])
        : [];

    return Scaffold(
      appBar: AppBar(title: Text('Details of ${rawData['name'] ?? 'Site'}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: rawData.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final entry = rawData.entries.elementAt(index);
            final key = entry.key;
            final value = entry.value;

            return ListTile(
              title: Text(
                key[0].toUpperCase() + key.substring(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(value.toString()),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/Navigate',
                  arguments: location,
                );
              },
              child: const Text(
                'Open Map',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
