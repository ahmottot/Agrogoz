import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const AgroGozApp());
}

class AgroGozApp extends StatelessWidget {
  const AgroGozApp({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2F7D4F);
    return MaterialApp(
      title: 'AGROGÖZ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: green,
        scaffoldBackgroundColor: const Color(0xFFF4F6F2),
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}

class Prediction {
  final String label;
  final String description;
  final String prevention;
  final String treatment;
  final double confidence;
  Prediction({
    required this.label,
    required this.description,
    required this.prevention,
    required this.treatment,
    required this.confidence,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Interpreter? _interpreter;
  List<dynamic>? _labels;
  File? _imageFile;
  bool _loadingModel = true;
  bool _running = false;
  String? _error;
  List<Prediction> _results = [];

  static const int inputSize = 224;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/plant_model.tflite');
      final labelsStr = await rootBundle.loadString('assets/labels.json');
      _labels = json.decode(labelsStr) as List<dynamic>;
    } catch (e) {
      _error = 'Model yüklenemedi: $e';
    } finally {
      setState(() => _loadingModel = false);
    }
  }

  Future<void> _pickAndRun(ImageSource source) async {
    setState(() {
      _error = null;
      _results = [];
    });
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 90,
    );
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _imageFile = file;
      _running = true;
    });

    try {
      final results = await _runInference(file);
      setState(() {
        _results = results;
        _running = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Analiz sırasında hata oluştu: $e';
        _running = false;
      });
    }
  }

  Future<List<Prediction>> _runInference(File file) async {
    if (_interpreter == null || _labels == null) {
      throw Exception('Model hazır değil');
    }

    final bytes = await file.readAsBytes();
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Görsel okunamadı');

    final resized = img.copyResize(decoded, width: inputSize, height: inputSize);

    // Model 224x224x3 float32, ham piksel degerleri (0-255) bekliyor.
    var input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final p = resized.getPixel(x, y);
            return [p.r.toDouble(), p.g.toDouble(), p.b.toDouble()];
          },
        ),
      ),
    );

    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final numClasses = outputShape.last;
    var output = List.generate(1, (_) => List.filled(numClasses, 0.0));

    _interpreter!.run(input, output);

    final scores = List<double>.from(output[0]);
    final indices = List<int>.generate(scores.length, (i) => i)
      ..sort((a, b) => scores[b].compareTo(scores[a]));

    final top = indices.take(3).toList();
    final sumTop = top.fold<double>(0, (s, i) => s + scores[i]);

    return top.map((i) {
      final labelData = (i < _labels!.length)
          ? _labels![i] as Map<String, dynamic>
          : {'label': 'Bilinmeyen', 'description': '', 'prevention': '', 'treatment': ''};
      final conf = sumTop > 0 ? (scores[i] / sumTop) * 100 : 0.0;
      return Prediction(
        label: labelData['label'] ?? '',
        description: labelData['description'] ?? '',
        prevention: labelData['prevention'] ?? '',
        treatment: labelData['treatment'] ?? '',
        confidence: conf,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final green = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Center(
                child: Text('🌿', style: TextStyle(fontSize: 44)),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'AGROGÖZ',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Bitki yaprağının fotoğrafını çek, cihaz üzerinde\nanında analiz edilsin (internet gerekmez).',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFFF4F6F2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _imageFile == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt_outlined,
                                        size: 40, color: Colors.grey.shade500),
                                    const SizedBox(height: 8),
                                    Text('Henüz fotoğraf çekilmedi',
                                        style: TextStyle(color: Colors.grey.shade600)),
                                  ],
                                ),
                              )
                            : Image.file(_imageFile!, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loadingModel)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 10),
                            Text('Model yükleniyor…'),
                          ],
                        ),
                      )
                    else ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _running
                              ? null
                              : () => _pickAndRun(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Fotoğraf Çek'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _running
                              ? null
                              : () => _pickAndRun(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Galeriden Seç'),
                        ),
                      ),
                    ],
                    if (_running)
                      const Padding(
                        padding: EdgeInsets.only(top: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 10),
                            Text('Analiz ediliyor…'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF1E8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFB3441F)),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: Color(0xFFB3441F))),
                ),

              if (_results.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Teşhis Sonucu',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                ..._results.asMap().entries.map((entry) {
                  final i = entry.key;
                  final r = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: i == 0 ? green : Colors.grey.shade300,
                          width: i == 0 ? 1.5 : 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: i == 0 ? 16 : 14,
                                  color: i == 0 ? green : null,
                                ),
                              ),
                            ),
                            Text('%${r.confidence.toStringAsFixed(1)}',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                        if (r.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(r.description,
                              style: const TextStyle(fontSize: 13, height: 1.4)),
                        ],
                        if (r.treatment.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Öneri: ${r.treatment}',
                              style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: Colors.grey.shade700)),
                        ],
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Sonuçlar bilgilendirme amaçlıdır; kesin teşhis için\ntarım uzmanına danışın.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
