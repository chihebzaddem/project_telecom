import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('telecom_sites');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SitesProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telecom Site Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AdminScreen(),
    );
  }
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      if (!Hive.isBoxOpen('telecom_sites')) {
        await Hive.openBox('telecom_sites');
      }
      await Provider.of<SitesProvider>(context, listen: false).init();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final sitesProvider = Provider.of<SitesProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telecom Site Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            sitesProvider.setNetworkType(['2G', '3G', '4G'][index]);
          },
          tabs: const [
            Tab(text: '2G'),
            Tab(text: '3G'),
            Tab(text: '4G'),
          ],
        ),
      ),
      body: sitesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    decoration: InputDecoration(
                      labelText: 'Search Sites',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSiteListView('2G'),
                      _buildSiteListView('3G'),
                      _buildSiteListView('4G'),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'import',
            onPressed: _showImportDialog,
            mini: true,
            child: const Icon(Icons.upload_file),
            tooltip: "Import from Excel",
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _showAddEditDialog(context, null),
            child: const Icon(Icons.add),
            tooltip: 'Add new site',
          ),
        ],
      ),
    );
  }

  Widget _buildSiteListView(String networkType) {
    return Consumer<SitesProvider>(
      builder: (context, provider, _) {
        final sites = provider.getSitesByType(networkType);
        final fieldNames = provider.getFieldNames(networkType);
        final filteredSites = sites.where((site) {
          return site[fieldNames[0]]?.toString().toLowerCase().contains(_searchQuery) ?? false;
        }).toList();

        if (filteredSites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No sites found'),
                TextButton(
                  onPressed: _showImportDialog,
                  child: const Text('Import from Excel'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: filteredSites.length,
          itemBuilder: (context, index) {
            final site = filteredSites[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                title: Text(site[fieldNames[0]]?.toString() ?? 'Unnamed Site'),
                subtitle: Text('ID: ${site[fieldNames[1]]?.toString() ?? 'N/A'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showAddEditDialog(context, index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _confirmDelete(context, index),
                    ),
                  ],
                ),
                onTap: () => _showSiteDetails(context, site, fieldNames),
              ),
            );
          },
        );
      },
    );
  }

  void _showSiteDetails(BuildContext context, Map<String, dynamic> site, List<String> fields) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(site[fields[0]]?.toString() ?? 'Site Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: fields.map((field) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: '$field: ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: site[field]?.toString() ?? 'N/A'),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showImportDialog() {
    final provider = Provider.of<SitesProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import Sites'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select an Excel file containing:'),
              SizedBox(height: 10),
              Text('- Header row with column names'),
              Text('- Data rows with site information'),
              SizedBox(height: 10),
              Text('Supported formats: .xlsx, .xls'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Processing file...')),
                );

                final result = await provider.importSitesFromExcel();
                
                if (!mounted) return;
                
                scaffoldMessenger.hideCurrentSnackBar();
                
                if (result.isSuccess) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('${result.count} sites imported')),
                  );
                } else if (result.isError) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error: ${result.error}')),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('No valid sites found')),
                  );
                }
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }

  void _showAddEditDialog(BuildContext context, int? index) {
    final provider = Provider.of<SitesProvider>(context, listen: false);
    final isEditing = index != null;
    final networkType = provider.currentNetworkType;
    final sites = provider.getSitesByType(networkType);
    final site = isEditing ? sites[index] : {};
    final fieldNames = provider.getFieldNames(networkType);
    
    final controllers = Map.fromIterables(
      fieldNames,
      fieldNames.map((field) => 
        TextEditingController(text: site[field]?.toString() ?? '')),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Site' : 'Add New Site'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: fieldNames.map((field) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextField(
                    controller: controllers[field],
                    decoration: InputDecoration(
                      labelText: field,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newSite = Map<String, String>.fromIterables(
                  fieldNames,
                  fieldNames.map((field) => controllers[field]!.text),
                );

                try {
                  if (isEditing) {
                    await provider.updateSite(networkType, index, newSite);
                  } else {
                    await provider.addSite(networkType, newSite);
                  }
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditing 
                              ? 'Site updated successfully' 
                              : 'Site added successfully',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, int index) {
    final provider = Provider.of<SitesProvider>(context, listen: false);
    final networkType = provider.currentNetworkType;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this site?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await provider.deleteSite(networkType, index);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Site deleted successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class SitesProvider with ChangeNotifier {
  late Box _storageBox;
  final Map<String, List<Map<String, dynamic>>> _sites = {
    '2G': [],
    '3G': [],
    '4G': [],
  };
  
  String _currentNetworkType = '2G';
  bool _isLoading = false;

  Future<void> init() async {
    _storageBox = Hive.box('telecom_sites');
    await _loadAllData();
  }

  Future<void> _loadAllData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      for (final type in _sites.keys) {
        final data = _storageBox.get(type);
        if (data != null && data is List) {
          _sites[type] = List<Map<String, dynamic>>.from(
            data.map((item) => Map<String, dynamic>.from(item)),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveNetworkType(String type) async {
    await _storageBox.put(type, _sites[type]);
  }

  String get currentNetworkType => _currentNetworkType;
  bool get isLoading => _isLoading;
  
  List<Map<String, dynamic>> getSitesByType(String type) {
    return _sites[type] ?? [];
  }

  void setNetworkType(String type) {
    _currentNetworkType = type;
    notifyListeners();
  }

  Future<ImportResult> importSitesFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null) return ImportResult.cancelled();

      final file = result.files.single;
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      int sitesImported = 0;

      for (var table in excel.tables.keys) {
        final rows = excel.tables[table]!.rows;
        if (rows.length < 2) continue;

        final headers = rows[0].map((cell) => cell?.value?.toString().trim() ?? '').toList();
        final networkType = _detectNetworkType(headers);

        if (networkType == null) {
          debugPrint('Could not detect network type for sheet $table');
          continue;
        }

        for (var i = 1; i < rows.length; i++) {
          final row = rows[i];
          if (row.isEmpty || row[0]?.value == null) continue;

          final siteData = <String, dynamic>{};
          bool isValid = true;

          for (var j = 0; j < headers.length; j++) {
            if (headers[j].isEmpty) continue;
            
            final cellValue = row[j]?.value;
            siteData[headers[j]] = cellValue?.toString().trim() ?? '';
            
            // Validate required fields
            if (getRequiredFieldsForType(networkType).contains(headers[j])) {
              if (cellValue == null || cellValue.toString().trim().isEmpty) {
                isValid = false;
                break;
              }
            }
          }

          if (isValid && siteData.isNotEmpty) {
            try {
              await addSite(networkType, siteData);
              sitesImported++;
            } catch (e) {
              debugPrint('Error adding site: $e');
            }
          }
        }
      }

      notifyListeners();
      return sitesImported > 0 
          ? ImportResult.success(sitesImported)
          : ImportResult.empty();
    } catch (e, stackTrace) {
      debugPrint('Import error: $e\n$stackTrace');
      return ImportResult.error(e.toString());
    }
  }

  String? _detectNetworkType(List<String> headers) {
    final lowerHeaders = headers.map((h) => h.toLowerCase()).toList();
    
    if (lowerHeaders.contains('bscname') || 
        lowerHeaders.contains('gerancellid')) {
      return '2G';
    }
    
    if (lowerHeaders.contains('rnc_name') || 
        lowerHeaders.contains('utrancellid')) {
      return '3G';
    }
    
    if (lowerHeaders.contains('enbid') || 
        lowerHeaders.contains('eutrancellfddid')) {
      return '4G';
    }
    
    return null;
  }

  Future<void> addSite(String networkType, Map<String, dynamic> siteData) async {
    try {
      final requiredFields = getRequiredFieldsForType(networkType);
      for (var field in requiredFields) {
        if (siteData[field] == null || siteData[field].toString().isEmpty) {
          throw Exception('Missing required field: $field for $networkType');
        }
      }

      final cleanedData = <String, dynamic>{};
      final allFields = getFieldNames(networkType);
      
      for (var field in allFields) {
        cleanedData[field] = siteData[field]?.toString() ?? '';
      }

      if (cleanedData['id']?.isEmpty ?? true) {
        cleanedData['id'] = '$networkType-${DateTime.now().millisecondsSinceEpoch}';
      }

      _sites[networkType]?.add(cleanedData);
      await _saveNetworkType(networkType);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding site: $e');
      rethrow;
    }
  }

  List<String> getRequiredFieldsForType(String networkType) {
    switch (networkType) {
      case '2G':
        return ['BscName', 'GeranCellId', 'LAT', 'LONG'];
      case '3G':
        return ['RNC_Name', 'UtranCellId', 'LAT', 'LONG'];
      case '4G':
        return ['eNBId', 'EUtranCellFDDId', 'LAT', 'LONG'];
      default:
        return [];
    }
  }

  Future<void> updateSite(String networkType, int index, Map<String, dynamic> updatedSite) async {
    _sites[networkType]?[index] = Map<String, dynamic>.from(updatedSite);
    await _saveNetworkType(networkType);
    notifyListeners();
  }

  Future<void> deleteSite(String networkType, int index) async {
    _sites[networkType]?.removeAt(index);
    await _saveNetworkType(networkType);
    notifyListeners();
  }

  List<String> getFieldNames(String networkType) {
    switch (networkType) {
      case '2G':
        return [
          'BscName', 'GeranCellId', 'SiteName', 'LAT', 'LONG', 
          'Azimuth', 'sector', 'id'
        ];
      case '3G':
        return [
          'RNC_Name', 'UtranCellId', '3GSiteName', 'LAT', 'LONG',
          'primaryScramblingCode', 'id'
        ];
      case '4G':
        return [
          'eNBId', 'EUtranCellFDDId', 'Site_Name', 'LAT', 'LONG',
          'tac', 'id'
        ];
      default:
        return [];
    }
  }
}

class ImportResult {
  final bool isSuccess;
  final bool isEmpty;
  final bool isError;
  final bool isCancelled;
  final int? count;
  final String? error;

  ImportResult._({
    required this.isSuccess,
    required this.isEmpty,
    required this.isError,
    required this.isCancelled,
    this.count,
    this.error,
  });

  factory ImportResult.success(int count) => ImportResult._(
    isSuccess: true, isEmpty: false, isError: false, isCancelled: false, count: count);

  factory ImportResult.empty() => ImportResult._(
    isSuccess: false, isEmpty: true, isError: false, isCancelled: false);

  factory ImportResult.error(String error) => ImportResult._(
    isSuccess: false, isEmpty: false, isError: true, isCancelled: false, error: error);

  factory ImportResult.cancelled() => ImportResult._(
    isSuccess: false, isEmpty: false, isError: false, isCancelled: true);
}

class AuthProvider with ChangeNotifier {
  String? _username;
  bool _isLoading = false;

  String? get username => _username;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _username != null;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    if (username == 'admin' && password == 'admin123') {
      _username = username;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _username = null;
    notifyListeners();
  }
}
