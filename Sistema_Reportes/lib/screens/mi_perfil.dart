import 'package:flutter/material.dart';

class MiPerfil extends StatefulWidget {
  final String titulo;
  final bool mostrarBotonRegresar;

  const MiPerfil({
    super.key,
    required this.titulo,
    this.mostrarBotonRegresar = false,
  });

  @override
  State<MiPerfil> createState() => _MiPerfilState();
}

class _MiPerfilState extends State<MiPerfil> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 80),
            SizedBox(height: 20),
            Text(
              'Mi Perfil',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text('Información del perfil del usuario'),
            // Aquí se agregaría la información real del perfil
          ],
        ),
      ),
    );
  }
}

