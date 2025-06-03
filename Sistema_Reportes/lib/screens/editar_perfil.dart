import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../config/api_config.dart';
import '../services/usuarioService.dart';
import '../services/connectivityService.dart';
// Usamos FlutterSecureStorage directamente en lugar de AuthService
// import '../services/auth_service.dart';
import '../services/estadoCivilService.dart';
import '../services/departamentoService.dart';
import '../services/municipioService.dart';
import '../models/estadoCivilViewModel.dart';
import '../models/departamentoViewModel.dart';
import '../models/municipioViewModel.dart';

/// Pantalla para editar el perfil completo del usuario
class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({Key? key}) : super(key: key);

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  // Servicios
  final UsuarioService _usuarioService = UsuarioService();
  final ConnectivityService _connectivityService =
      ConnectivityService(); // Se utilizará para verificar conectividad
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final EstadoCivilService _estadoCivilService = EstadoCivilService();
  final DepartamentoService _departamentoService = DepartamentoService();
  final MunicipioService _municipioService = MunicipioService();
  final ImagePicker _picker = ImagePicker();

  // Controladores para los campos de texto
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _nombrePersonaController =
      TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();

  // Variables para la imagen de perfil
  File? _imagenPerfil;
  bool _subiendoImagen = false;
  String? _rutaImagenPerfil;

  // Variables para controlar el estado
  bool _isLoading = false;
  bool _datosModificados =
      false; // Se utiliza para rastrear cambios en el formulario

  // Datos del usuario
  String _nombreUsuario = '';
  String _correoUsuario = '';
  String _dniUsuario = '';
  String _nombrePersona = '';
  String _apellidoPersona = '';
  String _telefonoUsuario = '';
  String _direccionUsuario = '';
  String? _sexoSeleccionado;
  int _usuarioId = 0;
  int _persId =
      0; // ID de la persona asociada al usuario (necesario para cargar datos)
  int _roleId = 0; // ID del rol del usuario (necesario para cargar datos)
  bool _esAdmin =
      false; // Indica si el usuario es administrador (necesario para cargar datos)
  bool _esEmpleado =
      false; // Indica si el usuario es empleado (necesario para cargar datos)
  String? _imagenPerfilActual;

  // Formatters para campos específicos
  final _dniFormatter = MaskTextInputFormatter(
    mask: '####-####-#####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _telefonoFormatter = MaskTextInputFormatter(
    mask: '####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // Variables para código de país
  String _codigoIsoPais = 'HN'; // Código ISO de Honduras
  String _codigoPais = '+504'; // Código de marcación para Honduras
  MaskTextInputFormatter? _telefonoFormatterDinamico;

  // Opciones para sexo
  final List<Map<String, dynamic>> _opcionesSexo = [
    {'valor': 'M', 'texto': 'M'},
    {'valor': 'F', 'texto': 'F'},
  ];

  // Variables para estado civil
  List<EstadoCivil> _estadosCiviles = [];
  int? _estadoCivilSeleccionado;
  bool _cargandoEstadosCiviles = true;

  // Variables para departamento y municipio
  List<Departamento> _departamentos = [];
  int? _departamentoSeleccionado;
  bool _cargandoDepartamentos = true;

  List<Municipio> _municipios = [];
  String? _municipioSeleccionado;
  bool _cargandoMunicipios = false;

  // Controlador de scroll para la página
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _actualizarFormateadorTelefono('HN');
    _cargarEstadosCiviles();
    _cargarDepartamentos();
  }

  @override
  void dispose() {
    // Liberar controladores
    _nombreController.dispose();
    _correoController.dispose();
    _dniController.dispose();
    _nombrePersonaController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Actualiza el formateador de teléfono según el país seleccionado
  void _actualizarFormateadorTelefono(String codigoIso) {
    String mask;

    switch (codigoIso) {
      case 'HN':
        mask = '####-####'; // Honduras: 9876-5432
        _codigoPais = '+504';
        break;
      case 'US':
      case 'CA':
        mask = '(###) ###-####'; // USA/Canadá: (123) 456-7890
        _codigoPais = '+1';
        break;
      case 'MX':
        mask = '## #### ####'; // México: 55 1234 5678
        _codigoPais = '+52';
        break;
      case 'GT':
        mask = '#### ####'; // Guatemala: 5555 1234
        _codigoPais = '+502';
        break;
      case 'SV':
        mask = '#### ####'; // El Salvador: 5555 1234
        _codigoPais = '+503';
        break;
      case 'NI':
        mask = '#### ####'; // Nicaragua: 5555 1234
        _codigoPais = '+505';
        break;
      case 'CR':
        mask = '####-####'; // Costa Rica: 8888-9999
        _codigoPais = '+506';
        break;
      case 'PA':
        mask = '####-####'; // Panamá: 6666-7777
        _codigoPais = '+507';
        break;
      default:
        mask = '########'; // Formato genérico
        _codigoPais = '+504'; // Honduras por defecto
        break;
    }

    _telefonoFormatterDinamico = MaskTextInputFormatter(
      mask: mask,
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy,
    );
  }

  /// Obtiene el texto de ejemplo según el país
  String _obtenerHintTelefono(String codigoIso) {
    switch (codigoIso) {
      case 'HN':
        return 'Ej: 9876-5432';
      case 'US':
      case 'CA':
        return 'Ej: (123) 456-7890';
      case 'MX':
        return 'Ej: 55 1234 5678';
      case 'GT':
      case 'SV':
      case 'NI':
        return 'Ej: 5555 1234';
      case 'CR':
      case 'PA':
        return 'Ej: 8888-9999';
      default:
        return 'Ingrese su número';
    }
  }

  /// Carga los datos del usuario desde la API
  Future<void> _cargarDatosUsuario() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Cargar datos básicos del usuario desde el almacenamiento seguro
      final idStr = await _storage.read(key: 'usuario_id');
      final usuarioId = idStr != null ? int.tryParse(idStr) ?? 0 : 0;

      if (usuarioId == 0) {
        _mostrarMensajeError('No se pudo obtener el ID del usuario');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Obtener los detalles del usuario desde la API
      final resultado = await _usuarioService.obtenerDetalleUsuario(usuarioId);

      if (resultado['exito']) {
        final usuario = resultado['usuario'];
        final persona = resultado['persona'];
        // Datos del empleado (si aplica)
        final empleado = resultado['empleado'];

        // Si es empleado, podríamos usar estos datos en el futuro
        if (empleado != null && _esEmpleado) {
          debugPrint(
            'Usuario es empleado con cargo: ${empleado['Carg_Nombre'] ?? "No especificado"}',
          );
        }

        if (mounted) {
          setState(() {
            // Datos del usuario
            _usuarioId = usuario['usua_Id'];
            _nombreUsuario = usuario['usua_Usuario'];
            _correoUsuario = usuario['pers_Correo'] ?? '';
            _persId = usuario['pers_Id'];
            _roleId = usuario['role_Id'];
            _esAdmin = usuario['usua_EsAdmin'];
            _esEmpleado = usuario['usua_EsEmpleado'];
            _imagenPerfilActual = usuario['usua_Imagen'];

            // Datos de la persona
            _dniUsuario = persona['Pers_DNI'] ?? '';
            _nombrePersona = persona['Pers_Nombre'] ?? '';
            _apellidoPersona = persona['Pers_Apellido'] ?? '';
            _sexoSeleccionado = persona['Pers_Sexo'];
            _telefonoUsuario = persona['Pers_Telefono'] ?? '';
            _direccionUsuario = persona['Pers_Direccion'] ?? '';

            // Datos de ubicación
            _estadoCivilSeleccionado = persona['EsCi_Id'];
            _municipioSeleccionado = persona['Muni_Codigo'];

            // Intentar obtener el departamento a partir del código de municipio
            final depaCodigo = persona['Depa_Codigo'];
            if (depaCodigo != null) {
              // Convertir el código de departamento a entero para el selector
              _departamentoSeleccionado = int.tryParse(depaCodigo.toString());
            }

            // Actualizar controladores
            _nombreController.text = _nombreUsuario;
            _correoController.text = _correoUsuario;
            _dniController.text = _dniUsuario;
            _nombrePersonaController.text = _nombrePersona;
            _apellidoController.text = _apellidoPersona;
            _telefonoController.text = _telefonoUsuario;
            _direccionController.text = _direccionUsuario;

            // Inicializar la ruta de la imagen con la actual
            _rutaImagenPerfil = _imagenPerfilActual;

            if (_imagenPerfilActual != null) {
              debugPrint(
                'Imagen de perfil actual cargada: $_imagenPerfilActual',
              );
            }

            _isLoading = false;
            _datosModificados = false; // Reiniciar el estado de modificación
          });

          // Cargar municipios del departamento seleccionado
          if (_departamentoSeleccionado != null) {
            _cargarMunicipiosPorDepartamento(_departamentoSeleccionado!);
          }

          debugPrint('Datos del usuario cargados correctamente desde la API');
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _mostrarMensajeError(
            resultado['mensaje'] ?? 'Error al cargar datos del usuario',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error al cargar datos del usuario: $e');
      _mostrarMensajeError('Error al cargar datos. Intente nuevamente.');
    }
  }

  /// Selecciona una imagen desde la galería
  Future<void> _seleccionarImagenDesdeGaleria() async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Calidad de la imagen (0-100)
        maxWidth: 800, // Ancho máximo
      );

      if (imagen != null) {
        setState(() {
          _imagenPerfil = File(imagen.path);
          _rutaImagenPerfil =
              null; // Resetear la ruta cuando se selecciona una nueva imagen
          _datosModificados = true;
        });

        // Subir la imagen inmediatamente
        await _subirImagenAlServidor();
      }
    } catch (e) {
      _mostrarMensajeError('Error al seleccionar imagen: $e');
    }
  }

  /// Toma una foto con la cámara
  Future<void> _tomarFoto() async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (imagen != null) {
        setState(() {
          _imagenPerfil = File(imagen.path);
          _rutaImagenPerfil = null;
          _datosModificados = true;
        });

        // Subir la imagen inmediatamente
        await _subirImagenAlServidor();
      }
    } catch (e) {
      _mostrarMensajeError('Error al tomar foto: $e');
    }
  }

  /// Sube la imagen seleccionada al servidor
  Future<void> _subirImagenAlServidor() async {
    if (_imagenPerfil == null) {
      _mostrarMensajeError('Por favor seleccione una imagen primero');
      return;
    }

    try {
      setState(() {
        _subiendoImagen = true;
      });

      // Crear un request multipart
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/Usuarios/SubirImagen'),
      );

      // Añadir la API key en los headers
      request.headers['X-API-KEY'] = ApiConfig.apiKey;

      // Añadir la imagen al request
      request.files.add(
        await http.MultipartFile.fromPath(
          'imagen', // nombre del parámetro que espera el servidor
          _imagenPerfil!.path,
        ),
      );

      // Enviar el request
      final response = await request.send();

      if (response.statusCode == 200) {
        // Convertir la respuesta a string
        final respuestaString = await response.stream.bytesToString();
        final respuestaJson = json.decode(respuestaString);

        // Guardar la ruta de la imagen
        setState(() {
          _rutaImagenPerfil = respuestaJson['ruta'];
          _subiendoImagen = false;
        });

        _mostrarMensajeExito('Imagen subida correctamente');
      } else {
        setState(() {
          _subiendoImagen = false;
        });
        _mostrarMensajeError('Error al subir imagen: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _subiendoImagen = false;
      });
      _mostrarMensajeError('Error al subir imagen: $e');
    }
  }

  /// Carga los municipios del departamento seleccionado
  Future<void> _cargarMunicipiosPorDepartamento(int departamentoId) async {
    if (!mounted) return;

    try {
      setState(() {
        _cargandoMunicipios = true;
        _municipios = [];
        _municipioSeleccionado = null;
      });

      // Verificar conectividad
      final tieneConexion = await _connectivityService.hasConnection();
      if (!tieneConexion) {
        setState(() {
          _cargandoMunicipios = false;
        });
        _mostrarMensajeError(
          'No hay conexión a Internet. Por favor, verifique su conexión e intente nuevamente.',
        );
        return;
      }

      try {
        // Obtener el código del departamento
        final departamento = _departamentos.firstWhere(
          (d) => int.parse(d.depa_Codigo) == departamentoId,
        );
        final depaCodigo = departamento.depa_Codigo;

        // Cargar municipios del departamento usando el servicio
        final municipios = await _municipioService.listarPorDepartamento(
          depaCodigo,
        );

        if (mounted) {
          setState(() {
            _municipios = municipios;
            _cargandoMunicipios = false;

            // Si hay un municipio seleccionado previamente, intentar mantenerlo
            if (_municipioSeleccionado != null) {
              final existeMunicipio = _municipios.any(
                (m) => m.muni_Codigo == _municipioSeleccionado,
              );
              if (!existeMunicipio) {
                _municipioSeleccionado =
                    _municipios.isNotEmpty ? _municipios[0].muni_Codigo : null;
              }
            } else if (_municipios.isNotEmpty) {
              _municipioSeleccionado = _municipios[0].muni_Codigo;
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _cargandoMunicipios = false;
          });
          _mostrarMensajeError('Error al cargar municipios: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoMunicipios = false;
        });
        _mostrarMensajeError('Error al cargar municipios: $e');
      }
    }
  }

  /// Muestra un mensaje de error
  void _mostrarMensajeError(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  /// Muestra un mensaje de éxito
  void _mostrarMensajeExito(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
    );
  }

  // El método _cargarMunicipiosPorDepartamento ya está definido arriba con parámetros

  /// Carga los estados civiles
  Future<void> _cargarEstadosCiviles() async {
    setState(() {
      _cargandoEstadosCiviles = true;
    });

    try {
      // Aquí deberíamos cargar los estados civiles desde la API
      // Por ahora, usaremos datos de ejemplo
      final estadosCiviles = await _estadoCivilService.listar();

      if (mounted) {
        setState(() {
          _estadosCiviles = estadosCiviles;
          _cargandoEstadosCiviles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoEstadosCiviles = false;
        });
        _mostrarMensajeError('Error al cargar estados civiles: $e');
      }
    }
  }

  /// Carga los departamentos
  Future<void> _cargarDepartamentos() async {
    setState(() {
      _cargandoDepartamentos = true;
    });

    try {
      // Aquí deberíamos cargar los departamentos desde la API
      // Por ahora, usaremos datos de ejemplo
      final departamentos = await _departamentoService.listar();

      if (mounted) {
        setState(() {
          _departamentos = departamentos;
          _cargandoDepartamentos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoDepartamentos = false;
        });
        _mostrarMensajeError('Error al cargar departamentos: $e');
      }
    }
  }

  /// Guarda los cambios del perfil
  Future<void> _guardarCambios() async {
    // Si no hay cambios, no hacer nada
    if (!_datosModificados) {
      _mostrarMensajeError('No hay cambios para guardar');
      return;
    }

    // Validar campos
    if (!_validarCampos()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Preparar los datos de persona para el JSON
      final personaData = {
        'Pers_DNI': _dniController.text.trim(),
        'Pers_Nombre': _nombrePersonaController.text.trim(),
        'Pers_Apellido': _apellidoController.text.trim(),
        'Pers_Sexo': _sexoSeleccionado,
        'Pers_Telefono': _telefonoController.text.trim(),
        'Pers_Correo': _correoController.text.trim(),
        'Pers_Direccion': _direccionController.text.trim(),
        'Muni_Codigo': _municipioSeleccionado,
        'EsCi_Id': _estadoCivilSeleccionado,
      };

      // Verificar conectividad antes de enviar la solicitud
      final tieneConexion = await _connectivityService.hasConnection();
      if (!tieneConexion) {
        setState(() {
          _isLoading = false;
        });
        _mostrarMensajeError(
          'No hay conexión a Internet. Por favor, verifique su conexión e intente nuevamente.',
        );
        return;
      }

      // Llamar al servicio para actualizar el perfil completo
      final resultado = await _usuarioService.editarRegistro(
        usuarioId: _usuarioId,
        personaData: personaData,
        usuario: _nombreController.text.trim(),
        usua_Imagen: _rutaImagenPerfil ?? _imagenPerfilActual,
        usuarioModificacion: _usuarioId,
      );

      setState(() {
        _isLoading = false;
      });

      if (resultado['exito']) {
        // Actualizar datos en el almacenamiento seguro
        await _storage.write(
          key: 'usuario_nombre',
          value: _nombreController.text.trim(),
        );
        await _storage.write(
          key: 'usuario_correo',
          value: _correoController.text.trim(),
        );

        // Actualizar la imagen de perfil si se ha cambiado
        if (_rutaImagenPerfil != null &&
            _rutaImagenPerfil != _imagenPerfilActual) {
          await _storage.write(key: 'usuario_imagen', value: _rutaImagenPerfil);
        }

        _mostrarMensajeExito(
          resultado['mensaje'] ?? 'Perfil actualizado correctamente',
        );

        // Volver a la pantalla anterior
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        _mostrarMensajeError(
          resultado['mensaje'] ?? 'Error al actualizar perfil',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _mostrarMensajeError('Error al actualizar perfil: $e');
    }
  }

  /// Valida los campos del formulario
  bool _validarCampos() {
    bool esValido = true;
    String mensajeError = '';

    // Validar nombre de usuario
    if (_nombreController.text.trim().isEmpty) {
      mensajeError = 'El nombre de usuario es requerido';
      esValido = false;
    }

    // Validar correo electrónico
    if (_correoController.text.trim().isEmpty) {
      mensajeError = 'El correo electrónico es requerido';
      esValido = false;
    } else if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(_correoController.text.trim())) {
      mensajeError = 'Ingrese un correo electrónico válido';
      esValido = false;
    }

    // Validar DNI
    if (_dniController.text.trim().isEmpty) {
      mensajeError = 'El DNI es requerido';
      esValido = false;
    }

    // Validar nombre de persona
    if (_nombrePersonaController.text.trim().isEmpty) {
      mensajeError = 'El nombre es requerido';
      esValido = false;
    }

    // Validar apellido
    if (_apellidoController.text.trim().isEmpty) {
      mensajeError = 'El apellido es requerido';
      esValido = false;
    }

    // Validar teléfono
    if (_telefonoController.text.trim().isEmpty) {
      mensajeError = 'El teléfono es requerido';
      esValido = false;
    }

    // Validar dirección
    if (_direccionController.text.trim().isEmpty) {
      mensajeError = 'La dirección es requerida';
      esValido = false;
    }

    // Validar sexo
    if (_sexoSeleccionado == null) {
      mensajeError = 'El sexo es requerido';
      esValido = false;
    }

    // Validar estado civil
    if (_estadoCivilSeleccionado == null) {
      mensajeError = 'El estado civil es requerido';
      esValido = false;
    }

    // Validar departamento
    if (_departamentoSeleccionado == null) {
      mensajeError = 'El departamento es requerido';
      esValido = false;
    }

    // Validar municipio
    if (_municipioSeleccionado == null) {
      mensajeError = 'El municipio es requerido';
      esValido = false;
    }

    if (!esValido) {
      _mostrarMensajeError(mensajeError);
    }

    return esValido;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Botón para guardar cambios
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Guardar cambios',
            onPressed: _isLoading ? null : _guardarCambios,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección de imagen de perfil
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.blue.shade700, Colors.blue.shade500],
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Avatar con opción para cambiar imagen
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white,
                                // Mostrar imagen seleccionada, imagen actual o icono predeterminado
                                backgroundImage:
                                    _imagenPerfil != null
                                        ? FileImage(_imagenPerfil!)
                                        : (_imagenPerfilActual != null
                                                ? NetworkImage(
                                                  'http://siresp.somee.com${_imagenPerfilActual}',
                                                )
                                                : null)
                                            as ImageProvider?,
                                child:
                                    _subiendoImagen
                                        ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                        : (_imagenPerfil == null &&
                                                _imagenPerfilActual == null
                                            ? Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.blue.shade700,
                                            )
                                            : null),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Row(
                                  children: [
                                    // Botón para tomar foto
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.green,
                                      child: InkWell(
                                        onTap: _tomarFoto,
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Botón para seleccionar de galería
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.blue,
                                      child: InkWell(
                                        onTap: _seleccionarImagenDesdeGaleria,
                                        child: const Icon(
                                          Icons.photo_library,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    // Secciones de datos en tarjetas
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sección: Información de la cuenta
                          _buildSectionCard(
                            title: 'Información de la cuenta',
                            icon: Icons.account_circle,
                            children: [
                              // Campo de nombre de usuario
                              TextFormField(
                                controller: _nombreController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre de usuario',
                                  prefixIcon: Icon(Icons.person),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Campo de correo electrónico
                              TextFormField(
                                controller: _correoController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Correo electrónico',
                                  prefixIcon: Icon(Icons.email),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Sección: Información personal
                          _buildSectionCard(
                            title: 'Información personal',
                            icon: Icons.badge,
                            children: [
                              // Campo de DNI
                              TextFormField(
                                controller: _dniController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [_dniFormatter],
                                decoration: const InputDecoration(
                                  labelText: 'DNI / Identidad',
                                  prefixIcon: Icon(Icons.credit_card),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Campo de nombre
                              TextFormField(
                                controller: _nombrePersonaController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Campo de apellido
                              TextFormField(
                                controller: _apellidoController,
                                decoration: const InputDecoration(
                                  labelText: 'Apellido',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Selector de sexo
                              Row(
                                children: [
                                  const Text(
                                    'Sexo:',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 16),
                                  for (var opcion in _opcionesSexo) ...[
                                    Radio<String>(
                                      value: opcion['valor'],
                                      groupValue: _sexoSeleccionado,
                                      onChanged: (valor) {
                                        setState(() {
                                          _sexoSeleccionado = valor;
                                          _datosModificados = true;
                                        });
                                      },
                                    ),
                                    Text(opcion['texto']),
                                    const SizedBox(width: 16),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Selector de estado civil
                              DropdownButtonFormField<int?>(
                                value: _estadoCivilSeleccionado,
                                decoration: const InputDecoration(
                                  labelText: 'Estado Civil',
                                  prefixIcon: Icon(Icons.favorite),
                                ),
                                hint: const Text('Seleccione una opción'),
                                isExpanded: true,
                                items:
                                    _cargandoEstadosCiviles
                                        ? [
                                          const DropdownMenuItem<int?>(
                                            value: null,
                                            child: Text('Cargando...'),
                                          ),
                                        ]
                                        : [
                                          const DropdownMenuItem<int?>(
                                            value: null,
                                            child: Text(
                                              'Seleccione una opción',
                                            ),
                                          ),
                                          // Asegurarse de que no haya valores duplicados
                                          ...Set<int>.from(
                                            _estadosCiviles.map(
                                              (e) => e.esCi_Id,
                                            ),
                                          ).map((id) {
                                            final estadoCivil = _estadosCiviles
                                                .firstWhere(
                                                  (e) => e.esCi_Id == id,
                                                );
                                            return DropdownMenuItem<int?>(
                                              value: id,
                                              child: Text(
                                                estadoCivil.esCi_Nombre,
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                onChanged: (valor) {
                                  setState(() {
                                    _estadoCivilSeleccionado = valor;
                                    _datosModificados = true;
                                  });
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Sección: Contacto y ubicación
                          _buildSectionCard(
                            title: 'Contacto y ubicación',
                            icon: Icons.location_on,
                            children: [
                              // Campo de teléfono
                              Row(
                                children: [
                                  // Selector de código de país
                                  Container(
                                    width: 120,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: CountryCodePicker(
                                      onChanged: (CountryCode countryCode) {
                                        setState(() {
                                          _codigoPais = countryCode.dialCode!;
                                          _codigoIsoPais = countryCode.code!;
                                          _actualizarFormateadorTelefono(
                                            _codigoIsoPais,
                                          );
                                          _datosModificados = true;
                                        });
                                      },
                                      initialSelection: 'HN',
                                      favorite: const [
                                        '+504',
                                        'HN',
                                        '+1',
                                        'US',
                                      ],
                                      showCountryOnly: false,
                                      showOnlyCountryWhenClosed: false,
                                      alignLeft: false,
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Campo de teléfono
                                  Expanded(
                                    child: TextFormField(
                                      controller: _telefonoController,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        _telefonoFormatterDinamico ??
                                            _telefonoFormatter,
                                      ],
                                      decoration: InputDecoration(
                                        labelText: 'Teléfono',
                                        hintText: _obtenerHintTelefono(
                                          _codigoIsoPais,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Campo de dirección
                              TextFormField(
                                controller: _direccionController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Dirección',
                                  prefixIcon: Icon(Icons.home),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Selector de departamento
                              DropdownButtonFormField<int?>(
                                value: _departamentoSeleccionado,
                                decoration: const InputDecoration(
                                  labelText: 'Departamento',
                                  prefixIcon: Icon(Icons.map),
                                ),
                                hint: const Text('Seleccione un departamento'),
                                isExpanded: true,
                                items:
                                    _cargandoDepartamentos
                                        ? [
                                          const DropdownMenuItem<int?>(
                                            value: null,
                                            child: Text('Cargando...'),
                                          ),
                                        ]
                                        : [
                                          const DropdownMenuItem<int?>(
                                            value: null,
                                            child: Text(
                                              'Seleccione un departamento',
                                            ),
                                          ),
                                          ..._departamentos.map((depa) {
                                            return DropdownMenuItem<int?>(
                                              value: int.parse(
                                                depa.depa_Codigo,
                                              ),
                                              child: Text(depa.depa_Nombre),
                                            );
                                          }).toList(),
                                        ],
                                onChanged:
                                    _cargandoDepartamentos
                                        ? null
                                        : (departamentoId) {
                                          if (departamentoId == null) return;
                                          // Actualizar el departamento seleccionado
                                          setState(() {
                                            _departamentoSeleccionado =
                                                departamentoId;
                                            _municipioSeleccionado = null;
                                            _municipios = [];
                                            _datosModificados =
                                                true; // Marcar que hay cambios pendientes para habilitar el botón de guardar
                                          });

                                          // Cargar municipios del departamento seleccionado
                                          _cargarMunicipiosPorDepartamento(
                                            departamentoId,
                                          );
                                        },
                              ),
                              const SizedBox(height: 16),

                              // Selector de municipio
                              DropdownButtonFormField<String?>(
                                value: _municipioSeleccionado,
                                decoration: const InputDecoration(
                                  labelText: 'Municipio',
                                  prefixIcon: Icon(Icons.location_city),
                                ),
                                hint: const Text('Seleccione un municipio'),
                                isExpanded: true,
                                items:
                                    _cargandoMunicipios
                                        ? [
                                          const DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text('Cargando...'),
                                          ),
                                        ]
                                        : _municipios.isEmpty
                                        ? [
                                          const DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text(
                                              'No hay municipios disponibles',
                                            ),
                                          ),
                                        ]
                                        : [
                                          const DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text(
                                              'Seleccione un municipio',
                                            ),
                                          ),
                                          ..._municipios.map((muni) {
                                            return DropdownMenuItem<String?>(
                                              value: muni.muni_Codigo,
                                              child: Text(muni.muni_Nombre),
                                            );
                                          }).toList(),
                                        ],
                                onChanged:
                                    _cargandoMunicipios || _municipios.isEmpty
                                        ? null
                                        : (valor) {
                                          setState(() {
                                            _municipioSeleccionado = valor;
                                            _datosModificados = true;
                                          });
                                        },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Botón de guardar cambios
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _guardarCambios,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text(
                                    'GUARDAR CAMBIOS',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  /// Construye una tarjeta para una sección de datos
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
