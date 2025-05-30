// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:permission_handler/permission_handler.dart';

// class LocationSelector extends StatefulWidget {
//   final Function(String) onLocationSelected;
//   final String? initialLocation;

//   const LocationSelector({
//     super.key,
//     required this.onLocationSelected,
//     this.initialLocation,
//   });

//   @override
//   State<LocationSelector> createState() => _LocationSelectorState();
// }

// class _LocationSelectorState extends State<LocationSelector> {
//   GoogleMapController? _controller;
//   LatLng _selectedLocation = const LatLng(15.5054, -88.0251); // Ubicación por defecto
//   String _selectedAddress = '';
//   bool _isLoading = false;
//   Set<Marker> _markers = {};

//   @override
//   void initState() {
//     super.initState();
//     _initializeLocation();
//   }

//   Future<void> _initializeLocation() async {
//     if (widget.initialLocation != null && widget.initialLocation!.isNotEmpty) {
//       _parseInitialLocation(widget.initialLocation!);
//     } else {
//       await _getCurrentLocation();
//     }
//   }

//   void _parseInitialLocation(String location) {
//     try {
//       final parts = location.split(', ');
//       final lat = double.parse(parts[0].split('Lat: ')[1]);
//       final lng = double.parse(parts[1].split('Lng: ')[1]);

//       setState(() {
//         _selectedLocation = LatLng(lat, lng);
//         _selectedAddress = parts.length > 2 ? parts[2].split('Dirección: ')[1] : '';
//         _updateMarker();
//       });
//     } catch (e) {
//       debugPrint('Error parsing initial location: $e');
//     }
//   }

//   Future<void> _getCurrentLocation() async {
//     setState(() => _isLoading = true);

//     if (await Permission.location.request().isGranted) {
//       final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//       final newLocation = LatLng(position.latitude, position.longitude);

//       setState(() {
//         _selectedLocation = newLocation;
//         _isLoading = false;
//       });

//       _updateMarker();
//       await _getAddressFromCoordinates(newLocation);

//       _controller?.animateCamera(
//         CameraUpdate.newCameraPosition(CameraPosition(target: newLocation, zoom: 16)),
//       );
//     } else {
//       setState(() => _isLoading = false);
//       _showPermissionDialog();
//     }
//   }

//   void _updateMarker() {
//     setState(() {
//       _markers = {
//         Marker(
//           markerId: const MarkerId('selected_location'),
//           position: _selectedLocation,
//           infoWindow: InfoWindow(title: 'Ubicación seleccionada', snippet: _selectedAddress),
//         ),
//       };
//     });
//   }

//   Future<void> _getAddressFromCoordinates(LatLng location) async {
//     try {
//       final placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
//       if (placemarks.isNotEmpty) {
//         final placemark = placemarks.first;
//         final address = '${placemark.street ?? ''}, ${placemark.locality ?? ''}, ${placemark.country ?? ''}';
//         setState(() {
//           _selectedAddress = address;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error getting address: $e');
//     }
//   }

//   void _onMapTap(LatLng location) async {
//     setState(() {
//       _selectedLocation = location;
//       _isLoading = true;
//     });

//     _updateMarker();
//     await _getAddressFromCoordinates(location);
//     setState(() => _isLoading = false);
//   }

//   void _showPermissionDialog() {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Permisos de ubicación'),
//         content: const Text('Habilita el permiso de ubicación desde la configuración del sistema.'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
//           TextButton(onPressed: openAppSettings, child: const Text('Abrir Configuración')),
//         ],
//       ),
//     );
//   }

//   void _confirmLocation() {
//     final result = 'Lat: ${_selectedLocation.latitude}, Lng: ${_selectedLocation.longitude}, Dirección: $_selectedAddress';
//     widget.onLocationSelected(result);
//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Seleccionar ubicación')),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: CameraPosition(target: _selectedLocation, zoom: 14),
//             onMapCreated: (controller) => _controller = controller,
//             onTap: _onMapTap,
//             markers: _markers,
//             myLocationEnabled: true,
//             myLocationButtonEnabled: false,
//           ),
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: Card(
//               margin: EdgeInsets.zero,
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(children: const [Icon(Icons.location_on), SizedBox(width: 8), Text('Ubicación seleccionada')]),
//                     const SizedBox(height: 8),
//                     _isLoading
//                         ? const CircularProgressIndicator()
//                         : Text(
//                             _selectedAddress.isEmpty
//                                 ? 'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}'
//                                 : _selectedAddress,
//                           ),
//                     const SizedBox(height: 16),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: _confirmLocation,
//                         child: const Text('Confirmar Ubicación'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
