import 'package:flutter/material.dart';

class Pantalla {
  final int id;
  final String nombre;
  final String ruta;
  final IconData icono;

  Pantalla({
    required this.id,
    required this.nombre,
    required this.ruta,
    required this.icono,
  });

  factory Pantalla.fromJson(Map<String, dynamic> json) {
    return Pantalla(
      id: json['Pant_Id'],
      nombre: json['Pant_Nombre'],
      ruta: json['Pant_Ruta'],
      icono: _iconFromString(json['Pant_Icono']),
    );
  }

  static IconData _iconFromString(String iconStr) {
    switch (iconStr) {
      case 'Icons.home':
        return Icons.home;
      case 'Icons.assignment':
        return Icons.assignment;
      case 'Icons.person':
        return Icons.person;
      case 'Icons.widgets':
        return Icons.widgets;
      default:
        return Icons.help_outline;
    }
  }
}
