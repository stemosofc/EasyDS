
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:io';
import 'package:ping_win32/ping_win32.dart';



class websocketConnection{

WebSocketChannel? ws;

websocketConnection(){
}

Future<bool> connectWifi() async {
  try{
  ws = WebSocketChannel.connect(Uri.parse('ws://192.168.4.1/ws'));
  debugPrint("CONECTANDO NESSA PORRA AI CARALHO");
  return await checkConnection().timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        return false;
      }
    );
  }catch (e) {
    return false;
  }
}

String? checkCloseReason() {
  if(ws != null){
    return ws?.closeReason;
  }
  return "not connected";
}

Future<void> disconnectWifi() async {
    try {
    await ws?.sink.close(1000, "Encerramento Normal");
  } catch (e) {
  }
}

Future<void> sendValues(String mensagem) async {
  if (ws != null) {
    ws?.sink.add(mensagem);
  } else {
    throw Exception('Conexão WebSocket não estabelecida');
  }
}

Future<bool> checkConnection() async {
  final Completer<bool> completer = Completer<bool>();
  ws?.stream.listen(
    (message) {
      if (message.contains('Conectado') && !completer.isCompleted) {
        completer.complete(true);
      }
    },
    onError: (error) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    },
    onDone: () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    },
  );
  await Future.delayed(const Duration(seconds: 1));
  if (!completer.isCompleted) {
    completer.complete(false);
  }
  return completer.future;
}
}

class ICMPPingManager {
  final String ipAddress;
  ICMPPingManager(this.ipAddress);
  
  


  Future<bool> checkPing() async {
  final ping = await PingWin32.ping(
    InternetAddress.tryParse(ipAddress)!,
    timeout: Duration(seconds: 2),
  );
  Completer<bool> completer = Completer<bool>();
  if(ping != null){
    if(ping.statusString == "IP_SUCCESS"){
      completer.complete(true);
    }
  }
  // Define um tempo limite para o ping, retornando falso se o tempo limite for excedido
  return completer.future.timeout(
    const Duration(seconds: 2),
    onTimeout: () => false,
  );
  }
}
