import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class EasyIDE {
  EasyIDE() {}

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

  Future<void> installAndRun() async {
    try {
      // Get a writable directory
      Directory appDir = await getApplicationSupportDirectory();
      String targetPath = '${appDir.path}/EasySTEAM_IDE/';

      // Ensure main directory exists
      Directory(targetPath).createSync(recursive: true);

      // Copy the .exe file to the app directory
      await copyAssetFile(
          'assets/ide/EasySTEAM_IDE.exe', '$targetPath/EasySTEAM_IDE.exe');

      // Extract _internal.zip to the same directory
      await extractZip('assets/ide/_internal.zip', targetPath);

      // Run the executable with the correct working directory
      Process.run('powershell', [
        'Start-Process',
        '$targetPath/EasySTEAM_IDE.exe',
        '-WorkingDirectory',
        targetPath,
        '-Verb',
        'runAs'
      ]);

      print('EasySTEAM IDE installed and launched successfully.');
    } catch (e) {
      print('Error installing and running IDE: $e');
    }
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
