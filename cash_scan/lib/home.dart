import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gga;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  final ImagePicker _picker = ImagePicker();
  bool _isListening = false;
  bool _loading = false;
  String _responseText = '';
  File? _image;
  final String api = dotenv.env['API_KEY']!;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();
  }

  void _captureCurrencyImage() {
    _captureImage("detect");
  }

  void _countCurrencyImage() {
    _captureImage("count");
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.toLowerCase().contains("detect")) {
            _captureImage("detect");
            _speech.stop();
            setState(() => _isListening = false);
          }
          if (result.recognizedWords.toLowerCase().contains("count")) {
            _captureImage("count");
            _speech.stop();
            setState(() => _isListening = false);
          }
        },
      );
    }
  }

  Future<void> _captureImage(String operation) async {
    setState(() => _loading = true);

    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null && operation == "detect") {
      String image = pickedFile.path;
      setState(() {
        _image = File(image); // Store the picked image in the state variable
      });
      _detect(image);
    } else if (pickedFile != null && operation == "count") {
      String image = pickedFile.path;
      setState(() {
        _image = File(image); // Store the picked image in the state variable
      });
      _count(image);
    } else {
      setState(() {
        _loading = false;
        _responseText = "No image captured.";
      });
    }
  }

  Future<void> _count(String image) async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: api);

      final imageBytes = await File(image).readAsBytes();
      final prompt = TextPart(
          'Can you count how many currencies are there and the value of currencies and give me the response (eg. You have two 50 rupees and three 20 rupees with total of 160 rupees)');
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        gga.Content.multi([prompt, imagePart])
      ]);

      if (response != null) {
        _responseText = response.text ?? 'No response text received.';
      } else {
        _responseText = 'No response from Google Generative AI.';
      }
      _speak(_responseText);
    } catch (e) {
      _responseText = 'Error generating response: $e';
      print('Error: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _detect(String image) async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: api);

      final imageBytes = await File(image).readAsBytes();
      final prompt = TextPart(
          'Detect what currency I have and give response (eg. You have 20 rupees)');
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        gga.Content.multi([prompt, imagePart])
      ]);

      if (response != null) {
        _responseText = response.text ?? 'No response text received.';
      } else {
        _responseText = 'No response from Google Generative AI.';
      }
      _speak(_responseText);
    } catch (e) {
      _responseText = 'Error generating response: $e';
      print('Error: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _sendImageToServer(File image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.32.231:5000/predict'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        _responseText = jsonResponse['amount'];
        _speak("$_responseText rupees");
      } else {
        _responseText = "Error: Could not detect currency.";
      }
    } catch (e) {
      _responseText = "Error: Unable to connect to the server.";
    }
    setState(() => _loading = false);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Indian Currency Detection'),
        backgroundColor: Colors.amber,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _image != null
                    ? Image.file(_image!,
                        height: 200) // Display the image if it's not null
                    : const Icon(Icons.camera_alt,
                        size: 100,
                        color: Colors.grey), // Default icon if image is null

                const SizedBox(height: 20),
                const Text(
                  'Press the button and say "Capture" to detect currency.',
                  style: TextStyle(fontSize: 18, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _isListening ? null : _startListening,
                        icon: const Icon(Icons.mic),
                        label: Text(
                            _isListening ? "Listening..." : "Start Listening"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          backgroundColor: Colors.amber,
                          textStyle: const TextStyle(fontSize: 20),
                        ),
                      ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _captureCurrencyImage,
                  icon: const Icon(Icons.camera),
                  label: const Text("Detect currency"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    backgroundColor: Colors.blue,
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _countCurrencyImage,
                  icon: const Icon(Icons.camera),
                  label: const Text("Count currency"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    backgroundColor: Colors.blue,
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  _responseText,
                  style: const TextStyle(fontSize: 24, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
