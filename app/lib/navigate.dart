/*import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class Navigate extends StatefulWidget {
  const Navigate({super.key});

  @override
  State<Navigate> createState() => _NavigateState();
}

class _NavigateState extends State<Navigate> {
  LatLng? currentPosition;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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
                  : FlutterMap(
                      options: MapOptions(
                        center: currentPosition!,
                        zoom: 25,
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
                              width: 40,
                              height: 40,
                              point: currentPosition!,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
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
/*
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Navigate extends StatefulWidget {
  const Navigate({super.key});

  @override
  State<Navigate> createState() => _NavigateState();
}

class _NavigateState extends State<Navigate> {
  LatLng? currentPosition;
  bool isLoading = true;
  String errorMessage = '';

  // 🔶 Custom marker locations
  final List<LatLng> customLocations = [
    LatLng(35.6818, 	10.1005), 
    LatLng(35.6886, 10.0961), 
    LatLng(	35.6792, 10.1000),  
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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
                  : FlutterMap(
                      options: MapOptions(
                        initialCenter: currentPosition!,
                        initialZoom: 16,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.yourapp',
                        ),
                        MarkerLayer(
                          markers: [
                            // 🔴 Current location marker
                            Marker(
                              width: 40,
                              height: 40,
                              point: currentPosition!,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                            // 🟡 Custom markers
                            ...customLocations.map((loc) {
                              return Marker(
                                width: 40,
                                height: 40,
                                point: loc,
                                child: SvgPicture.asset('assets/site.svg',
                                  width: 40,
                                 height: 40,),
                              );
                            })
                          ],
                        ),
                      ],
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.refresh),
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

class TelecomSite {
  final LatLng location;
  final List<double> azimuths;

  TelecomSite(this.location, this.azimuths);
}

class Navigate extends StatefulWidget {
  const Navigate({super.key});

  @override
  State<Navigate> createState() => _NavigateState();
}

class _NavigateState extends State<Navigate> {
  LatLng? currentPosition;
  bool isLoading = true;
  String errorMessage = '';

  final List<TelecomSite> telecomSites = [
    TelecomSite(LatLng(35.6818, 10.1005), [20, 90, 170]),
    TelecomSite(LatLng(35.6886, 10.0961), [0, 90, 180, 270]),
    TelecomSite(LatLng(35.6792, 10.1000), [0, 120, 240]),
  ];

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

                      return Transform.translate(
                        offset: Offset(dx, dy),
                        child: Transform.rotate(
                          angle: azimuth * pi / 180,
                          child: const AzimuthArc(size: 50),
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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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
                  : FlutterMap(
                      options: MapOptions(
                        initialCenter: currentPosition!,
                        initialZoom: 16,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

