
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

WebSocketChannel? ws;

Future<bool> connectWifi() async {
  try{
  ws = WebSocketChannel.connect(Uri.parse('ws://192.168.4.1/ws'));
  await Future.delayed(Duration(milliseconds: 10));
      return await _checkConnection();
  }catch (e) {
    return false;
  }
}

Future<void> disconnectWifi() async {
    try {
    await ws?.sink.close(status.goingAway);
  } catch (e) {
    // Handle disconnection error if needed
  }
}

Future<Duration> getPing() async {
  final Completer<Duration> completer = Completer<Duration>();
  final start = DateTime.now();
  ws?.sink.add('ping');
  ws?.stream.listen((message) {
    if (message == 'pong' && !completer.isCompleted) {
      final latency = DateTime.now().difference(start);
      completer.complete(latency);
    }
  }, onError: (error) {
    if (!completer.isCompleted) {
      completer.completeError('Erro ao calcular ping: $error');
    }
  });
  return completer.future;
}

Future<void> sendValues(String mensagem) async {
  if (ws != null) {
    ws?.sink.add(mensagem);
  } else {
    throw Exception('Conexão WebSocket não estabelecida');
  }
}

Future<bool> _checkConnection() async {
  final Completer<bool> completer = Completer<bool>();
  ws?.stream.listen(
    (message) {
      print('Mensagem recebida do WebSocket: $message');
      if (message.contains('connected')) {
        completer.complete(true);
      }
    },
    onError: (error) {
      print('Erro de WebSocket: $error');
      completer.complete(false);
    },
    onDone: () {
      completer.complete(false);
    },
  );
  await Future.delayed(Duration(seconds: 1));
  return completer.future;
}
