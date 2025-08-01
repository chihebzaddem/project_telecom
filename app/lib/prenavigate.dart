import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'navigate.dart';

class PreNavigatePage extends StatefulWidget {
  const PreNavigatePage({Key? key}) : super(key: key);

  @override
  State<PreNavigatePage> createState() => _PreNavigatePageState();
}

class _PreNavigatePageState extends State<PreNavigatePage> {
  String? selectedSiteType;
  Map<String, bool> selectedVariables = {};

  // Variables available for each site type
  Map<String, List<String>> siteTypeVariables = {
    '2G': [],
    '3G': [],
    '4G': [],
    'Reseau': [], // No variables for Reseau - shows all sites with just basic info
  };

  // JSON data loaded
  List<Map<String, dynamic>> sites2g = [];
  List<Map<String, dynamic>> sites3g = [];
  List<Map<String, dynamic>> sites4g = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadJsonFiles();
  }

  Future<void> loadJsonFiles() async {
    final json2g = await rootBundle.loadString('assets/data/sites_2g.json');
    final json3g = await rootBundle.loadString('assets/data/sites_3g.json');
    final json4g = await rootBundle.loadString('assets/data/sites_4g.json');

    final List<dynamic> data2g = json.decode(json2g);
    final List<dynamic> data3g = json.decode(json3g);
    final List<dynamic> data4g = json.decode(json4g);

    setState(() {
      sites2g = List<Map<String, dynamic>>.from(data2g);
      sites3g = List<Map<String, dynamic>>.from(data3g);
      sites4g = List<Map<String, dynamic>>.from(data4g);

      // Extract variables (keys) from first items for each type (except 'Reseau')
      siteTypeVariables['2G'] = sites2g.isNotEmpty ? sites2g.first.keys.toList() : [];
      siteTypeVariables['3G'] = sites3g.isNotEmpty ? sites3g.first.keys.toList() : [];
      siteTypeVariables['4G'] = sites4g.isNotEmpty ? sites4g.first.keys.toList() : [];
      // 'Reseau' is empty

      loading = false;
    });
  }

  void onSiteTypeSelected(String type) {
    setState(() {
      selectedSiteType = type;
      if (type != 'Reseau') {
        selectedVariables = {
          for (var variable in siteTypeVariables[type] ?? []) variable: false
        };
      } else {
        selectedVariables = {};
      }
    });
  }

  void onGoToMapPressed() {
    // Prepare selected sites based on selected type
    List<Map<String, dynamic>> selectedSites = [];

    if (selectedSiteType == '2G') {
      selectedSites = sites2g;
    } else if (selectedSiteType == '3G') {
      selectedSites = sites3g;
    } else if (selectedSiteType == '4G') {
      selectedSites = sites4g;
    } else if (selectedSiteType == 'Reseau') {
      // Show all sites for Reseau
      selectedSites = [...sites2g, ...sites3g, ...sites4g];
    }

    // Build a set of selected variables only (to show in details/popups)
    final selectedVars = selectedVariables.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toSet();

    Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => Navigate(
      sites: selectedSites,
      selectedVars: selectedVars,
      siteType: selectedSiteType!,
    ),
  ),
);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final variables = selectedSiteType != null
        ? siteTypeVariables[selectedSiteType] ?? []
        : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Network '),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Site Type',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['2G', '3G', '4G', 'Reseau'].map((type) {
                    final isSelected = selectedSiteType == type;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: () => onSiteTypeSelected(type),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isSelected ? Colors.teal : Colors.grey[300],
                            foregroundColor:
                                isSelected ? Colors.white : Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            type,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
                if (selectedSiteType != null && selectedSiteType != 'Reseau')
                  Text(
                    'Select Variables for $selectedSiteType',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                if (selectedSiteType != null && selectedSiteType != 'Reseau')
                  const SizedBox(height: 10),
                if (selectedSiteType != null && selectedSiteType != 'Reseau')
                  Expanded(
                    child: ListView(
                      children: variables.map((variable) {
                        return CheckboxListTile(
                          title: Text(variable),
                          value: selectedVariables[variable] ?? false,
                          onChanged: (bool? value) {
                            setState(() {
                              selectedVariables[variable] = value ?? false;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                if (selectedSiteType == 'Reseau')
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),

                  ),
              ],
            ),
          ),

          Positioned(
            bottom: 10,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: selectedSiteType == null ? null : onGoToMapPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      selectedSiteType == null ? Colors.grey : Colors.teal,
                ),
                child: const Text(
                  'Go to Map',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
