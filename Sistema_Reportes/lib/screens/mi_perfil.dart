import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'editar_perfil.dart';

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
  String nombreUsuario = 'Usuario';
  String rolUsuario = 'Rol';
  String? imagenPerfil;
  String correoUsuario = '';
  
  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }
  
  Future<void> _cargarDatosUsuario() async {
    final nombre = await AuthService.obtenerNombreUsuario() ?? 'Usuario';
    final rol = await AuthService.obtenerRol() ?? 'Rol';
    final imagen = await AuthService.obtenerImagenPerfil();
    final correo = await AuthService.obtenerCorreoUsuario() ?? '';
    
    setState(() {
      nombreUsuario = nombre;
      rolUsuario = rol;
      imagenPerfil = imagen;
      correoUsuario = correo;
      
      if (imagenPerfil != null) {
        debugPrint('Imagen de perfil cargada en mi_perfil: $imagenPerfil');
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Portada con imagen de perfil encimada
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/TimelineCovers.pro_ultra-hd-space-facebook-cover.jpg',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: -50, // sobresale hacia abajo
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 46,
                    // Mostrar imagen de perfil si está disponible, de lo contrario mostrar una imagen predeterminada
                    backgroundImage: imagenPerfil != null
                        ? NetworkImage('http://sistemareportesgob.somee.com${imagenPerfil}')
                        : const AssetImage('assets/images/logoAcademiaSL.png') as ImageProvider,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60), // espacio extra por el overlap
          // Nombre y usuario con botón de edición
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                nombreUsuario,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.blue),
                tooltip: 'Editar perfil',
                onPressed: () {
                  // Navegar a la pantalla de edición de perfil
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditarPerfilScreen(),
                    ),
                  ).then((_) {
                    // Recargar datos cuando regrese de la pantalla de edición
                    _cargarDatosUsuario();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('@$nombreUsuario', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),

          // Info adicional
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Text('Rol: $rolUsuario'),
                Text('Correo: $correoUsuario'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Estadísticas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              Column(
                children: [
                  Text(
                    '42',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text('Publicaciones'),
                ],
              ),
              Column(
                children: [
                  Text(
                    '128',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text('Seguidores'),
                ],
              ),
              Column(
                children: [
                  Text(
                    '80',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text('Siguiendo'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista de publicaciones (mock)
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Publicaciones recientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                              'assets/images/TimelineCovers.pro_ultra-hd-space-facebook-cover.jpg',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      const Text(
                        'Este es el contenido de la publicación del usuario.',
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Hace 2 horas',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
