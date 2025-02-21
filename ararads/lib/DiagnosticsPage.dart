import 'package:EasyDS/easy_stem_connection.dart' as araraConnection;
import 'package:flutter/material.dart';

class DiagnosticPage extends StatefulWidget {
  const DiagnosticPage({Key? key}) : super(key: key);

  @override
  _DiagnosticPageState createState() => _DiagnosticPageState();
}

class _DiagnosticPageState extends State<DiagnosticPage> {
  int latency = -1;
  bool isConnected = false;
  late araraConnection.ICMPPingManager icmpPing;

  @override
  void initState() {
    super.initState();
    icmpPing = araraConnection.ICMPPingManager('192.168.4.1');
    _updateDiagnostics();
  }

  Future<void> _updateDiagnostics() async {
    while (mounted) {
      int? newLatency = await icmpPing.pingLatency();
      setState(() {
        latency = newLatency!;
        isConnected = newLatency > 0;
      });
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Status da Conexão:',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          Icon(
            isConnected ? Icons.wifi : Icons.signal_wifi_off,
            color: isConnected ? Colors.green : Colors.red,
            size: 50,
          ),
          const SizedBox(height: 20),
          Text(
            'Latência ICMP: ${latency > 0 ? "$latency ms" : "Desconectado"}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}
