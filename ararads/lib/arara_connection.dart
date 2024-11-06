
import 'dart:async';
import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;


class websocketConnection{

WebSocketChannel? ws;

Future<bool> connectWifi() async {
  try{
  ws = WebSocketChannel.connect(Uri.parse('ws://192.168.4.1/ws'));
  return await checkConnection().timeout(
      const Duration(seconds: 5), // **Timeout adicionado para limitar a tentativa de conexão**
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
  await Future.delayed(const Duration(seconds: 2));
  if (!completer.isCompleted) {
    completer.complete(false);
  }
  return completer.future;
}

Future<bool> endOfConnection() async {
  final Completer<bool> completer = Completer<bool>();
  if (kDebugMode) {
        debugPrint('Indo escutar');
      }
  ws?.stream.listen(
    (message) {
      if (kDebugMode) {
        debugPrint('Mensagem recebida do WebSocket: $message');
      }
      if (message.contains('Desconectado') && !completer.isCompleted) {
        completer.complete(true);
      }
    },
    onError: (error) {
      if (kDebugMode) {
        debugPrint('Erro de WebSocket: $error');
      }
      if (!completer.isCompleted) {
        completer.complete(true);
      }
    },
    onDone: () {
      if (kDebugMode) {
        debugPrint('Mensagem recebida');
      }
      if (!completer.isCompleted) {
        completer.complete(true);
      }
    },
  );
  await Future.delayed(const Duration(seconds: 2));
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
  final ping = Ping(ipAddress, count: 1, timeout: 1); // Um ping único com timeout de 1 segundo
  Completer<bool> completer = Completer<bool>();

  ping.stream.listen(
    (event) {
      if (!completer.isCompleted) {
        if (event.response != null) {
          completer.complete(true); // Ping bem-sucedido
        } else {
          completer.complete(false); // Ping falhou
        }
      }
    },
    onError: (error) {
      if (!completer.isCompleted) {
        completer.complete(false); // Completa com falso em caso de erro
      }
    },
    onDone: () {
      if (!completer.isCompleted) {
        completer.complete(false); // Completa com falso se o stream terminar sem resposta
      }
    },
  );

  // Define um tempo limite para o ping, retornando falso se o tempo limite for excedido
  return completer.future.timeout(
    Duration(seconds: 2),
    onTimeout: () => false,
  );
}


  Future<Duration?> ping() async {
    final ping = Ping(ipAddress, count: 1, timeout: 1); // Um ping com timeout de 1 segundo
    Completer<Duration?> completer = Completer<Duration?>();
    ping.stream.listen(
      (event) {
        if (event.response != null) {
          final responseTime = event.response!.time!.inMilliseconds;
          completer.complete(Duration(milliseconds: responseTime));
        } else {
          completer.complete(null);
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError('Erro ao tentar ping: $error');
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(null); // Caso o ping não tenha retornado uma resposta
        }
      },
    );

    // Define um tempo limite para o ping
    return completer.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () => null,
    );
  }

  // Método para monitorar a conectividade periodicamente
  Stream<bool> monitorConnection({int intervalSeconds = 5}) async* {
    while (true) {
      final response = await ping();
      yield response != null; // Retorna verdadeiro se houver resposta, falso se não houver
      await Future.delayed(Duration(seconds: intervalSeconds));
    }
  }
}
