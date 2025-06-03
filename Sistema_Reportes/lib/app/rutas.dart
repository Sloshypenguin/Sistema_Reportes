import 'package:flutter/material.dart';
import '../screens/login.dart';
import '../screens/principal.dart';
import '../screens/mi_perfil.dart';
import '../screens/reporteEdit.dart';
import '../screens/reporteDetalleCrear.dart';
// import '../screens/reportes.dart';
import '../layout/plantilla_base.dart';
import '../widgets/plantilla_widget.dart';
import '../screens/reporteCrear.dart';
import '../screens/google_maps.dart';

Route<dynamic> generarRuta(RouteSettings settings) {
  Widget pagina;

  switch (settings.name) {
    case '/':
    case '/login':
      pagina = const LoginScreen();
      break;

    case '/principal':
      pagina = const PlantillaBase(
        titulo: 'Página Principal',
        mostrarBotonRegresar: false,
        child: PrincipalScreen(),
      );
      break;

    

       case '/EditarReporte':
      pagina = const PlantillaBase(
        titulo: 'Editar Reporte',
        mostrarBotonRegresar: false,
         child: ReporteEdit(titulo: 'Editar Reporte'),
      );
      break;

      case '/CrearReporte':
      pagina = const PlantillaBase(
        titulo: 'Crear Reporte',
        mostrarBotonRegresar: false,
        child: reporteCrear(titulo: 'Crear Reporte'),
      );
      break;


  case '/ReporteDetalleCrear':
      pagina = const PlantillaBase(
        titulo: 'Crear Reporte Detalle',
        mostrarBotonRegresar: false,
         child: ReporteDetalleCrear(titulo: 'Crear Reporte Detalle', reporte: null),
      );
      break;

    case '/mi_perfil':
      pagina = const PlantillaBase(
        titulo: 'Mi Perfil',
        mostrarBotonRegresar: true,
        child: MiPerfil(titulo: 'Mi Perfil'),
      );
      break;

    // case '/reportes':
    //   pagina = const PlantillaBase(
    //     child: Reportes(),
    //   );
    //   break;

    case '/plantilla':
      pagina = const PlantillaBase(
        titulo: 'Plantilla Widget',
        mostrarBotonRegresar: true,
        child: PlantillaWidget(titulo: 'Ejemplo de Plantilla'),
      );
      break;
      
    case '/google_maps':
      pagina = const PlantillaBase(
        titulo: 'Google Maps',
        mostrarBotonRegresar: true,
        child: GoogleMapsScreen(),
      );
      break;

    default:
      pagina = Scaffold(
        appBar: AppBar(title: const Text('Ruta no encontrada')),
        body: const Center(child: Text('404 - Página no encontrada')),
      );
  }

  return MaterialPageRoute(builder: (_) => pagina, settings: settings);
}
