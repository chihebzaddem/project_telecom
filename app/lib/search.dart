/*import 'package:flutter/material.dart';
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
}*/
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'details.dart';

class TelecomSite {
  final String id;
  final String siteName;
  final String type; // 2G / 3G / 4G
  final LatLng location;
  final List<int> azimuths;
  final Map<String, dynamic> rawData; // full JSON

  TelecomSite(this.id, this.siteName, this.type, this.location, this.azimuths, this.rawData);
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _searchText = '';
  String _filterBy = 'Site ID';

  bool _show2G = true;
  bool _show3G = true;
  bool _show4G = true;

  List<TelecomSite> telecomSites = [];

  @override
  void initState() {
    super.initState();
    loadSites();
  }

  Future<void> loadSites() async {
    final sites2g = await rootBundle.loadString('assets/data/sites_2g.json');
    final sites3g = await rootBundle.loadString('assets/data/sites_3g.json');
    final sites4g = await rootBundle.loadString('assets/data/sites_4g.json');

    final List<dynamic> data2g = json.decode(sites2g);
    final List<dynamic> data3g = json.decode(sites3g);
    final List<dynamic> data4g = json.decode(sites4g);

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    List<TelecomSite> parsed = [];

    for (var site in data2g) {
      final lat = parseDouble(site['LAT']);
      final lng = parseDouble(site['LONG']);
      if (lat == null || lng == null) continue;
      parsed.add(
        TelecomSite(
          site['GeranCellId']?.toString() ?? 'Unknown',
          site['SiteName'] ?? 'Unnamed',
          '2G',
          LatLng(lat, lng),
          [site['Azimuth'] is int ? site['Azimuth'] : int.tryParse(site['Azimuth']?.toString() ?? '') ?? 0],
          site,
        ),
      );
    }

    for (var site in data3g) {
      final lat = parseDouble(site['LAT']);
      final lng = parseDouble(site['LONG']);
      if (lat == null || lng == null) continue;
      parsed.add(
        TelecomSite(
          site['3GSiteID']?.toString() ?? 'Unknown',
          site['3GSiteName'] ?? 'Unnamed',
          '3G',
          LatLng(lat, lng),
          [site['AZIMUTH'] is int ? site['AZIMUTH'] : int.tryParse(site['AZIMUTH']?.toString() ?? '') ?? 0],
          site,
        ),
      );
    }

    for (var site in data4g) {
      final lat = parseDouble(site['LAT']);
      final lng = parseDouble(site['LONG']);
      if (lat == null || lng == null) continue;
      parsed.add(
        TelecomSite(
          site['eNBId']?.toString() ?? 'Unknown',
          site['Site_Name'] ?? 'Unnamed',
          '4G',
          LatLng(lat, lng),
          [site['AZIMUTH'] is int ? site['AZIMUTH'] : int.tryParse(site['AZIMUTH']?.toString() ?? '') ?? 0],
          site,
        ),
      );
    }

    setState(() {
      telecomSites = parsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAnyTypeSelected = _show2G || _show3G || _show4G;

    final filteredSites = telecomSites.where((site) {
      final query = _searchText.toLowerCase();

      // Check search filter
      bool matchesSearch;
      if (_filterBy == 'Site ID') {
        matchesSearch = site.id.toLowerCase().contains(query);
      } else {
        matchesSearch = site.siteName.toLowerCase().contains(query);
      }
      if (!matchesSearch) return false;

      // Check network type filter
      if (isAnyTypeSelected) {
        if (_show2G && site.type == '2G') return true;
        if (_show3G && site.type == '3G') return true;
        if (_show4G && site.type == '4G') return true;
        return false;
      }

      // No type filter active, show all
      return true;
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

            const SizedBox(height: 10),

            // Network type filter buttons
            Row(
              children: [
                Expanded(
                  child: FilterToggleButton(
                    label: '2G',
                    isSelected: _show2G,
                    onTap: () {
                      setState(() {
                        _show2G = !_show2G;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterToggleButton(
                    label: '3G',
                    isSelected: _show3G,
                    onTap: () {
                      setState(() {
                        _show3G = !_show3G;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterToggleButton(
                    label: '4G',
                    isSelected: _show4G,
                    onTap: () {
                      setState(() {
                        _show4G = !_show4G;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // List of sites
            Expanded(
              child: filteredSites.isEmpty
                  ? const Center(child: Text('No sites found'))
                  : ListView.builder(
                      itemCount: filteredSites.length,
                      itemBuilder: (context, index) {
                        final site = filteredSites[index];
                        return SiteCard(
                          site: site,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailsPage(rawData: site.rawData),
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
                    Text('ID: ${site.id}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Name: ${site.siteName}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Type: ${site.type}',
                        style: const TextStyle(
                            fontSize: 14, fontStyle: FontStyle.italic)),
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

class FilterToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterToggleButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }
}
