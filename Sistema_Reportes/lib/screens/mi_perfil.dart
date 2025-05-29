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
              const Positioned(
                bottom: -50, // sobresale hacia abajo
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 46,
                    backgroundImage: AssetImage(
                      'assets/images/logoAcademiaSL.png',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60), // espacio extra por el overlap
          // Nombre y usuario
          const Text(
            'Juan Pérez',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('@juanperez', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),

          // Info adicional
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Text('Rol: Administrador'),
                Text('Correo: juan.perez@email.com'),
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
