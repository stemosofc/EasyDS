import 'package:flutter/material.dart';

import 'esp32_deployer.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({Key? key}) : super(key: key);

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  late Esp32Deployer deployer;
  String? _selectedCode; // Código selecionado na lista
  bool _isUploading = false; // Status do upload
  String _statusMessage = ''; // Mensagem de status do upload

  _UploadPageState() {
    initializeDeployer();
  }
  // Lista de códigos prontos para seleção
  final List<String> _availableCodes = [
    'codigo1',
    'codigo2',
    'codigo3',
  ];

  @override
  void initState() {
    super.initState();
    _statusMessage = 'Selecione um código e clique em "Enviar para ESP32"';
  }

  Future<void> initializeDeployer() async {
    deployer = await Esp32Deployer.create();
  }

  Future<void> _uploadFile() async {
    if (_selectedCode == null) {
      setState(() {
        _statusMessage = 'Erro: Nenhum código selecionado.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _statusMessage = 'Iniciando o upload do código: $_selectedCode...';
    });

    try {
      await deployer.deployCode(_selectedCode!);
      setState(() {
        _isUploading = false;
        _statusMessage = 'Upload concluído com sucesso para $_selectedCode! 🚀';
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _statusMessage = 'Erro durante o upload: $e ❌';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<String>(
            value: _selectedCode,
            hint: const Text('Selecione um código'),
            items: _availableCodes.map((String code) {
              return DropdownMenuItem<String>(
                value: code,
                child: Text(code),
              );
            }).toList(),
            onChanged: (String? value) {
              setState(() {
                _selectedCode = value;
                _statusMessage = 'Código selecionado: $value';
              });
            },
          ),
          const SizedBox(height: 20),
          // Botão para iniciar o upload
          ElevatedButton(
            onPressed: _isUploading ? null : _uploadFile,
            child: _isUploading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : const Text('Enviar para ESP32'),
          ),
          const SizedBox(height: 20),

          // Mensagem de status
          Text(
            _statusMessage,
            style: TextStyle(
              color: _isUploading ? Colors.orange : Colors.black,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
