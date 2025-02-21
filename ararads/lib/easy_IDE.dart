import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class EasyIDE {
  String _targetPath = "";

  EasyIDE() {}

  Future<void> initialize() async {
    await extractToTempDir();
  }

  Future<void> execute() async {
    try {
      Directory tempDir = await getApplicationDocumentsDirectory();
      String tempPath = '${tempDir.path}/EasySTEAM_IDE.exe';

      // Run as administrator using PowerShell
      Process.run('powershell', ['Start-Process', tempPath, '-Verb', 'runAs']);

      print('Executable started with admin privileges.');
    } catch (e) {
      print('Error opening file: $e');
    }
  }

  Future<void> extractToTempDir() async {
    Directory appDir = await getApplicationSupportDirectory();
    _targetPath = '${appDir.path}/EasySTEAM_IDE/';

    Directory(_targetPath).createSync(recursive: true);

    await copyAssetFile(
        'assets/ide/EasySTEAM_IDE.exe', '$_targetPath/EasySTEAM_IDE.exe');

    await extractZip('assets/ide/_internal.zip', _targetPath);
  }

  void installAndRun() {
    Process.run('powershell', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      "Start-Process -FilePath '$_targetPath/EasySTEAM_IDE.exe' -WorkingDirectory '$_targetPath' -Verb runAs"
    ]);
  }

  // Extracts a ZIP file from assets
  Future<void> extractZip(String assetPath, String destinationPath) async {
    ByteData data = await rootBundle.load(assetPath);
    List<int> bytes = data.buffer.asUint8List();

    Archive archive = ZipDecoder().decodeBytes(bytes);
    for (ArchiveFile file in archive) {
      String filePath = '$destinationPath/${file.name}';
      if (file.isFile) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(file.content as List<int>);
      } else {
        Directory(filePath).createSync(recursive: true);
      }
    }
  }

  // Copies a file from assets to a writable directory
  Future<void> copyAssetFile(String assetPath, String destinationPath) async {
    ByteData data = await rootBundle.load(assetPath);
    List<int> bytes = data.buffer.asUint8List();
    File(destinationPath).createSync(recursive: true);
    await File(destinationPath).writeAsBytes(bytes, flush: true);
  }
}
