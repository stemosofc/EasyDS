import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:process_run/shell.dart';

class Esp32Deployer {
  String esptoolPath;
  final int baudRate;

  Esp32Deployer({
    required this.esptoolPath,
    this.baudRate = 115200,
  });

  static Future<Esp32Deployer> create({int baudRate = 115200}) async {
    final esptoolPath = await _extractEsptool();
    return Esp32Deployer(
      esptoolPath: esptoolPath,
      baudRate: baudRate,
    );
  }

  Future<void> deployCode(String codeName) async {
    print('Chamando shell');
   final shell = Shell();
    print('Chamando detectPort...');
   String? portDetected = await detectPort();
    if (portDetected == null) {
     print('Erro: Nenhuma porta detectada. Conecte a ESP32 e tente novamente. ❌');
     return;
    }
    final bootloaderPath = 'assets/codes/ArduinoFiles/$codeName/$codeName.ino.bootloader.bin';
    final partitionsPath = 'assets/codes/ArduinoFiles/$codeName/$codeName.ino.partitions.bin';
    final appBinPath = 'assets/codes/ArduinoFiles/$codeName/$codeName.inobin';
    try {
     print('Iniciando upload do firmware para a porta $portDetected...');
      await shell.run('''
        "$esptoolPath" --chip esp32 --port $portDetected --baud $baudRate write_flash \
          0x1000 $bootloaderPath \
          0x8000 $partitionsPath \
         0x10000 $appBinPath
     ''');
      print('Upload concluído com sucesso! 🚀');
    } catch (e) {
     print('Erro durante o upload: $e ❌');
    }
  }


  static Future<String> _extractEsptool() async {
    final byteData = await rootBundle.load('assets/codes/esptool.exe');
    final tempDir = Directory.systemTemp.createTempSync();
    final tempEsptool = File('${tempDir.path}/esptool.exe');
    await tempEsptool.writeAsBytes(byteData.buffer.asUint8List());
    return tempEsptool.path;
  }

  Future<String?> detectPort() async {
    try {
      final result = await Process.run('cmd', ['/c', 'mode']);
      print('Comando "mode" executado com sucesso.');
      final output = result.stdout as String;
      final matches = RegExp(r'COM\d+').allMatches(output);
      if (matches.isNotEmpty) {
        print('Portas detectadas: ${matches.map((e) => e.group(0)).join(', ')}');
        return matches.first.group(0); 
      } else {
       print('Nenhuma porta COM detectada.');
        return null;
      }
    } catch (e) {
     debugPrint('Erro ao detectar porta: $e');
     return null;
    }
  }

}
