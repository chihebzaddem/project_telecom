import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'tool_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Site Search',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SearchPage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _searchText = '';
  String _filterBy = 'Site ID';

  final List<Map<String, String>> _allSites = [
    {'siteId': '17xxxx', 'siteName': 'Site XYZ'},
    {'siteId': '18abcd', 'siteName': '4G5G Kairouan'},
    {'siteId': '19efgh', 'siteName': 'Tunis Center'},
  ];

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> filteredSites = _allSites.where((site) {
      final query = _searchText.toLowerCase();
      if (_filterBy == 'Site ID') {
        return site['siteId']!.toLowerCase().contains(query);
      } else {
        return site['siteName']!.toLowerCase().contains(query);
      }
    }).toList();

    return Scaffold(
      appBar: CustomAppBar(title: 'Search'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Buttons Row
            Row(
              children: [
                SizedBox(
                  width:100,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9A01B),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Search', style: TextStyle(fontSize: 26, color:Colors.black)),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width:100,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C8F4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Navigate', style: TextStyle(fontSize: 26, color:Colors.black)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Filter dropdown
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

            const SizedBox(height: 16),

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
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Site results list
            Expanded(
              child: ListView(
                children: filteredSites.map((site) {
                  return Site(
                    siteId: site['siteId']!,
                    siteName: site['siteName']!,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Site extends StatelessWidget {
  final String siteId;
  final String siteName;

  const Site({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SVG Image
            SvgPicture.asset(
              'assets/site.svg',
              height: 32,
              width: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),

            // Text section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID: $siteId',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Name: $siteName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
