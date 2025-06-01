import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import '../services/connectivityService.dart';

class GoogleMapsScreen extends StatefulWidget {
  // Constructor que permite pasar un parámetro opcional para indicar si se está seleccionando ubicación
  const GoogleMapsScreen({super.key, this.seleccionarUbicacion = false});
  
  // Indica si se está usando la pantalla para seleccionar una ubicación
  final bool seleccionarUbicacion;

  @override
  State<GoogleMapsScreen> createState() => _GoogleMapsScreenState();
}

class _GoogleMapsScreenState extends State<GoogleMapsScreen> {
  // Controlador para el mapa
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  // Servicio de conectividad
  final ConnectivityService _connectivityService = ConnectivityService();

  // Ubicación inicial (Costa Rica)
  static const LatLng _defaultLocation = LatLng(
    9.9281,
    -84.0907,
  ); // San José, Costa Rica

  // Estado para la ubicación actual
  LatLng? _currentLocation;
  bool _isLoading = true;
  String? _errorMessage;

  // Estado para la ubicación seleccionada por el usuario
  LatLng? _selectedLocation;
  bool _isSelectionMode = false;
  String? _selectedAddress;
  bool _isLoadingAddress = false;

  // Estado para controlar la visibilidad de los paneles
  bool _isInstructionPanelVisible = true;
  bool _isInfoPanelVisible = true;

  // Conjunto de marcadores
  final Set<Marker> _markers = {};

  bool _mapLoaded = false;

  @override
  void initState() {
    super.initState();
    _verificarConectividadYCargarMapa();

    // Verificar si el mapa se carga correctamente después de un tiempo
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && !_mapLoaded && _errorMessage == null) {
        setState(() {
          _errorMessage =
              'El mapa no se ha podido cargar. Verifica tu conexión a internet y que la API de Google Maps esté correctamente configurada.';
          _isLoading = false;
        });
      }
    });
  }

  // Verificar conectividad antes de cargar el mapa
  Future<void> _verificarConectividadYCargarMapa() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verificar conectividad usando el servicio existente
      final bool tieneConexion = await _connectivityService.hasConnection();

      if (!tieneConexion) {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              'No hay conexión a internet. Conectáte a una red Wi-Fi o datos móviles para usar el mapa.';
          _isLoading = false;
        });
        return;
      }

      // Si hay conexión, proceder a obtener la ubicación
      await _getCurrentLocation();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Ocurrió un error al verificar la conexión. Intenta nuevamente.';
        _isLoading = false;
      });
      debugPrint('Error al verificar conectividad: $e');
    }
  }

  // Obtener la ubicación actual del usuario
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Location location = Location();

      bool serviceEnabled;
      PermissionStatus permissionGranted;
      LocationData locationData;

      // Verificar si el servicio de ubicación está habilitado
      try {
        serviceEnabled = await location.serviceEnabled();
        if (!serviceEnabled) {
          serviceEnabled = await location.requestService();
          if (!serviceEnabled) {
            setState(() {
              _errorMessage = 'Para ver tu ubicación en el mapa, necesitas activar el servicio de ubicación en tu dispositivo.';
              _isLoading = false;
              _mapLoaded = true; // Permitir que el mapa se cargue sin la ubicación actual
            });
            return;
          }
        }
      } catch (e) {
        debugPrint('Error al verificar servicio de ubicación: $e');
        setState(() {
          _errorMessage = 'No se pudo acceder al servicio de ubicación. Puedes usar el mapa sin tu ubicación actual.';
          _isLoading = false;
          _mapLoaded = true; // Permitir que el mapa se cargue sin la ubicación actual
        });
        return;
      }

      // Verificar permisos de ubicación
      try {
        permissionGranted = await location.hasPermission();
        if (permissionGranted == PermissionStatus.denied) {
          permissionGranted = await location.requestPermission();
          if (permissionGranted != PermissionStatus.granted) {
            setState(() {
              _errorMessage = 'Para ver tu ubicación en el mapa, necesitas conceder permisos de ubicación.';
              _isLoading = false;
              _mapLoaded = true; // Permitir que el mapa se cargue sin la ubicación actual
            });
            return;
          }
        }
      } catch (e) {
        debugPrint('Error al verificar permisos de ubicación: $e');
        setState(() {
          _errorMessage = 'No se pudieron verificar los permisos de ubicación. Puedes usar el mapa sin tu ubicación actual.';
          _isLoading = false;
          _mapLoaded = true; // Permitir que el mapa se cargue sin la ubicación actual
        });
        return;
      }

      // Obtener la ubicación actual con manejo de errores mejorado
      try {
        locationData = await location.getLocation().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw 'Tiempo de espera agotado';
          },
        );
      } catch (e) {
        debugPrint('Error al obtener ubicación: $e');
        // Mostrar mensaje amigable y continuar con el mapa
        if (!mounted) return;
        setState(() {
          _errorMessage = 'No pudimos obtener tu ubicación actual. Puedes seleccionar manualmente una ubicación en el mapa.';
          _isLoading = false;
          _mapLoaded = true; // Permitir que el mapa se cargue sin la ubicación actual
        });
        return;
      }

      if (!mounted) return;

      // Limpiar marcadores existentes
      _markers.clear();

      setState(() {
        _currentLocation = LatLng(
          locationData.latitude ?? _defaultLocation.latitude,
          locationData.longitude ?? _defaultLocation.longitude,
        );

        // Añadir un marcador en la ubicación actual
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: _currentLocation!,
            infoWindow: const InfoWindow(title: 'Mi ubicación actual'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        );

        _isLoading = false;
      });

      // Mover la cámara a la ubicación actual solo si el controlador está disponible
      if (_controller.isCompleted) {
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 15),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Mensajes de error amigables para el usuario
      String errorMsg = 'No se pudo obtener la ubicación.';

      if (e.toString().contains('ubicación está desactivado')) {
        errorMsg =
            'El servicio de ubicación está desactivado. Actívalo para ver tu ubicación en el mapa.';
      } else if (e.toString().contains('permisos')) {
        errorMsg =
            'Se requieren permisos de ubicación para mostrar tu posición en el mapa.';
      } else if (e.toString().contains('conexión') ||
          e.toString().contains('tiempo de espera')) {
        errorMsg =
            'Verifica tu conexión a internet para cargar el mapa correctamente.';
      }

      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });

      debugPrint('Error al obtener ubicación: $e');
    }
  }

  // Método para obtener la dirección de una ubicación usando geocodificación inversa
  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      // Verificar conectividad antes de hacer la solicitud
      final bool tieneConexion = await _connectivityService.hasConnection();

      if (!tieneConexion) {
        setState(() {
          _selectedAddress = 'Dirección no disponible (sin conexión a internet)';
          _isLoadingAddress = false;
        });
        return;
      }

      // Clave de API de Google Maps (reemplazar con tu clave real)
      const apiKey = 'AIzaSyD1FN7UbkCJOwi_k4DjLiowf2uJ3drQB8w';

      // URL para la API de Geocodificación Inversa de Google Maps
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey',
      );

      // Realizar la solicitud HTTP con manejo de errores mejorado
      try {
        final response = await http.get(url).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw 'Tiempo de espera agotado',
        );

        if (response.statusCode == 200) {
          // Decodificar la respuesta JSON
          final data = json.decode(response.body);

          if (data['status'] == 'OK') {
            // Obtener la primera dirección de los resultados
            if (data['results'] != null && data['results'].isNotEmpty) {
              final address = data['results'][0]['formatted_address'];
              setState(() {
                _selectedAddress = address;
                _isLoadingAddress = false;
              });
            } else {
              setState(() {
                _selectedAddress = 'Dirección no disponible (sin resultados)';
                _isLoadingAddress = false;
              });
            }
          } else {
            setState(() {
              _selectedAddress = 'Dirección no disponible';
              _isLoadingAddress = false;
            });
          }
        } else {
          setState(() {
            _selectedAddress = 'No se pudo obtener la dirección';
            _isLoadingAddress = false;
          });
        }
      } catch (e) {
        debugPrint('Error en solicitud HTTP: $e');
        setState(() {
          _selectedAddress = 'No se pudo obtener la dirección';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'No se pudo obtener la dirección';
        _isLoadingAddress = false;
      });
      debugPrint('Error al obtener dirección: $e');
    }
  }

  // Método para agregar un marcador en la ubicación seleccionada
  void _addMarkerAtPosition(LatLng position) {
    if (!_isSelectionMode) return;
    
    setState(() {
      // Eliminamos cualquier marcador de selección anterior
      _markers.removeWhere(
        (marker) => marker.markerId.value == 'selected_location',
      );
      
      _selectedLocation = position;
      _isLoadingAddress = true;

      // Añadir marcador en la posición seleccionada
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          infoWindow: InfoWindow(
            title: 'Ubicación seleccionada',
            snippet: 'Cargando dirección...',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          draggable: true,
          onDragEnd: (newPosition) {
            _selectedLocation = newPosition;
            _getAddressFromLatLng(newPosition);
          },
        ),
      );
    });

    // Obtener la dirección de la ubicación seleccionada
    _getAddressFromLatLng(position);
  }

  // Método para marcar la ubicación actual como ubicación seleccionada
  Future<void> _markCurrentLocationAsSelected() async {
    if (_currentLocation == null) {
      // Si no tenemos la ubicación actual, intentamos obtenerla primero
      await _getCurrentLocation();

      if (_currentLocation == null) {
        // Si aún no tenemos ubicación, mostramos un mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo obtener tu ubicación actual. Verifica los permisos y la configuración de ubicación.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }
    
    // Activar el modo de selección si no está activo
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
      });
    }
    
    // Usar la ubicación actual como ubicación seleccionada
    _addMarkerAtPosition(_currentLocation!);
  }

  // Método para alternar el modo de selección
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode && _selectedLocation != null) {
        // Si salimos del modo selección y había una ubicación seleccionada, la mantenemos
      } else if (_isSelectionMode) {
        // Mostrar mensaje de ayuda
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toca el mapa para seleccionar una ubicación'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          // Mapa de Google
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target:
                  _defaultLocation, // Siempre iniciar con ubicación por defecto
              zoom: 15,
            ),
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
                setState(() {
                  _mapLoaded = true;
                });

                // Forzar actualización del mapa
                if (_currentLocation != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(_currentLocation!, 15),
                  );
                }
              }
            },
            // Permitir tocar el mapa para seleccionar ubicación
            onTap: _isSelectionMode ? _addMarkerAtPosition : null,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled:
                false, // Desactivamos el botón por defecto para usar el nuestro
            zoomControlsEnabled: true,
            compassEnabled: true,
            padding: const EdgeInsets.all(16),
          ),

          // Indicador de carga
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Obteniendo ubicación...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // Mensaje de error
          if (_errorMessage != null && !_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _verificarConectividadYCargarMapa,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Reintentar',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          // Panel de mensajes de carga y error
          if (_isLoading) const Center(child: CircularProgressIndicator()),

          // Mensaje de error
          if (_errorMessage != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _verificarConectividadYCargarMapa,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Reintentar',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Botón para centrar en la ubicación actual
          Positioned(
            top: 10,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'center_location',
              onPressed: () async {
                if (_currentLocation != null) {
                  final GoogleMapController controller =
                      await _controller.future;
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(_currentLocation!, 15),
                  );
                } else {
                  _getCurrentLocation();
                }
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),

          // Botón para activar/desactivar modo de selección
          Positioned(
            top: 80,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'toggle_selection',
              onPressed: _toggleSelectionMode,
              backgroundColor: _isSelectionMode ? Colors.red : Colors.white,
              child: Icon(
                Icons.location_on,
                color: _isSelectionMode ? Colors.white : Colors.red,
              ),
            ),
          ),

          // Botón para marcar la ubicación actual como ubicación seleccionada
          Positioned(
            top: 150,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'mark_current_location',
              onPressed: _markCurrentLocationAsSelected,
              backgroundColor: Colors.green,
              child: const Icon(Icons.gps_fixed, color: Colors.white),
              tooltip: 'Marcar mi ubicación actual',
            ),
          ),

          // Indicador de modo de selección (panel de instrucciones)
          if (_isSelectionMode)
            Positioned(
              top: 16,
              left: 16,
              right:
                  _isInstructionPanelVisible
                      ? 16
                      : null, // Ancho completo solo cuando está expandido
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isInstructionPanelVisible = !_isInstructionPanelVisible;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize:
                          _isInstructionPanelVisible
                              ? MainAxisSize.max
                              : MainAxisSize.min,
                      children:
                          _isInstructionPanelVisible
                              ? [
                                // Icono de información
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                                // Cuando está expandido, mostrar todo el contenido
                                const SizedBox(width: 8),
                                const Text(
                                  'Instrucciones',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.keyboard_arrow_left,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Toca el mapa para seleccionar una ubicación o arrastra el marcador para ajustar. Puedes usar el botón verde para marcar tu ubicación actual.',
                                    style: TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ]
                              : [
                                // Icono de información
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                                // Cuando está contraído, mostrar solo el icono de expansión
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_right,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ],
                    ),
                  ),
                ),
              ),
            ),

          // Panel de información de la ubicación seleccionada
          if (_selectedLocation != null && _isSelectionMode)
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Barra superior con título y botón para contraer/expandir
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isInfoPanelVisible = !_isInfoPanelVisible;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ubicación seleccionada',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              _isInfoPanelVisible
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_up,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Contenido del panel (visible solo si _isInfoPanelVisible es true)
                    if (_isInfoPanelVisible)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.home,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child:
                                      _isLoadingAddress
                                          ? const Row(
                                            children: [
                                              SizedBox(
                                                width: 12,
                                                height: 12,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                              SizedBox(width: 8),
                                              Text('Obteniendo dirección...'),
                                            ],
                                          )
                                          : Text(
                                            _selectedAddress ??
                                                'Dirección no disponible',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedLocation = null;
                                      _selectedAddress = null;
                                      _markers.removeWhere(
                                        (marker) =>
                                            marker.markerId.value ==
                                            'selected_location',
                                      );
                                    });
                                  },
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Cancelar'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // Mostrar mensaje de confirmación
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Ubicación seleccionada: ${_selectedAddress ?? "Dirección no disponible"}',
                                        ),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                    
                                    // Si estamos en modo de selección de ubicación para un formulario
                                    if (widget.seleccionarUbicacion && _selectedLocation != null) {
                                      // Devolver la ubicación seleccionada al formulario
                                      Navigator.of(context).pop({
                                        'latitud': _selectedLocation!.latitude,
                                        'longitud': _selectedLocation!.longitude,
                                        'direccion': _selectedAddress ?? 'Dirección no disponible',
                                      });
                                    } else {
                                      // Comportamiento normal: salir del modo selección pero mantener el marcador
                                      setState(() {
                                        _isSelectionMode = false;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.check),
                                  label: const Text('Confirmar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
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
        ],
      ),
    );
  }
}
