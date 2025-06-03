import 'package:flutter/material.dart';
import '../models/dashboardViewModel.dart';
import '../services/dashboardService.dart';
import '../widgets/dashboard_kpi_cards.dart';
import '../widgets/dashboard_distribucion_reportes.dart';
import '../widgets/dashboard_reportes_servicio.dart';
import '../widgets/dashboard_reportes_municipio.dart';
import '../widgets/dashboard_reportes_estado.dart';
import '../widgets/dashboard_resumen_usuarios.dart';
import '../widgets/dashboard_top_usuarios.dart';
import '../widgets/dashboard_servicios_mas_reportados.dart';
import '../widgets/dashboard_resumen_estado_servicio.dart';
// import '../widgets/dashboard_reportes_mensuales.dart'; // Se utilizará cuando se implemente el servicio

class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  final DashboardService _dashboardService = DashboardService();
  bool _isLoading = true;
  String? _errorMessage;
  ResumenReportes? _resumenReportes;
  ResumenUsuarios? _resumenUsuarios;
  List<ReportePorServicio> _reportesPorServicio = [];
  List<ReportePorMunicipio> _reportesPorMunicipio = [];
  List<ReportePorEstado> _reportesPorEstado = [];
  List<TopUsuario> _topUsuarios = [];
  List<ServicioMasReportado> _serviciosMasReportados = [];
  List<ResumenEstadoPorServicio> _resumenEstadoPorServicio = [];
  // Esta lista se utilizará cuando se implemente el servicio de reportes mensuales
  // List<ReportePorMes> _reportesPorMes = [];

  Future<void> _cargarDatosDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resumen = await _dashboardService.obtenerResumenDashboard();
      final resumenUsuarios = await _dashboardService.obtenerResumenUsuarios();
      final reportesPorServicio =
          await _dashboardService.obtenerReportesPorServicio();
      final reportesPorMunicipio =
          await _dashboardService.obtenerReportesPorMunicipio();
      final reportesPorEstado =
          await _dashboardService.obtenerReportesPorEstado();
      final topUsuarios = await _dashboardService.obtenerTopUsuarios();
      final serviciosMasReportados = 
          await _dashboardService.obtenerServiciosMasReportados();
      final resumenEstadoPorServicio = 
          await _dashboardService.obtenerResumenEstadoPorServicio();
      // Aquí se podría cargar también los reportes por mes cuando esté implementado
      // final reportesPorMes = await _dashboardService.obtenerReportesPorMes();

      setState(() {
        _resumenReportes = resumen;
        _resumenUsuarios = resumenUsuarios;
        _reportesPorServicio = reportesPorServicio;
        _reportesPorMunicipio = reportesPorMunicipio;
        _reportesPorEstado = reportesPorEstado;
        _topUsuarios = topUsuarios;
        _serviciosMasReportados = serviciosMasReportados;
        _resumenEstadoPorServicio = resumenEstadoPorServicio;
        // _reportesPorMes = reportesPorMes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Mensaje de error amigable para el usuario
        if (e.toString().contains('Sin conexión a internet')) {
          _errorMessage =
              'No hay conexión a internet. Por favor, verifica tu conexión e intenta nuevamente.';
        } else {
          _errorMessage =
              'No se pudo cargar la información del dashboard. Por favor, intenta más tarde.';
        }
      });
      print('Error al cargar datos del dashboard: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarDatosDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _cargarDatosDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Panel de Control',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Mostrar error si existe
            if (_errorMessage != null && _errorMessage!.isNotEmpty)
              _buildErrorMessage(),

            // Mostrar indicador de carga o contenido del dashboard
            _isLoading
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
                : _buildDashboardContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? 'Ha ocurrido un error inesperado',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_resumenReportes == null) {
      return const Center(
        child: Text(
          'No hay datos disponibles',
          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen de Reportes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        DashboardKpiCards(resumenReportes: _resumenReportes!),
        const SizedBox(height: 24),
        DashboardDistribucionReportes(resumenReportes: _resumenReportes!),
        const SizedBox(height: 24),
        DashboardReportesPorServicio(reportesPorServicio: _reportesPorServicio),
        const SizedBox(height: 24),
        DashboardReportesPorMunicipio(reportesPorMunicipio: _reportesPorMunicipio),
        const SizedBox(height: 24),
        DashboardReportesPorEstado(reportesPorEstado: _reportesPorEstado),
        const SizedBox(height: 24),
        if (_resumenUsuarios != null)
          DashboardResumenUsuarios(resumenUsuarios: _resumenUsuarios!),
        if (_resumenUsuarios != null)
          const SizedBox(height: 24),
        DashboardTopUsuarios(topUsuarios: _topUsuarios),
        const SizedBox(height: 24),
        DashboardServiciosMasReportados(serviciosMasReportados: _serviciosMasReportados),
        const SizedBox(height: 24),
        DashboardResumenEstadoServicio(resumenEstadoPorServicio: _resumenEstadoPorServicio),
        const SizedBox(height: 24),
        // Cuando esté implementado el servicio de reportes por mes, descomentar esta línea
        // DashboardReportesMensuales(reportesPorMes: _reportesPorMes),
      ],
    );
  }
}
