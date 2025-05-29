import 'package:flutter/material.dart';

/// Widget de plantilla que puede ser usado como base para crear otros widgets
///
/// Este widget implementa una estructura básica que puede ser adaptada
/// para diferentes propósitos como pantallas de perfil, reportes, etc.
class PlantillaWidget extends StatefulWidget {
  final String titulo;
  
  const PlantillaWidget({
    super.key,
    required this.titulo,
  });

  @override
  State<PlantillaWidget> createState() => _PlantillaWidgetState();
}

class _PlantillaWidgetState extends State<PlantillaWidget> {
  // Variables de estado
  bool _cargando = false;
  String _mensaje = 'Hola Mundo';
  
  @override
  void initState() {
    super.initState();
    // Aquí puedes inicializar variables o cargar datos
    _cargarDatos();
  }
  
  /// Método para cargar datos iniciales
  Future<void> _cargarDatos() async {
    try {
      setState(() {
        _cargando = true;
      });
      
      // Simulación de carga de datos
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Actualizar el estado con los datos cargados
      setState(() {
        _mensaje = 'Datos cargados correctamente';
        _cargando = false;
      });
    } catch (e) {
      // Manejo de errores
      setState(() {
        _mensaje = 'Error al cargar datos: $e';
        _cargando = false;
      });
      debugPrint('Error en _cargarDatos: $e');
    }
  }
  
  /// Método para realizar alguna acción
  void _realizarAccion() {
    setState(() {
      _mensaje = 'Acción realizada: ${DateTime.now().toString()}';
    });
    
    // Mostrar un SnackBar (asegúrate de que este widget esté dentro de un Scaffold)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Acción realizada')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return _cargando
        ? const Center(child: CircularProgressIndicator())
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.titulo,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Text(
                _mensaje,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _realizarAccion,
                child: const Text('Realizar Acción'),
              ),
            ],
          );
  }
}
