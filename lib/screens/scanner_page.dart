import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../utils/api_service.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  CameraController? _camera;
  bool _isScanning = false;
  String _thaiName = "กำลังรอสแกน...";
  double _confidence = 0.0;

  final thaiNames = {
    'somdej': 'พระสมเด็จ',
    'luang_pu_thuat': 'หลวงปู่ทวด',
    'luang_pho_sothorn': 'หลวงพ่อโสธร',
    'luang_pho_khun': 'หลวงพ่อคูณ',
    'luang_pho_ruay': 'หลวงพ่อรวย',
    'phra_pidta': 'พระปิดตา',
    'luang_pho_pan_khrut': 'หลวงพ่อปานพิมพ์ครุฑ',
    'phra_khun_pan': 'พระขุนแผน',
  };

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _camera = CameraController(cameras[0], ResolutionPreset.medium);
    await _camera!.initialize();
    if (mounted) setState(() {});
    
    Timer.periodic(const Duration(milliseconds: 800), (_) => _scanFrame());
  }

  Future<void> _scanFrame() async {
    if (_isScanning || _camera == null || !_camera!.value.isInitialized) return;
    _isScanning = true;

    try {
      final image = await _camera!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final result = await ApiService.scanAmulet(base64Image);
      final predictions = result['predictions']?['predictions'];

      if (predictions != null && predictions.isNotEmpty) {
        final topClass = predictions[0]['class'];
        final confidence = predictions[0]['confidence'].toDouble();

        if (mounted) {
          setState(() {
            _thaiName = thaiNames[topClass] ?? topClass;
            _confidence = confidence;
          });
        }
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      _isScanning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_camera == null || !_camera!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_camera!),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _thaiName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ความมั่นใจ: ${(_confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: _confidence > 0.6 ? Colors.greenAccent : Colors.orange,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }
}
