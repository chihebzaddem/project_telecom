/*import 'dart:math';
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
*/
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/widgets/arc.dart';


class TelecomSite {
  final String name;
  final LatLng location;
  final List<double> azimuths;
  final int? bccp;
  final int? si;

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
  String filterType = 'bccp';

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

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
        isLoading = false;
      });
    });
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

  void _openGoogleMapsDirections(LatLng destination) async {
  if (currentPosition == null) return;

  final Uri googleMapsAppUrl = Uri.parse(
    'comgooglemaps://?saddr=${currentPosition!.latitude},${currentPosition!.longitude}&daddr=${destination.latitude},${destination.longitude}&directionsmode=driving',
  );

  final Uri googleMapsWebUrl = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&origin=${currentPosition!.latitude},${currentPosition!.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving',
  );

  print('Trying to launch Google Maps app URL: $googleMapsAppUrl');

  if (await canLaunchUrl(googleMapsAppUrl)) {
    await launchUrl(googleMapsAppUrl, mode: LaunchMode.externalApplication);
  } else if (await canLaunchUrl(googleMapsWebUrl)) {
    print('App not available. Falling back to web URL: $googleMapsWebUrl');
    await launchUrl(googleMapsWebUrl, mode: LaunchMode.externalApplication);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not launch Google Maps')),
    );
  }
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
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(site.name),
                content: const Text('Do you want directions to this site?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openGoogleMapsDirections(site.location);
                    },
                    child: const Text('Show Directions'),
                  ),
                ],
              ),
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              SvgPicture.asset('assets/site.svg', width: svgSize, height: svgSize),
              for (var az in site.azimuths)
                Transform.translate(
                  offset: Offset(
                    arcOffset * cos(az * pi / 180),
                    arcOffset * sin(az * pi / 180),
                  ),
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
                            onPositionChanged:
                                (MapPosition position, bool hasGesture) {
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
                                  child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
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
                                        setState(() {});
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
                            onPressed: () => _startListeningLocation(),
                            child: const Icon(Icons.refresh),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
