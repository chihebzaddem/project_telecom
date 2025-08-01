
/*import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/widgets/arc.dart';
import 'details.dart';

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
  TelecomSite? selectedSite;

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
    setState(() {
      selectedSite = site;
    });
  }

  void _openGoogleMapsDirections(LatLng destination) async {
    if (currentPosition == null) return;

    final Uri googleMapsAppUrl = Uri.parse(
      'comgooglemaps://?saddr=${currentPosition!.latitude},${currentPosition!.longitude}&daddr=${destination.latitude},${destination.longitude}&directionsmode=driving',
    );

    final Uri googleMapsWebUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${currentPosition!.latitude},${currentPosition!.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving',
    );

    if (await canLaunchUrl(googleMapsAppUrl)) {
      await launchUrl(googleMapsAppUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(googleMapsWebUrl)) {
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

    if (filterType == 'bccp' && site.bccp == filterNum) return Colors.red;
    if (filterType == 'si' && site.si == filterNum) return Colors.red;
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
            setState(() {
              selectedSite = site;
            });
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

Widget _buildSitePopup() {
  if (selectedSite == null) return const SizedBox.shrink();

  return Positioned(
    bottom: 120,
    left: 16,
    right: 16,
    child: AnimatedOpacity(
      opacity: selectedSite != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedSite!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => selectedSite = null),
                  ),
                ],
              ),
            ),

            // Details section with buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedSite!.bccp != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.signal_cellular_alt_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text("BCCP: ${selectedSite!.bccp}"),
                        ],
                      ),
                    ),
                  if (selectedSite!.si != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text("SI: ${selectedSite!.si}"),
                        ],
                      ),
                    ),

                  // Buttons Row: Show Directions + Show Details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _openGoogleMapsDirections(selectedSite!.location);
                            setState(() => selectedSite = null);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.directions),
                          label: const Text("Show Directions"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailsPage(
                                  rawData: {
                                    'name': selectedSite!.name,
                                    'latitude': selectedSite!.location.latitude,
                                    'longitude': selectedSite!.location.longitude,
                                    'angles': selectedSite!.azimuths.map((e) => e.toInt()).toList(),
                                    'bccp': selectedSite!.bccp,
                                    'si': selectedSite!.si,
                                  },
                                ),
                              ),
                            );
                            setState(() => selectedSite = null);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            backgroundColor: const Color(0xFF42A5F5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.info_outline),
                          label: const Text("Show Details"),
                        ),
                      ),
                    ],
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
                        _buildSitePopup(),
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
*/
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:app/widgets/arc.dart'; 
import 'site_details_page.dart'; 

class Navigate extends StatefulWidget {
  final List<Map<String, dynamic>> sites; 
  final Set<String> selectedVars;          
  final String siteType;                 

  const Navigate({
    Key? key,
    required this.sites,
    required this.selectedVars,
    required this.siteType,
  }) : super(key: key);

  @override
  _NavigateState createState() => _NavigateState();
}

class _NavigateState extends State<Navigate> {
  LatLng? currentPosition;

  String filterVariable = 'bcchNo'; 
  final _filterController = TextEditingController();
  final _searchController = TextEditingController();
  final _mapController = MapController();

  double currentZoom = 16.0;
  bool isLoading = true;
  String errorMessage = '';

  StreamSubscription<Position>? _positionStream;

  List<Map<String, dynamic>> filteredSites = [];
  Map<String, dynamic>? selectedSite;

  @override
  void initState() {
    super.initState();
    _prepareSites();
    _searchController.addListener(_onSearchChanged);
    _startListeningLocation();
  }

  void _prepareSites() {
    for (var site in widget.sites) {
      site['lat'] = site['LAT'] ?? site['latitude'] ?? site['lat'] ?? site['location']?['latitude'];
      site['lng'] = site['LONG'] ?? site['longitude'] ?? site['lng'] ?? site['location']?['longitude'];
      site['name'] = site['SiteName'] ?? site['Site_Name'] ?? site['3GSiteName'] ?? site['SiteID_x'] ?? site['name'] ?? 'Unknown';
      site['id'] = site['SiteID_x'] ?? site['3GSiteID'] ?? site['3GID'] ?? site['id'] ?? 'Unknown';

      // Normalize azimuths
      final azRaw = site['AZIMUTH'] ?? site['Azimuth'];
      if (azRaw is num) {
        site['azimuths'] = [azRaw.toDouble()];
      } else if (azRaw is List) {
        site['azimuths'] = azRaw.map((e) => double.tryParse(e.toString()) ?? 0.0).toList();
      } else {
        site['azimuths'] = [];
      }
    }
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
          : widget.sites.where((site) {
              final name = (site['name'] ?? '').toString().toLowerCase();
              final idStr = (site['id'] ?? '').toString().toLowerCase();
              return name.contains(q) || idStr.contains(q);
            }).toList();
    });
  }

  void _selectSite(Map<String, dynamic> site) {
    FocusScope.of(context).unfocus();
    _searchController.text = site['name'] ?? '';
    filteredSites.clear();

    final lat = site['lat'];
    final lng = site['lng'];
    if (lat != null && lng != null) {
      _mapController.move(LatLng(lat, lng), currentZoom);
    }

    setState(() {
      selectedSite = site;
    });
  }

  int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  List<Marker> _buildMarkers() {
    double arcSize = ((currentZoom - 13) / (17 - 13)) * (400 - 10) + 10;
    arcSize = arcSize.clamp(10, 400);
    double svgSize = ((currentZoom - 13) / (17 - 13)) * (100 - 30) + 30;
    svgSize = svgSize.clamp(30, 100);
    const double arcOffset = 10;
    double markerSize = max(arcSize + arcOffset, svgSize) * 2 + 24;

    final filterText = _filterController.text.trim();
    final filterTextInt = int.tryParse(filterText);

    return widget.sites.map((site) {
      final lat = site['lat'];
      final lng = site['lng'];

      if (lat == null || lng == null) {
        return Marker(point: LatLng(0, 0), width: 0, height: 0, child: Container());
      }

      List<double> azimuths = [];
      if (site.containsKey('azimuths')) {
        final list = site['azimuths'];
        if (list is List) {
          azimuths = list.map<double>((e) => (e is num ? e.toDouble() : 0)).toList();
        }
      } else if (site.containsKey('AZIMUTH') || site.containsKey('Azimuth')) {
        final az = site['AZIMUTH'] ?? site['Azimuth'];
        if (az is num) {
          azimuths = [az.toDouble()];
        }
      }

      bool isFilteredMatch = false;
      if (filterText.isNotEmpty) {
        final val = site[filterVariable] ?? site[filterVariable.toUpperCase()] ?? site[filterVariable.toLowerCase()];
        if (val != null) {
          if (filterTextInt != null) {
            isFilteredMatch = parseInt(val) == filterTextInt;
          } else {
            isFilteredMatch = val.toString().contains(filterText);
          }
        }
      }

      Color arcColor = isFilteredMatch ? Colors.red : Colors.blue;

      return Marker(
        key: ValueKey(site),
        point: LatLng(lat, lng),
        width: markerSize,
        height: markerSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  selectedSite = site;
                });
              },
              child: SvgPicture.asset('assets/site.svg', width: svgSize, height: svgSize),
            ),
            for (var az in azimuths)
              IgnorePointer(
                child: Transform.translate(
                  offset: Offset(
                    arcOffset * cos(az * pi / 180),
                    arcOffset * sin(az * pi / 180),
                  ),
                  child: Transform.rotate(
                    angle: az * pi / 180,
                    child: AzimuthArc(
                      size: arcSize,
                      color: arcColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  void _openGoogleMapsDirections(LatLng destination) async {
    if (currentPosition == null) return;

    final Uri googleMapsAppUrl = Uri.parse(
      'comgooglemaps://?saddr=${currentPosition!.latitude},${currentPosition!.longitude}&daddr=${destination.latitude},${destination.longitude}&directionsmode=driving',
    );

    final Uri googleMapsWebUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${currentPosition!.latitude},${currentPosition!.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving',
    );

    if (await canLaunchUrl(googleMapsAppUrl)) {
      await launchUrl(googleMapsAppUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(googleMapsWebUrl)) {
      await launchUrl(googleMapsWebUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch Google Maps')),
      );
    }
  }

  Widget _buildSitePopup() {
    if (selectedSite == null) return const SizedBox.shrink();

    final lat = selectedSite!['lat'];
    final lng = selectedSite!['lng'];

    return Positioned(
      bottom: 120,
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 300),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400,
            ),
            child: Material(
              elevation: 14,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedSite!['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${selectedSite!['id'] ?? 'Unknown'}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 24),
                          onPressed: () => setState(() => selectedSite = null),
                        ),
                      ],
                    ),
                  ),

                  // Location info
                  if (lat != null && lng != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Text(
                        'Location: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  const Divider(height: 1, thickness: 1),

                  // Scrollable variables list
                  if (widget.selectedVars.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(
                        maxHeight: 180,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final varName in widget.selectedVars)
                              if (selectedSite![varName] != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    '$varName: ${selectedSite![varName].toString()}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),

                  const Divider(height: 1, thickness: 1),

                  // Buttons row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (lat != null && lng != null) {
                                _openGoogleMapsDirections(LatLng(lat, lng));
                                setState(() => selectedSite = null);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              minimumSize: const Size.fromHeight(48), // fixed height
                            ),
                            icon: const Icon(Icons.directions),
                            label: const Text(
                              "Directions",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SiteDetailsPage(siteData: selectedSite!),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              minimumSize: const Size.fromHeight(48), // fixed height
                            ),
                            icon: const Icon(Icons.info),
                            label: const Text("Details"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _filterController.dispose();
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

                        // Filter and search UI
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            children: [
                              // Filter row: dropdown + number input
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          value: filterVariable,
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(() {
                                                filterVariable = value;
                                              });
                                            }
                                          },
                                          items: const [
                                            DropdownMenuItem(value: 'bcchNo', child: Text('BCCH')),
                                            DropdownMenuItem(value: 'cId', child: Text('CID')),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 4,
                                    child: Material(
                                      elevation: 4,
                                      borderRadius: BorderRadius.circular(24),
                                      child: TextField(
                                        controller: _filterController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: 'Enter number to filter',
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(24),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          suffixIcon: _filterController.text.isEmpty
                                              ? null
                                              : IconButton(
                                                  icon: const Icon(Icons.clear),
                                                  onPressed: () {
                                                    setState(() {
                                                      _filterController.clear();
                                                    });
                                                  },
                                                ),
                                        ),
                                        onChanged: (value) {
                                          setState(() {}); // To rebuild markers on input change
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Search bar (name/id)
                              Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(24),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search Telecom Site (by name or ID)',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: _searchController.text.isEmpty
                                        ? null
                                        : IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              setState(() {
                                                _searchController.clear();
                                                filteredSites.clear();
                                              });
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
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: filteredSites.length,
                                    itemBuilder: (context, index) {
                                      final site = filteredSites[index];
                                      return ListTile(
                                        title: Text(site['name'] ?? 'Unknown'),
                                        subtitle: Text('ID: ${site['id'] ?? 'Unknown'}'),
                                        onTap: () => _selectSite(site),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Popup with site details and buttons
                        _buildSitePopup(),

                        // Floating button bottom right to zoom on current location
                        Positioned(
                          bottom: 16,
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

                        // Refresh location button
                        Positioned(
                          bottom: 80,
                          right: 16,
                          child: FloatingActionButton(
                            mini: true,
                            onPressed: _startListeningLocation,
                            child: const Icon(Icons.refresh),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
