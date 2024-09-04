import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    @override
  notifyListeners();
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
          //leadingWidth: 300,
          leading: Padding(
            padding: const EdgeInsets.all(4.0),
            child: 
              Image.asset('assets/leadingAraraIcon.png'),
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
    return Container(
      child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                  const Card(
                    child: SizedBox(
                      width: 300,
                      height: 200,
                      child: Center(
                        child: Row(

                        ),
                      )
                    ),
                  ),
        
                  ElevatedButton.icon(
                    onPressed: () {
                    },
                    label: const Text('Conectar'),
                  ),
            ],
              ),
          ),
    );
  }
}


