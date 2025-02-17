import 'package:open_file/open_file.dart';

class EasyIDE {
  String _path = "";

  EasyIDE(String path) {
    _path = path;
  }

  void execute() async {
    await OpenFile.open(_path, type: ".exe");
  }

  // Method to stop the IDE
  void stop() {}

  // Additional methods and properties can be added here
}
