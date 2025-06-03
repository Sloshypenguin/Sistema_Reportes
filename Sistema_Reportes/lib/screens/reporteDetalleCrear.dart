import 'package:flutter/material.dart';
import '../services/reporteDetalleService.dart';
import '../models/reporteViewModel.dart';

class ReporteDetalleCrear extends StatefulWidget {
  final String titulo;
  final Reporte? reporte;
  
  const ReporteDetalleCrear({
    super.key,
    required this.titulo,
    this.reporte,
  });

  @override
  State<ReporteDetalleCrear> createState() => _ReporteDetalleCrearState();
}

class _ReporteDetalleCrearState extends State<ReporteDetalleCrear>
    with TickerProviderStateMixin {
  
  // Controladores y variables de estado
  final TextEditingController _observacionController = TextEditingController();
  final ReporteDetalleService _reporteDetalleService = ReporteDetalleService();
  final _formKey = GlobalKey<FormState>();
  
  bool _guardando = false;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _observacionController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  /// Método para guardar la observación
  Future<void> _guardarObservacion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _guardando = true;
      });

      // Obtener datos necesarios
      final int repoId = widget.reporte!.repo_Id;
      final String observacion = _observacionController.text.trim();
      const int usuaCreacion = 1; // TODO: Obtener del usuario logueado

      // Debug: Mostrar los datos que se van a enviar
      debugPrint('=== DATOS A ENVIAR ===');
      debugPrint('Repo ID: $repoId');
      debugPrint('Observación: $observacion');
      debugPrint('Usuario Creación: $usuaCreacion');
      debugPrint('====================');

      // Llamar al servicio
      final resultado = await _reporteDetalleService.insertarObservacion(
        repoId,
        observacion,
        usuaCreacion,
      );

      if (resultado['success'] == true) {
        // Mostrar mensaje de éxito con animación
        if (mounted) {
          _mostrarMensajeExito(resultado['message'] ?? 'Observación guardada correctamente');
          
          // Esperar un poco para que se vea el mensaje y luego navegar
          await Future.delayed(const Duration(milliseconds: 1500));
          
          // Navegar de vuelta a la lista de reportes detalle
          Navigator.of(context).pushReplacementNamed(
            '/reporte-detalle-lista',
            arguments: {
              'reporte': widget.reporte,
              'titulo': 'Detalles del Reporte #${widget.reporte!.repo_Id}',
            },
          );
        }
      } else {
        // Mostrar mensaje de error
        if (mounted) {
          _mostrarMensajeError(resultado['message'] ?? 'Error al guardar la observación');
        }
      }
    } catch (e) {
      // Manejo de errores
      if (mounted) {
        _mostrarMensajeError('Error técnico: ${e.toString()}');
      }
      debugPrint('Error al guardar observación: $e');
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }
  
  void _mostrarMensajeExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '¡Éxito!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      mensaje,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _mostrarMensajeError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Error',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      mensaje,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Método para cancelar y regresar
  void _cancelar() {
    if (_observacionController.text.trim().isNotEmpty) {
      _mostrarDialogoCancelacion();
    } else {
      Navigator.of(context).pop();
    }
  }
  
  void _mostrarDialogoCancelacion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          elevation: 10,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '¿Cancelar observación?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Se perderá el texto ingresado. ¿Estás seguro de que deseas cancelar?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: const Text(
                        'No, continuar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Cerrar diálogo
                        Navigator.of(context).pop(); // Regresar a la pantalla anterior
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Sí, cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    // Validar que el reporte no sea null
    if (widget.reporte == null) {
      return _buildErrorScreen(theme);
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Column(
          children: [
            // Header mejorado con gradiente y animaciones
            _buildAnimatedHeader(theme),
            
            // Contenido principal
            Expanded(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Información del reporte mejorada
                              _buildReportInfoCard(theme),
                              
                              const SizedBox(height: 24),
                              
                              // Campo de observación mejorado
                              _buildObservacionField(theme),
                              
                              // Espaciado adicional
                              SizedBox(height: mediaQuery.padding.bottom + 100),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      
      // Botones flotantes mejorados
      bottomNavigationBar: _buildBottomActionBar(theme, mediaQuery),
    );
  }
  
  Widget _buildErrorScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(widget.titulo),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 60,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Error: No se encontró información del reporte',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Por favor regresa e intenta nuevamente',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnimatedHeader(ThemeData theme) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacity(0.8),
                  Colors.deepPurple.withOpacity(0.9),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icono animado
                      Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.note_add_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Agregar Observación',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.tag,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ID: ${widget.reporte!.repo_Id}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildReportInfoCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: theme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Información del Reporte',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            Icons.assignment_rounded,
            'Reporte',
            '#${widget.reporte!.repo_Id}',
            theme,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.build_rounded,
            'Servicio',
            widget.reporte!.serv_Nombre,
            theme,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.description_rounded,
            'Descripción',
            widget.reporte!.repo_Descripcion,
            theme,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme, {
    int? maxLines,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  height: 1.3,
                ),
                maxLines: maxLines,
                overflow: maxLines != null ? TextOverflow.ellipsis : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildObservacionField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.edit_note_rounded,
                color: theme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Observación',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(color: Colors.red, fontSize: 18),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: _observacionController,
            maxLines: 6,
            enabled: !_guardando,
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: 'Escribe tu observación aquí...\n\nDetalla la información importante sobre este reporte.',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
                height: 1.4,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(20),
              prefixIcon: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.message_rounded,
                  color: theme.primaryColor,
                  size: 20,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor ingresa una observación';
              }
              if (value.trim().length < 5) {
                return 'La observación debe tener al menos 5 caracteres';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildBottomActionBar(ThemeData theme, MediaQueryData mediaQuery) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        mediaQuery.padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón Cancelar
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _guardando ? null : _cancelar,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Cancelar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Botón Guardar
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _guardando ? null : _guardarObservacion,
              icon: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_guardando ? 'Guardando...' : 'Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: theme.primaryColor.withOpacity(0.3),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}