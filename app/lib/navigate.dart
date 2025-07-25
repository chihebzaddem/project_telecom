
/*import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app/widgets/arc.dart';

class TelecomSite {
  final String name;
  final LatLng location;
  final List<double> azimuths;

  TelecomSite(this.name, this.location, this.azimuths);
}

class Navigate extends StatefulWidget {
  final LatLng? initialLocation;

  const Navigate({super.key, this.initialLocation});

  @override
  State<Navigate> createState() => _NavigateState();
}

class _NavigateState extends State<Navigate> {
  LatLng? currentPosition;
  double currentZoom = 16.0;
  bool isLoading = true;
  String errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  List<TelecomSite> filteredSites = [];

  final List<TelecomSite> telecomSites = [
    TelecomSite("Site A", LatLng(35.6818, 10.1005), [20, 90, 170]),
    TelecomSite("XYZ Site", LatLng(35.6886, 10.0961), [0, 90, 180, 270]),
    TelecomSite("Site C", LatLng(35.6792, 10.1000), [0, 120, 240]),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check for location argument passed from DetailsPage
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is LatLng) {
      setState(() {
        currentPosition = args;
        isLoading = false;
      });
    } else {
      if (currentPosition == null) {
        _getCurrentLocation();
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          errorMessage = 'Location services are disabled.';
          isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            errorMessage = 'Location permissions are denied';
            isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          errorMessage = 'Location permissions are permanently denied';
          isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error getting location: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  List<Marker> buildMarkers(List<TelecomSite> sites) {
    List<Marker> markers = [];

    for (final site in sites) {
      markers.add(
        Marker(
          point: site.location,
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SvgPicture.asset(
                'assets/site.svg',
                width: 50,
                height: 50,
              ),
              ...site.azimuths.map((azimuth) {
                const double distance = 25;
                final double dx = distance * cos(azimuth * pi / 180);
                final double dy = distance * sin(azimuth * pi / 180);
                double arcSize = (currentZoom * 10).clamp(20, 300);

                return Transform.translate(
                  offset: Offset(dx, dy),
                  child: Transform.rotate(
                    angle: azimuth * pi / 180,
                    child: AzimuthArc(size: arcSize),

                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  void _onSearchChanged(String query) {
    if (query.length < 2) {
      // Hide suggestions if less than 2 chars
      setState(() {
        filteredSites = [];
      });
      return;
    }

    setState(() {
      filteredSites = telecomSites
          .where((site) => site.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _selectSite(TelecomSite site) {
    FocusScope.of(context).unfocus(); // Hide keyboard
    _searchController.text = site.name;
    filteredSites.clear();

    _mapController.move(site.location, 16);
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
    _mapController.mapEventStream.listen((event) {
    
      if (_mapController.zoom != currentZoom) {
      setState(() {
        currentZoom = _mapController.zoom;
        print("Current Zoom Level: $currentZoom");
      });
      }
    }
  );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigate')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : currentPosition == null
                  ? const Center(child: Text('Unable to determine location'))
                  : Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: currentPosition!,
                            initialZoom: currentZoom,
                            onPositionChanged: (MapPosition position, bool hasGesture) {
                              final newZoom = position.zoom;
                                    if (newZoom != null && newZoom != currentZoom) {
                                      setState(() {
                                        currentZoom = newZoom;
                                        print("Current Zoom Level: $currentZoom");
                                      });}},
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.yourapp',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: currentPosition!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                                ...buildMarkers(telecomSites),
                              ],
                            ),
                          ],
                        ),

                        Positioned(
                          top: 20,
                          left: 16,
                          right: 16,
                          child: Column(
                            children: [
                              Material(
                                elevation: 6,
                                borderRadius: BorderRadius.circular(24),
                                color: Colors.white,
                                child: TextField(
                                  controller: _searchController,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                    hintText: 'Search Telecom Site',
                                    hintStyle: TextStyle(color: Colors.grey[600]),
                                    prefixIcon:
                                        const Icon(Icons.search, color: Colors.black54),
                                    suffixIcon: _searchController.text.isEmpty
                                        ? null
                                        : GestureDetector(
                                            onTap: () {
                                              _searchController.clear();
                                              setState(() {
                                                filteredSites = [];
                                              });
                                            },
                                            child: const Icon(Icons.clear,
                                                color: Colors.black54),
                                          ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  onChanged: _onSearchChanged,
                                ),
                              ),
                              if (filteredSites.isNotEmpty)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  margin: const EdgeInsets.only(top: 8),
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: filteredSites.length,
                                    itemBuilder: (context, index) {
                                      final site = filteredSites[index];
                                      return ListTile(
                                        title: Text(site.name),
                                        onTap: () => _selectSite(site),
                                        splashColor: Colors.grey[200],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 90, // adjust as needed for spacing above the FAB
                          right: 16,
                          child: FloatingActionButton(
                            mini: true,
                            backgroundColor: Colors.white,
                            elevation: 6,
                            child: const Icon(Icons.my_location, color: Colors.black87),
                            onPressed: () {
                              if (currentPosition != null) {
                                _mapController.move(currentPosition!, 16);
                              }
                            },
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          right: 16,
                          child: FloatingActionButton(
                            mini: true,
                            backgroundColor: Colors.white,
                            elevation: 6,
                            child: const Icon(Icons.refresh, color: Colors.black87),
                            onPressed: _getCurrentLocation,
                          ),
                        ),
                      ],
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}*/

/*import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app/widgets/arc.dart';

class TelecomSite {
  final String name;
  final LatLng location;
  final List<double> azimuths;
   

  TelecomSite(this.name, this.location, this.azimuths);
}

class Navigate extends StatefulWidget {
  final LatLng? initialLocation;

  const Navigate({Key? key, this.initialLocation}) : super(key: key);

  @override
  _NavigateState createState() => _NavigateState();
}

class _NavigateState extends State<Navigate> {
  LatLng? currentPosition;
  double currentZoom = 16.0;
  bool isLoading = true;
  String errorMessage = '';

  final _searchController = TextEditingController();
  final _mapController = MapController();
  List<TelecomSite> filteredSites = [];

  final List<TelecomSite> telecomSites = [
    TelecomSite('XYZ Site', LatLng(35.6886, 10.0961), [0, 90, 180, 270]),
    TelecomSite('Site C', LatLng(35.6792, 10.1000), [0, 120, 240]),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Location services disabled.';
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          throw 'Location permission denied.';
        }
      }
      if (perm == LocationPermission.deniedForever) {
        throw 'Location permission permanently denied.';
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        currentPosition = LatLng(pos.latitude, pos.longitude);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      filteredSites = q.length < 2
          ? []
          : telecomSites.where((s) => s.name.toLowerCase().contains(q)).toList();
    });
  }

  void _selectSite(TelecomSite site) {
    FocusScope.of(context).unfocus();
    _searchController.text = site.name;
    filteredSites.clear();
    _mapController.move(site.location, currentZoom);
  }

List<Marker> _buildMarkers() {
  // Scale arc size from 10 at zoom 13 to 400 at zoom 17
  double arcSize = ((currentZoom - 13) / (17 - 13)) * (400 - 10) + 10;
  arcSize = arcSize.clamp(10, 400);

  // Scale svg size proportionally, say from 10 to 80
double svgSize = ((currentZoom - 13) / (17 - 13)) * (100 - 30) + 30;
svgSize = svgSize.clamp(30, 100);

  const double arcOffset = 10;  // fixed 10 px offset for arcs

  double markerSize = max(arcSize + arcOffset, svgSize) * 2 + 24;

  return telecomSites.map((site) {
    return Marker(
      point: site.location,
      width: markerSize,
      height: markerSize,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture.asset('assets/site.svg', width: svgSize, height: svgSize),
            for (var az in site.azimuths)
              Transform.translate(
                offset: Offset(arcOffset * cos(az * pi / 180), arcOffset * sin(az * pi / 180)),
                child: Transform.rotate(
                  angle: az * pi / 180,
                  child: AzimuthArc(size: arcSize),
                ),
              ),
          ],
        ),
      ),
    );
  }).toList();
}
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigate')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : currentPosition == null
                  ? const Center(child: Text('Unable to determine location'))
                  : Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: currentPosition!,
                            initialZoom: currentZoom,
                            onPositionChanged: (MapPosition position, bool hasGesture) {
                              final newZoom = position.zoom;
                              if (newZoom != null && newZoom != currentZoom) {
                                setState(() {
                                  currentZoom = newZoom;
                                  print('Zoom: $currentZoom');
                                });
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.yourapp',
                            ),
                            MarkerLayer(
                              key: ValueKey(currentZoom),
                              markers: [
                                Marker(
                                  point: currentPosition!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                                ..._buildMarkers(),
                              ],
                            ),
                          ],
                        ),

                        Positioned(
                          top: 16, left: 16, right: 16,
                          child: Column(
                            children: [
                              Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(24),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search Telecom Site',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: _searchController.text.isEmpty
                                        ? null
                                        : IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              _searchController.clear();
                                              filteredSites.clear();
                                            },
                                          ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true, fillColor: Colors.white,
                                  ),
                                ),
                              ),
                              if (filteredSites.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: filteredSites.map((site) => ListTile(
                                      title: Text(site.name),
                                      onTap: () => _selectSite(site),
                                    )).toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        Positioned(
                          bottom: 80, right: 16,
                          child: FloatingActionButton(
                            mini: true,
                            onPressed: () {
                              if (currentPosition != null) {
                                _mapController.move(currentPosition!, currentZoom);
                              }
                            },
                            child: const Icon(Icons.my_location),
                          ),
                        ),
                        Positioned(
                          bottom: 16, right: 16,
                          child: FloatingActionButton(
                            mini: true,
                            onPressed: _getCurrentLocation,
                            child: const Icon(Icons.refresh),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

*/
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app/widgets/arc.dart';
import 'dart:async'; 

class TelecomSite {
  final String name;
  final LatLng location;
  final List<double> azimuths;
  final int? bccp;  // Nullable
  final int? si;    // Nullable

  TelecomSite({
    required this.name,
    required this.location,
    required this.azimuths,
    this.bccp,
    this.si,
  });
}

class Navigate extends StatefulWidget {
  final LatLng? initialLocation;

  const Navigate({Key? key, this.initialLocation}) : super(key: key);

  @override
  _NavigateState createState() => _NavigateState();
}

class _NavigateState extends State<Navigate> {
  LatLng? currentPosition;
  double currentZoom = 16.0;
  bool isLoading = true;
  String errorMessage = '';
  StreamSubscription<Position>? _positionStream;

  final _searchController = TextEditingController();
  final _mapController = MapController();
  final _filterController = TextEditingController();
  List<TelecomSite> filteredSites = [];

  String filterType = 'bccp'; // Filter type: 'bccp' or 'si'

  final List<TelecomSite> telecomSites = [
    TelecomSite(
      name: 'XYZ Site',
      location: LatLng(35.6886, 10.0961),
      azimuths: [0, 90, 180, 270],
      bccp: 16,
      si: 456,
    ),
    TelecomSite(
      name: 'Site C',
      location: LatLng(35.6792, 10.1000),
      azimuths: [0, 120, 240],
      bccp: 17,
      si: null,
    ),
    TelecomSite(
      name: 'Site D',
      location: LatLng(35.6800, 10.1020),
      azimuths: [45, 135, 225, 315],
      bccp: 12,
      si: 456,
    ),
    // Add more sites here
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _startListeningLocation();
  }
  
void _startListeningLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    setState(() {
      errorMessage = 'Location services disabled.';
      isLoading = false;
    });
    return;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      setState(() {
        errorMessage = 'Location permission denied.';
        isLoading = false;
      });
      return;
    }
  }
  if (permission == LocationPermission.deniedForever) {
    setState(() {
      errorMessage = 'Location permission permanently denied.';
      isLoading = false;
    });
    return;
  }

  // Listen to position updates
  _positionStream = Geolocator.getPositionStream(
    locationSettings: LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // update every 10 meters movement (adjust as needed)
    ),
  ).listen((Position position) {
    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
      isLoading = false;
    });
  });
}

  Future<void> _getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Location services disabled.';
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          throw 'Location permission denied.';
        }
      }
      if (perm == LocationPermission.deniedForever) {
        throw 'Location permission permanently denied.';
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        currentPosition = LatLng(pos.latitude, pos.longitude);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      filteredSites = q.length < 2
          ? []
          : telecomSites.where((s) => s.name.toLowerCase().contains(q)).toList();
    });
  }

  void _selectSite(TelecomSite site) {
    FocusScope.of(context).unfocus();
    _searchController.text = site.name;
    filteredSites.clear();
    _mapController.move(site.location, currentZoom);
  }

  Color _getArcColor(TelecomSite site) {
    if (_filterController.text.isEmpty) return Colors.blue;

    final int? filterNum = int.tryParse(_filterController.text);
    if (filterNum == null) return Colors.blue;

    if (filterType == 'bccp' && site.bccp == filterNum) {
      return Colors.red;
    }
    if (filterType == 'si' && site.si == filterNum) {
      return Colors.red;
    }

    return Colors.blue;
  }

  List<Marker> _buildMarkers() {
    double arcSize = ((currentZoom - 13) / (17 - 13)) * (400 - 10) + 10;
    arcSize = arcSize.clamp(10, 400);

    double svgSize = ((currentZoom - 13) / (17 - 13)) * (100 - 30) + 30;
    svgSize = svgSize.clamp(30, 100);

    const double arcOffset = 10;
    double markerSize = max(arcSize + arcOffset, svgSize) * 2 + 24;

    return telecomSites.map((site) {
      return Marker(
        point: site.location,
        width: markerSize,
        height: markerSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SvgPicture.asset('assets/site.svg', width: svgSize, height: svgSize),
              for (var az in site.azimuths)
                Transform.translate(
                  offset: Offset(arcOffset * cos(az * pi / 180), arcOffset * sin(az * pi / 180)),
                  child: Transform.rotate(
                    angle: az * pi / 180,
                    child: AzimuthArc(
                      size: arcSize,
                      color: _getArcColor(site),
                    ),
                  ),
                ),
            ],
          ),
        
      );
    }).toList();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _searchController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigate')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : currentPosition == null
                  ? const Center(child: Text('Unable to determine location'))
                  : Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: currentPosition!,
                            initialZoom: currentZoom,
                            onPositionChanged: (MapPosition position, bool hasGesture) {
                              final newZoom = position.zoom;
                              if (newZoom != null && newZoom != currentZoom) {
                                setState(() {
                                  currentZoom = newZoom;
                                });
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.yourapp',
                            ),
                            MarkerLayer(
                              key: ValueKey(currentZoom),
                              markers: [
                                Marker(
                                  point: currentPosition!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                                ..._buildMarkers(),
                              ],
                            ),
                          ],
                        ),

                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            children: [
                              Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(24),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search Telecom Site',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: _searchController.text.isEmpty
                                        ? null
                                        : IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              _searchController.clear();
                                              filteredSites.clear();
                                            },
                                          ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      value: filterType,
                                      decoration: InputDecoration(
                                        labelText: 'Filter by',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      items: ['bccp', 'si'].map((String val) {
                                        return DropdownMenuItem<String>(
                                          value: val,
                                          child: Text(val.toUpperCase()),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            filterType = val;
                                            _filterController.clear();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: _filterController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Enter value',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      onChanged: (value) {
                                        setState(() {}); // update arcs on input change
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              if (filteredSites.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: filteredSites
                                        .map(
                                          (site) => ListTile(
                                            title: Text(site.name),
                                            onTap: () => _selectSite(site),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        Positioned(
                          bottom: 80,
                          right: 16,
                          child: FloatingActionButton(
                            mini: true,
                            onPressed: () {
                              if (currentPosition != null) {
                                _mapController.move(currentPosition!, currentZoom);
                              }
                            },
                            child: const Icon(Icons.my_location),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: FloatingActionButton(
                            mini: true,
                            onPressed: _getCurrentLocation,
                            child: const Icon(Icons.refresh),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

