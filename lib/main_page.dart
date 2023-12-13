import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<String> dataList = [];
  final List<GlobalKey> _qrKeys = [];
  final TextEditingController _textController = TextEditingController();
  int imageCounter = 1; // Contador global de imágenes

  @override
  void initState() {
    super.initState();
    _qrKeys.add(GlobalKey());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Generator'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _textController,
                maxLines: null,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(10),
                  labelText: 'Enter Text',
                  labelStyle: TextStyle(color: Colors.grey),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 2, 129, 179),
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 2.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _clearData,
                  child: const Text('Clear QR Codes'),
                ),
                ElevatedButton(
                  onPressed: () => _captureAndSaveAll(),
                  child: const Text('Export All QRs'),
                ),
              ],
            ),
            const SizedBox(height: 15),
            RawMaterialButton(
              onPressed: () {
                _generateQRCodes(_textController.text);
                _textController.clear();
              },
              fillColor: Colors.blue,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
              child: const Text(
                'Generate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 15),
            ListView.separated(
              shrinkWrap: true,
              itemCount: dataList.length,
              separatorBuilder: (context, index) => const Divider(height: 10),
              itemBuilder: (context, index) {
                final data = dataList[index];
                final qrKey = _qrKeys[index];
                return Column(
                  children: [
                    RepaintBoundary(
                      key: qrKey,
                      child: QrImageView(
                        data: data,
                        version: QrVersions.auto,
                        size: 250.0,
                        gapless: true,
                        errorStateBuilder: (ctx, err) {
                          return const Center(
                            child: Text(
                              'Something went wrong!!!',
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Text: $data',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _generateQRCodes(String text) {
    final lines = text.split('\n');
    for (final line in lines) {
      if (line.isNotEmpty) {
        setState(() {
          dataList.add(line);
          _qrKeys.add(GlobalKey());
        });
      }
    }
  }

  void _clearData() {
    setState(() {
      dataList.clear();
      _qrKeys.clear();
      _qrKeys.add(GlobalKey());
      imageCounter = 1; // Reiniciar contador al limpiar datos
    });
  }

  Future<void> _captureAndSaveAll() async {
    for (int i = 0; i < dataList.length; i++) {
      await _captureAndSavePng(dataList[i], _qrKeys[i]);
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR codes saved to gallery')));
  }

  Future<void> _captureAndSavePng(String data, GlobalKey qrKey) async {
    try {
      RenderRepaintBoundary boundary = qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 3.0);

      final whitePaint = Paint()..color = Colors.white;
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()));
      canvas.drawRect(Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), whitePaint);
      canvas.drawImage(image, Offset.zero, Paint());
      final picture = recorder.endRecording();
      final img = await picture.toImage(image.width, image.height);
      ByteData? byteData = await img.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final externalDir = (await getExternalStorageDirectory())!.path;

      String fileName = 'qr_code';
      while (await File('$externalDir/$fileName$imageCounter.png').exists()) {
        imageCounter++;
      }

      final file = await File('$externalDir/$fileName$imageCounter.png').create();
      await file.writeAsBytes(pngBytes);
      imageCounter++;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Something went wrong!!!')));
    }
  }
}
