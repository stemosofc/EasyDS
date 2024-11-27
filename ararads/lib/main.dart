
import 'dart:async';
import 'esp32_deployer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ararads/arara_connection.dart' as araraConnection;
import 'package:ararads/joystick.dart' as joystick;

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
  final websocketConnection = araraConnection.websocketConnection();
  final icmpPing = araraConnection.ICMPPingManager('192.168.4.1');
  final controllers = joystick.Joystick();
  bool araraConnectedViaWiFi = false;
  bool isEnabled = false;
  bool isReachable = false;
  bool wantedToDisconnect = false;
  Timer? pingTimer;
  Timer? checkControllerTimer;
  Timer? sendControllerTimer;


  MyAppState() {
    _startPingMonitoring();
    checkControllers();
    sendControllerValues();
  }

  void _startPingMonitoring() {
    pingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
    isReachable = await icmpPing.checkPing();
    if(isReachable && !wantedToDisconnect && !araraConnectedViaWiFi){
      websocketConnection.connectWifi();
      araraConnectedViaWiFi = isReachable;
    }else if(!wantedToDisconnect){
      araraConnectedViaWiFi = isReachable;
    }
    notifyListeners();
    });
  }

    void checkControllers() {
    checkControllerTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
    if(controllers.controllerConnectedOrDisconnected()){
      controllers.initialize();
    }
    notifyListeners();
    });
  }

  void sendControllerValues() {
    sendControllerTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) async {
    if(araraConnectedViaWiFi && isEnabled){
      websocketConnection.sendValues(controllers.getJson());
    }else{
      isEnabled = false;
    }
    notifyListeners();
    });
  }

  @override
  void dispose() {
    pingTimer?.cancel();
    super.dispose();
  }

  Future<void> useConnectButton(BuildContext context) async {
    if ((!araraConnectedViaWiFi && !wantedToDisconnect) || !isReachable) {
      showDisconnectedMessage(context);
    } else {
      if(araraConnectedViaWiFi){
        wantedToDisconnect = true;
        websocketConnection.disconnectWifi();
        araraConnectedViaWiFi = false;
      }else{
        final success = await websocketConnection.connectWifi();
        araraConnectedViaWiFi = success;
        wantedToDisconnect = false;
      }
    }
    notifyListeners();
  }

  void showDisconnectedMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Erro de Conexão'),
          content: const Text('A placa não está conectada ao Wi-Fi.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  void toggleEnabled() {
    isEnabled = !isEnabled; // Alterna entre habilitar e desabilitar
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
        page = const UploadPage();
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
            AnimatedOpacity(
              opacity: appState.araraConnectedViaWiFi ? 1.0 : 0,
              duration: const Duration(milliseconds: 500),
              child: appState.araraConnectedViaWiFi ? ElevatedButton(
                onPressed: () {
                  appState.toggleEnabled();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appState.isEnabled ? Colors.red : Colors.green,
                ),
                child: Text(
                  style: theme.labelLarge,
                  appState.isEnabled ? 'Desabilitar' : 'Habilitar',
                ),
              ) : const SizedBox.shrink(),
            ),
          const SizedBox(height: 20),
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
                  const SizedBox(height: 50,), 
                  ElevatedButton.icon(
                    onPressed: () async {
                      await appState.useConnectButton(context);
                    },
                    label: appState.araraConnectedViaWiFi ?  const Text('Disconectar') : const Text('Conectar'),
                  ),
            const SizedBox(height: 50),
          if (appState.controllers.availableControllers.isNotEmpty)
            Center(
              child: SizedBox(
                width: 200, // Defina a largura desejada para a lista
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: appState.controllers.availableControllers.length,
                  itemBuilder: (context, index) {
                    final controller =
                        appState.controllers.availableControllers[index];
                    final isButtonPressed = appState.controllers.jsonArray[index]
                        .entries
                        .any((entry) => entry.value == true);
                    return ListTile(
                      leading: Icon(Icons.gamepad,
                          color: isButtonPressed ? Colors.green : Colors.grey),
                      title: Text('Controle ${controller.index}'),
                      subtitle: Text('Status: Conectado'),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16.0),
                    );
                  },
                ),
              ),
            )
          else
            Card(
              child: SizedBox(
                height: 50,
                width: 250,
                child: Center(
                  child: Text(
                    'Nenhum controle conectado',
                    style: theme.labelLarge
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class UploadPage extends StatefulWidget {
  const UploadPage({Key? key}) : super(key: key);

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  late Esp32Deployer deployer;
  String? _selectedCode; // Código selecionado na lista
  bool _isUploading = false; // Status do upload
  String _statusMessage = ''; // Mensagem de status do upload

  _UploadPageState(){
    initializeDeployer(); 
  }
  // Lista de códigos prontos para seleção
  final List<String> _availableCodes = [
    'codigo1',
    'codigo2',
    'codigo3',
  ];

  @override
  void initState() {
    super.initState();
    _statusMessage = 'Selecione um código e clique em "Enviar para ESP32"';
  }

  Future<void> initializeDeployer() async {
    deployer = await Esp32Deployer.create(); 
  }

  Future<void> _uploadFile() async {
    if (_selectedCode == null) {
      setState(() {
        _statusMessage = 'Erro: Nenhum código selecionado.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _statusMessage = 'Iniciando o upload do código: $_selectedCode...';
    });

    try {
      await deployer.deployCode(_selectedCode!);
      setState(() {
        _isUploading = false;
        _statusMessage = 'Upload concluído com sucesso para $_selectedCode! 🚀';
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _statusMessage = 'Erro durante o upload: $e ❌';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload de Código'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<String>(
              value: _selectedCode,
              hint: const Text('Selecione um código'),
              items: _availableCodes.map((String code) {
                return DropdownMenuItem<String>(
                  value: code,
                  child: Text(code),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedCode = value;
                  _statusMessage = 'Código selecionado: $value';
                });
              },
            ),
            const SizedBox(height: 20),
            // Botão para iniciar o upload
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadFile,
              child: _isUploading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text('Enviar para ESP32'),
            ),
            const SizedBox(height: 20),

            // Mensagem de status
            Text(
              _statusMessage,
              style: TextStyle(
                color: _isUploading ? Colors.orange : Colors.black,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
