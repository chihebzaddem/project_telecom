import 'package:flutter/material.dart';
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
