import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ararads/websockets_connection.dart' as websockets;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Arara DS',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(100,43, 76, 120)),
          textTheme: const TextTheme()
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  bool araraConnectedViaWiFi = false;

  Future<void> connect() async {
    if (!araraConnectedViaWiFi) {
      final success = await websockets.connectWifi();
      if (success) {
        araraConnectedViaWiFi = true;
      } else {
        araraConnectedViaWiFi = false;
      }
    } else {
      debugPrint("Já conectado");
    }
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = const HomePage();
        break;
      case 1:
        page = const Placeholder();
        break;
      case 2:
        page = const Placeholder();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
}
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).primaryColor,
          automaticallyImplyLeading: false,
          iconTheme: IconTheme.of(context),
          leadingWidth: 200,
          leading: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 5.0),
            child: 
              Image.asset('assets/leadingAraraIcon.png', color: Colors.white),
            ),
          title: Text(
            'Painel de Controle',
            style: Theme.of(context).textTheme.displaySmall
            ),
          ),
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  minExtendedWidth: 200,
                  extended: false,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Página Inicial'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.code),
                      label: Text('Códigos Prontos'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.network_wifi_3_bar),
                      label: Text('Diagnóstico'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
  
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>(); 
    TextTheme theme = Theme.of(context).textTheme;
    return Container(
      child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                  Card(
                    child: SizedBox(
                      width: 150,
                      height: 50,
                      child: Center(
                        child: Row(
                          children: [
                            const SizedBox(width: 10,),
                            Text("Conexão", style: theme.bodyLarge),
                            const SizedBox(width: 30,),
                            Icon(appState.araraConnectedViaWiFi ? Icons.signal_cellular_4_bar_outlined : 
                            Icons.signal_cellular_connected_no_internet_0_bar_outlined)
                          ],
                        ),
                      )
                    ),
                  ),
                  SizedBox(height: 50,), 
                  ElevatedButton.icon(
                    onPressed: () async {
                      await appState.connect();
                    },
                    label: const Text('Conectar'),
                  ),
            ],
              ),
          ),
    );
  }
}


