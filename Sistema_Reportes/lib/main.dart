import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/login.dart';
import 'screens/principal.dart';
import 'widgets/widgets.dart';
import 'screens/mi_perfil.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final storage = FlutterSecureStorage();
  bool _sesionIniciada = false;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  /// Verifica si hay una sesión activa
  Future<void> _verificarSesion() async {
    try {
      final token = await storage.read(key: 'usuario_token');
      setState(() {
        _sesionIniciada = token != null && token.isNotEmpty;
        _cargando = false;
      });
    } catch (e) {
      debugPrint('Error al verificar sesión: $e');
      setState(() {
        _sesionIniciada = false;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Reportes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home:
          _cargando
              ? const _PantallaCarga()
              : _sesionIniciada
              ? const _PantallaPrincipal()
              : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/principal': (context) => const _PantallaPrincipal(),
        '/reportes': (context) => const _PantallaReportes(),
        '/configuracion': (context) => const _PantallaConfiguracion(),
        '/mi_perfil': (context) => const MiPerfil(),
      },
    );
  }
}

/// Pantalla de carga mientras se verifica la sesión
class _PantallaCarga extends StatelessWidget {
  const _PantallaCarga();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Pantalla principal que utiliza la plantilla base
class _PantallaPrincipal extends StatelessWidget {
  const _PantallaPrincipal();

  @override
  Widget build(BuildContext context) {
    return PlantillaBase(
      titulo: 'Página Principal',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Bienvenido al Sistema de Reportes',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Selecciona una opción del menú lateral',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/reportes');
              },
              child: const Text('Ver Reportes'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla de reportes que utiliza la plantilla base
class _PantallaReportes extends StatelessWidget {
  const _PantallaReportes();

  @override
  Widget build(BuildContext context) {
    return PlantillaBase(
      titulo: 'Reportes',
      mostrarBotonRegresar: true,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Listado de Reportes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text('${index + 1}'),
                      ),
                      title: Text('Reporte #${index + 1}'),
                      subtitle: Text('Descripción del reporte ${index + 1}'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Ver detalles del reporte ${index + 1}',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla de configuración que utiliza la plantilla base
class _PantallaConfiguracion extends StatelessWidget {
  const _PantallaConfiguracion();

  @override
  Widget build(BuildContext context) {
    return PlantillaBase(
      titulo: 'Configuración',
      mostrarBotonRegresar: true,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración del Sistema',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const ListTile(
              leading: Icon(Icons.person, color: Colors.blue),
              title: Text('Perfil de Usuario'),
              subtitle: Text('Editar información de perfil'),
              trailing: Icon(Icons.arrow_forward_ios),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.notifications, color: Colors.orange),
              title: Text('Notificaciones'),
              subtitle: Text('Configurar notificaciones del sistema'),
              trailing: Icon(Icons.arrow_forward_ios),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.color_lens, color: Colors.purple),
              title: Text('Apariencia'),
              subtitle: Text('Personalizar la apariencia de la aplicación'),
              trailing: Icon(Icons.arrow_forward_ios),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.security, color: Colors.green),
              title: Text('Seguridad'),
              subtitle: Text('Configuración de seguridad y privacidad'),
              trailing: Icon(Icons.arrow_forward_ios),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
