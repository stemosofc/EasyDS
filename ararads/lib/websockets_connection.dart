
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

WebSocketChannel? ws;

Future<bool> connectWifi() async {
  try{
  ws = WebSocketChannel.connect(Uri.parse('ws://192.168.4.1/ws'));
  return await checkConnection().timeout(
      Duration(seconds: 5), // **Timeout adicionado para limitar a tentativa de conexão**
      onTimeout: () {
        return false;
      }
    );
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
  // Cria um Completer para retornar o tempo de resposta (ping)
  final Completer<Duration> completer = Completer<Duration>();
  final start = DateTime.now();

  // Verifica se o WebSocket está conectado antes de enviar o ping
  if (ws == null || ws?.sink == null) {
    return Future.error('Conexão WebSocket não estabelecida');
  }

  // Envia a mensagem "ping" pelo WebSocket
  ws?.sink.add('ping');

  // Configura o listener para aguardar uma resposta "pong"
  late StreamSubscription subscription;
  subscription = ws!.stream.listen(
    (message) {
      if (message == 'pong' && !completer.isCompleted) {
        // Calcula a latência e completa o Completer com o valor
        final latency = DateTime.now().difference(start);
        completer.complete(latency);
        subscription.cancel(); // Cancela a assinatura após receber o "pong"
      }
    },
    onError: (error) {
      // Completa o Completer com um erro se ocorrer um problema
      if (!completer.isCompleted) {
        completer.completeError('Erro ao calcular ping: $error');
      }
      subscription.cancel();
    },
    onDone: () {
      // Completa o Completer com erro se o WebSocket for fechado
      if (!completer.isCompleted) {
        completer.completeError('Conexão WebSocket fechada');
      }
      subscription.cancel();
    },
  );

  // Define um tempo limite para evitar que o Future fique pendente indefinidamente
  return completer.future.timeout(
    Duration(seconds: 5),
    onTimeout: () {
      if (!completer.isCompleted) {
        completer.completeError('Tempo limite excedido para resposta de ping');
      }
      subscription.cancel();
      return Duration.zero;
    },
  );
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
  if (kDebugMode) {
        debugPrint('Indo escutar');
      }
  ws?.stream.listen(
    (message) {
      if (kDebugMode) {
        debugPrint('Mensagem recebida do WebSocket: $message');
      }
      if (message.contains('Conectado') && !completer.isCompleted) {
        completer.complete(true);
      }
    },
    onError: (error) {
      if (kDebugMode) {
        debugPrint('Erro de WebSocket: $error');
      }
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    },
    onDone: () {
      if (kDebugMode) {
        debugPrint('Mensagem recebida');
      }
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    },
  );
  await Future.delayed(Duration(seconds: 2));
  if (!completer.isCompleted) {
    completer.complete(false);
  }
  return completer.future;
}

