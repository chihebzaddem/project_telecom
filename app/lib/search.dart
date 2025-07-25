import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

import 'details.dart';

class TelecomSite {
  final String id;
  final String siteName;
  final LatLng location;
  final List<int> azimuths;

  TelecomSite(this.id, this.siteName, this.location, this.azimuths);
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _searchText = '';
  String _filterBy = 'Site ID';

  final List<TelecomSite> telecomSites = [
    TelecomSite('172002', "Site A", LatLng(35.6818, 10.1005), [20, 90, 170]),
    TelecomSite('232465', "XYZ Site", LatLng(35.6886, 10.0961), [0, 90, 180, 270]),
    TelecomSite('300000', "Site C", LatLng(35.6792, 10.1000), [0, 120, 240]),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredSites = telecomSites.where((site) {
      final query = _searchText.toLowerCase();
      if (_filterBy == 'Site ID') {
        return site.id.toLowerCase().contains(query);
      } else {
        return site.siteName.toLowerCase().contains(query);
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter dropdown row
            Row(
              children: [
                const Text("Filter by: ", style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filterBy,
                  items: ['Site ID', 'Site Name'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _filterBy = newValue!;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Search bar
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: filteredSites.length,
                itemBuilder: (context, index) {
                  final site = filteredSites[index];
                  return SiteCard(
                    site: site,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailsPage(  id: site.id,
                                                              name: site.siteName,
                                                              location: site.location,
                                                              angles: site.azimuths,),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SiteCard extends StatelessWidget {
  final TelecomSite site;
  final VoidCallback onTap;

  const SiteCard({
    super.key,
    required this.site,
    required this.onTap,
  });

   @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/site.svg',
                height: 32,
                width: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: ${site.id}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Name: ${site.siteName}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}