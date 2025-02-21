import 'dart:async';

import 'package:EasyDS/DiagnosticsPage.dart';
import 'package:EasyDS/UploadPage.dart';
import 'package:EasyDS/easy_IDE.dart';
import 'package:EasyDS/easy_stem_connection.dart' as araraConnection;
import 'package:EasyDS/joystick.dart' as joystick;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static const ColorScheme myColorScheme = ColorScheme(
    primary: Color.fromARGB(255, 27, 25, 25),
    secondary: const Color(0xFF5D00D6),
    surface: Color.fromARGB(255, 92, 0, 193),
    error: const Color(0xFFFD6A63),
    onPrimary: Colors.white,
    onSecondary: Color(0xFFD0EC26),
    onSurface: Colors.white,
    onError: Colors.white,
    brightness: Brightness.dark,
    tertiary: Color.fromARGB(255, 249, 249, 249),
    onTertiary: Color.fromARGB(255, 27, 25, 25),
  );

  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Arara DS',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: myColorScheme,
          cardTheme: CardTheme(
            shadowColor: myColorScheme.primary,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // Softer rounded corners
            ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: myColorScheme.secondary,
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.5),
            titleTextStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: myColorScheme.onPrimary,
            ),
          ),
          textTheme: TextTheme(
            headlineMedium: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            displayLarge: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 32,
                fontWeight: FontWeight.normal),
            displayMedium: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 28,
                fontWeight: FontWeight.normal),
            displaySmall: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 27,
                fontWeight: FontWeight.w200),
            bodyLarge: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w500),
            bodyMedium: TextStyle(fontFamily: 'Poppins', fontSize: 16),
            bodySmall: TextStyle(fontFamily: 'Poppins', fontSize: 14),
            labelLarge: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: myColorScheme.secondary),
            labelMedium: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.normal),
            labelSmall: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.normal),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              padding: WidgetStatePropertyAll(
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
              ),
              textStyle: WidgetStatePropertyAll(
                const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
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
  final easyIDE = EasyIDE();
  bool araraConnectedViaWiFi = false;
  bool isEnabled = false;
  bool isReachable = false;
  bool wantedToDisconnect = false;
  bool disableSetted = false;
  Timer? pingTimer;
  Timer? checkControllerTimer;
  Timer? sendControllerTimer;
  int elseTickCount = 0;

  MyAppState() {
    easyIDE.initialize();
    _startPingMonitoring();
    checkControllers();
    sendControllerValues();
  }

  void _startPingMonitoring() {
    pingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      isReachable = await icmpPing.checkPing();
      if (isReachable && !wantedToDisconnect && !araraConnectedViaWiFi) {
        websocketConnection.connectWifi();
        araraConnectedViaWiFi = isReachable;
      } else if (!wantedToDisconnect) {
        araraConnectedViaWiFi = isReachable;
      }
      notifyListeners();
    });
  }

  void checkControllers() {
    checkControllerTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (controllers.controllerConnectedOrDisconnected()) {
        controllers.initialize();
      }
      notifyListeners();
    });
  }

  void sendControllerValues() {
    sendControllerTimer =
        Timer.periodic(const Duration(milliseconds: 25), (timer) async {
      try {
        if (araraConnectedViaWiFi && isEnabled) {
          controllers.setControllerState(isEnabled);
          await websocketConnection.sendValues(controllers.getJson());
          disableSetted = false;
          elseTickCount = 0;
        } else {
          if (!disableSetted && araraConnectedViaWiFi) {
            controllers.setControllerState(false);
            await websocketConnection.sendValues(controllers.getJson());
            elseTickCount++;
          }
          if (elseTickCount >= 5) {
            disableSetted = true;
          }
        }
      } catch (e) {
        print('Error sending values: $e');
        wantedToDisconnect = true;
        websocketConnection.disconnectWifi();
        araraConnectedViaWiFi = false;
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
      if (araraConnectedViaWiFi) {
        wantedToDisconnect = true;
        websocketConnection.disconnectWifi();
        araraConnectedViaWiFi = false;
      } else {
        final success = await websocketConnection.connectWifi();
        araraConnectedViaWiFi = success;
        wantedToDisconnect = false;
      }
    }
    notifyListeners();
  }

  Future<void> openEasyIDE() async {
    easyIDE.installAndRun();
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
    var appState = context.watch<MyAppState>();

    switch (selectedIndex) {
      case 0:
        page = const HomePage();
        break;
      case 1:
        page = const UploadPage();
        break;
      case 2:
        page = const DiagnosticPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          automaticallyImplyLeading: false,
          centerTitle: true,
          leadingWidth: 250,
          leading: Transform.scale(
            scale: 6.0,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
              child: Image.asset(
                "assets/Easy Steam/Logo/Logo principal/4.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
          title: Text(
            'EasyDS',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSecondary,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                leading: IconButton(
                  iconSize: 150, // Set button size
                  icon: SizedBox(
                    height: 80, // Set height
                    width: 80, // Set width
                    child: Image.asset(
                      'assets/Easy Steam/Logo/Ícone/2.png',
                      fit: BoxFit
                          .contain, // Adjust image to fill the box properly
                    ),
                  ),
                  tooltip: "Easy IDE Blocks",
                  onPressed: () {
                    appState.openEasyIDE();
                  },
                ),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
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
                selectedIconTheme: IconThemeData(
                    color: Theme.of(context)
                        .colorScheme
                        .onSecondary), // Keeps selected icon in the theme color
                unselectedIconTheme: const IconThemeData(
                    color: Colors.black), // Makes unselected icons black
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
    });
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    TextTheme theme = Theme.of(context).textTheme;
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: appState.araraConnectedViaWiFi ? 1.0 : 0,
              duration: const Duration(milliseconds: 500),
              child: appState.araraConnectedViaWiFi
                  ? SizedBox(
                      width: 200, // Aumenta a largura do botão
                      height: 60, // Aumenta a altura do botão
                      child: ElevatedButton(
                        onPressed: () {
                          appState.toggleEnabled();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appState.isEnabled
                              ? Colors.red
                              : Theme.of(context).colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(
                              vertical: 20), // Expande internamente
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                16), // Cantos mais arredondados
                          ),
                        ),
                        child: Text(
                          appState.isEnabled ? 'DESABILITAR' : 'HABILITAR',
                          style: theme.labelLarge?.copyWith(
                            fontSize: 20, // Aumenta o tamanho da fonte
                            fontWeight: FontWeight.w500, // Deixa mais destacado
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 70),
            Card(
              child: Container(
                width: 250,
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit
                            .scaleDown, // Evita que o texto estoure os limites
                        child: Text(
                          "Conexão",
                          style: theme.bodyLarge?.copyWith(
                              fontSize: 22), // Aumenta a fonte dinamicamente
                        ),
                      ),
                    ),

                    // Ícone responsivo ao tamanho do Card
                    FittedBox(
                      child: Icon(
                        appState.araraConnectedViaWiFi
                            ? Icons.signal_cellular_4_bar_outlined
                            : Icons
                                .signal_cellular_connected_no_internet_0_bar_outlined,
                        color: appState.araraConnectedViaWiFi
                            ? Theme.of(context).colorScheme.onSecondary
                            : Theme.of(context).colorScheme.error,
                        size: 30, // Ajuste dinâmico do tamanho do ícone
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            connectToAraraButton(appState, context),
            const SizedBox(height: 50),
            if (appState.controllers.availableControllers.isNotEmpty)
              listOfConnectedControllers(appState)
            else
              Card(
                color: Theme.of(context).colorScheme.tertiary,
                child: SizedBox(
                  height: 50,
                  width: 250,
                  child: Center(
                    child: Text('Nenhum controle conectado',
                        style: theme.labelLarge),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Center listOfConnectedControllers(MyAppState appState) {
    return Center(
      child: SizedBox(
        width: 200, // Defina a largura desejada para a lista
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: appState.controllers.availableControllers.length,
          itemBuilder: (context, index) {
            final controller = appState.controllers.availableControllers[index];
            final isButtonPressed = appState
                .controllers.jsonArray[index].entries
                .where((entry) => entry.key != 'EN')
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            );
          },
        ),
      ),
    );
  }

  ElevatedButton connectToAraraButton(
      MyAppState appState, BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        await appState.useConnectButton(context);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateColor.resolveWith(
          (Set<WidgetState> states) {
            return appState.araraConnectedViaWiFi
                ? Theme.of(context).colorScheme.error // Red when disconnecting
                : Theme.of(context)
                    .colorScheme
                    .onSecondary; // Green when connecting
          },
        ),
        foregroundColor: WidgetStateColor.resolveWith(
          (Set<WidgetState> states) {
            return appState.araraConnectedViaWiFi
                ? Colors.white // White text when disconnecting
                : Theme.of(context)
                    .colorScheme
                    .secondary; // Secondary-colored text when connecting
          },
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        padding: WidgetStatePropertyAll(
          const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        ),
        textStyle: WidgetStatePropertyAll(
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      label: Text(
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.secondary),
        appState.araraConnectedViaWiFi ? 'Desconectar' : 'Conectar',
      ),
      icon: Icon(
        appState.araraConnectedViaWiFi ? Icons.wifi_off : Icons.wifi,
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}
