import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

import 'dart:convert';

import '../translations.dart';

// TODO: add these packages to pubspec.yaml when you're ready to make this
// screen fully functional:
//   audioplayers      -> to play the sample voice-prompt recordings
//   supabase_flutter  -> to upload the photo + save the product row

/// Base URL for your FastAPI services (image enhancement + voice-to-fields).
/// IMPORTANT: "localhost" means a different machine depending on where the
/// app is actually running:
///   - iOS Simulator / desktop / web (Chrome): http://localhost:8000 works.
///   - Android Emulator: use http://10.0.2.2:8000 instead -- on Android's
///     emulator, "localhost" refers to the emulator itself, not your PC.
///   - Physical phone (real device): use your computer's LAN IP, e.g.
///     http://192.168.1.42:8000 -- find it with `ipconfig` (Windows) or
///     `ifconfig`/`ipconfig getifaddr en0` (Mac), and make sure your phone
///     is on the same WiFi network as your computer.
String get _apiBaseUrl {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://localhost:8000';
}

class SellProductScreen extends StatefulWidget {
  final String languageCode;
  final String pehchanId;
  const SellProductScreen({
    super.key,
    required this.languageCode,
    required this.pehchanId,
  });

  @override
  State<SellProductScreen> createState() => _SellProductScreenState();
}

class _SellProductScreenState extends State<SellProductScreen> {
  // Form state
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _sizeController = TextEditingController();
  final _materialController = TextEditingController();
  final _colorController = TextEditingController();
  final _craftTechniqueController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _descriptionHindiController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  bool _hasPhoto = false; // becomes true once a photo is picked
  bool _isEnhancing = false; // true while AI is processing the image
  bool _isEnhanced = false; // true once the submitted photo comes back enhanced
  bool _isRecording = false; // true while mic is actively recording
  bool _isTranscribing =
      false; // true while the recorded audio is being processed
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _samplePlayer = AudioPlayer();
  File? _photoFile; // the picked photo, shown in the preview
  Uint8List? _enhancedBytes; // the PNG bytes returned by the AI enhancement API

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _sizeController.dispose();
    _materialController.dispose();
    _colorController.dispose();
    _craftTechniqueController.dispose();
    _descriptionController.dispose();
    _descriptionHindiController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _audioRecorder.dispose();
    _samplePlayer.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    // Let the artisan choose camera or gallery.
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo | फोटो लें'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery | गैलरी से चुनें'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return; // user dismissed the sheet

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85, // compress a bit so uploads are faster later
    );
    if (picked == null) return; // user cancelled picking

    setState(() {
      _photoFile = File(picked.path);
      _hasPhoto = true;
      _isEnhanced =
          false; // a freshly picked photo is not yet submitted/enhanced
      _enhancedBytes = null;
    });
  }

  Future<void> _submitPhoto() async {
    if (_photoFile == null || _isEnhancing) return;

    setState(() => _isEnhancing = true);

    try {
      final uri = Uri.parse('$_apiBaseUrl/image');
      final request = http.MultipartRequest(
        'POST',
        uri,
      )..files.add(await http.MultipartFile.fromPath('file', _photoFile!.path));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() {
          _enhancedBytes = response.bodyBytes; // raw PNG bytes
          _isEnhancing = false;
          _isEnhanced = true;
        });
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isEnhancing = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Enhancement failed: $e')));
      }
    }
  }

  // void _playSampleVoicePrompt() {
  //   // TODO: play the pre-recorded sample audio for widget.languageCode here,
  //   // e.g. using audioplayers with an asset like
  //   // 'assets/voice_prompts/${widget.languageCode}.mp3'
  // }
  Future<void> _playSampleVoicePrompt() async {
    try {
      await _samplePlayer.stop();
      await _samplePlayer.play(
        AssetSource('voice_prompts/${widget.languageCode}.mp3'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not play sample: $e')));
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (!_isRecording) {
      // --- Start recording ---
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required to record.'),
            ),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/product_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() => _isRecording = true);
    } else {
      // --- Stop recording, then upload for transcription/parsing ---
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isTranscribing = path != null;
      });
      if (path == null) return;

      try {
        final uri = Uri.parse('$_apiBaseUrl/process-voice');
        final request = http.MultipartRequest('POST', uri)
          ..files.add(await http.MultipartFile.fromPath('audio_file', path))
          ..fields['native_lang'] = widget.languageCode;
        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 120),
        );
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          // TODO: match these keys to whatever your FastAPI /voice endpoint
          // actually returns -- adjust the key names below as needed.
          _fillIfPresent(_nameController, data['product_Name']);
          _fillIfPresent(_categoryController, data['category']);
          _fillIfPresent(_sizeController, data['size']);
          _fillIfPresent(_materialController, data['Material']);
          _fillIfPresent(_colorController, data['color']);
          _fillIfPresent(_craftTechniqueController, data['crafting_technique']);
          _fillIfPresent(_descriptionController, data['Description']);
          _fillIfPresent(_descriptionHindiController, data['hindi_dec']);
          _fillIfPresent(_priceController, data['suggested_price']);
          _fillIfPresent(_stockController, data['stock']);
        } else {
          throw Exception('Server returned ${response.statusCode}');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Voice processing failed: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isTranscribing = false);
      }
    }
  }

  /// Sets [controller]'s text from [value] if it isn't null/empty.
  /// Handles the field arriving as a String or a number from the API.
  void _fillIfPresent(TextEditingController controller, dynamic value) {
    if (value == null) return;
    final text = value.toString();
    if (text.isNotEmpty) controller.text = text;
  }

  // Future<void> _handleUpload() async {
  //   // TODO: replace with real Supabase calls:
  //   // 1. upload the photo file to Storage
  //   // 2. insert a row into `products` with the form field values +
  //   //    artisan_id + status: 'pending'
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Upload not yet connected to database')),
  //   );
  // }

  Future<void> _handleUpload() async {
    if (_photoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a photo first | कृपया पहले फोटो जोड़ें'),
        ),
      );
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      // 1. Upload the photo (enhanced version if available, else original)
      final Uint8List bytesToUpload = (_isEnhanced && _enhancedBytes != null)
          ? _enhancedBytes!
          : await _photoFile!.readAsBytes();

      final fileName =
          '${widget.pehchanId}_${DateTime.now().millisecondsSinceEpoch}.png';

      await supabase.storage
          .from('product-photos')
          .uploadBinary(
            fileName,
            bytesToUpload,
            fileOptions: const FileOptions(contentType: 'image/png'),
          );

      final imageUrl = supabase.storage
          .from('product-photos')
          .getPublicUrl(fileName);

      // 2. Insert the product row
      await supabase.from('Udyam-data').insert({
        'product_name': _nameController.text,
        'size': _sizeController.text,
        'hindi_description': _descriptionHindiController.text,
        'english_description': _descriptionController.text,
        'price': double.tryParse(_priceController.text) ?? 0,
        'color': _colorController.text,
        'material': _materialController.text,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'craft_technique': _craftTechniqueController.text,
        'category': _categoryController.text,
        'image_url': imageUrl,
        'pehchan_id': widget.pehchanId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Product uploaded successfully! | उत्पाद सफलतापूर्वक अपलोड हुआ!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = textFor(widget.languageCode);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: Text('Sell Product | उत्पाद बेचें | ${t.sell}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Photo upload + AI preview ---
            GestureDetector(
              onTap: _pickPhoto,
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(
                      color: _isEnhanced ? Colors.green : Colors.grey.shade300,
                      width: _isEnhanced ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isEnhancing
                      ? const Center(child: CircularProgressIndicator())
                      : (_hasPhoto && _photoFile != null)
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: (_isEnhanced && _enhancedBytes != null)
                                  ? Image.memory(
                                      _enhancedBytes!,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      _photoFile!,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            if (_isEnhanced)
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Enhanced | संवर्धित',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.camera_alt,
                                size: 48,
                                color: Colors.deepOrange,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upload Photo | फोटो अपलोड करें | ${t.uploadPhoto}',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            // GestureDetector(
            //   onTap: _pickPhoto,
            //   child: Container(
            //     height: 220,
            //     decoration: BoxDecoration(
            //       color: Colors.grey.shade100,
            //       border: Border.all(
            //         color: _isEnhanced ? Colors.green : Colors.grey.shade300,
            //         width: _isEnhanced ? 2 : 1,
            //       ),
            //       borderRadius: BorderRadius.circular(12),
            //     ),
            //     child: _isEnhancing
            //         ? const Center(child: CircularProgressIndicator())
            //         : (_hasPhoto && _photoFile != null)
            //         ? Stack(
            //             children: [
            //               ClipRRect(
            //                 borderRadius: BorderRadius.circular(12),
            //                 child: (_isEnhanced && _enhancedBytes != null)
            //                     ? Image.memory(
            //                         _enhancedBytes!,
            //                         width: double.infinity,
            //                         height: 220,
            //                         fit: BoxFit.cover,
            //                       )
            //                     : Image.file(
            //                         _photoFile!,
            //                         width: double.infinity,
            //                         height: 220,
            //                         fit: BoxFit.cover,
            //                       ),
            //               ),
            //               if (_isEnhanced)
            //                 Positioned(
            //                   top: 10,
            //                   left: 10,
            //                   child: Container(
            //                     padding: const EdgeInsets.symmetric(
            //                       horizontal: 10,
            //                       vertical: 5,
            //                     ),
            //                     decoration: BoxDecoration(
            //                       color: Colors.green,
            //                       borderRadius: BorderRadius.circular(20),
            //                     ),
            //                     child: const Row(
            //                       mainAxisSize: MainAxisSize.min,
            //                       children: [
            //                         Icon(
            //                           Icons.auto_awesome,
            //                           size: 14,
            //                           color: Colors.white,
            //                         ),
            //                         SizedBox(width: 4),
            //                         Text(
            //                           'Enhanced | संवर्धित',
            //                           style: TextStyle(
            //                             color: Colors.white,
            //                             fontSize: 11,
            //                             fontWeight: FontWeight.w600,
            //                           ),
            //                         ),
            //                       ],
            //                     ),
            //                   ),
            //                 ),
            //             ],
            //           )
            //         : Center(
            //             child: Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 const Icon(
            //                   Icons.camera_alt,
            //                   size: 48,
            //                   color: Colors.deepOrange,
            //                 ),
            //                 const SizedBox(height: 8),
            //                 Text(
            //                   'Upload Photo | फोटो अपलोड करें | ${t.uploadPhoto}',
            //                   textAlign: TextAlign.center,
            //                 ),
            //               ],
            //             ),
            //           ),
            //   ),
            // ),

            // --- Submit Photo button: only shown once a photo is picked
            // and hasn't been submitted/enhanced yet ---
            if (_hasPhoto && !_isEnhanced) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isEnhancing ? null : _submitPhoto,
                  icon: _isEnhancing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                  label: Text(
                    'Submit Photo | फोटो सबमिट करें | ${t.submitPhoto}',
                    style: const TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // --- Mic + Speaker row ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                _isTranscribing
                    ? const SizedBox(
                        width: 64,
                        height: 64,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      )
                    : IconButton(
                        iconSize: 64,
                        icon: Icon(
                          _isRecording ? Icons.mic : Icons.mic_none,
                          color: _isRecording ? Colors.red : Colors.deepOrange,
                        ),
                        tooltip:
                            'Record Voice | आवाज़ रिकॉर्ड करें | ${t.recordVoice}',
                        onPressed: _toggleRecording,
                      ),
                const Spacer(),
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.volume_up, color: Colors.grey),
                  tooltip: 'Play sample prompt',
                  onPressed: _playSampleVoicePrompt,
                ),
              ],
            ),
            Text(
              'Record Voice | आवाज़ रिकॉर्ड करें | ${t.recordVoice}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // --- Autofill fields (same order as udyam_app.html catalog form) ---
            _LabeledField(
              label: 'Product Name | उत्पाद का नाम | ${t.productName}',
              controller: _nameController,
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Category | श्रेणी | ${t.category}',
              controller: _categoryController,
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Size / capacity | आकार / क्षमता | ${t.size}',
              controller: _sizeController,
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Material | सामग्री | ${t.material}',
              controller: _materialController,
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Color | रंग | ${t.color}',
              controller: _colorController,
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Craft technique | शिल्प तकनीक | ${t.craftTechnique}',
              controller: _craftTechniqueController,
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Description (English) | ${t.description}',
              controller: _descriptionController,
              maxLines: 3,
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Description (Hindi) | विवरण (हिन्दी)',
              controller: _descriptionHindiController,
              maxLines: 3,
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Price | कीमत | ${t.price}',
              controller: _priceController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Current Stock | वर्तमान स्टॉक | ${t.currentStock}',
              controller: _stockController,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 28),

            // --- Upload button + speaker icon ---
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _handleUpload,
                      child: Text(
                        'Upload | अपलोड करें | ${t.upload}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.grey),
                  tooltip: 'Play sample prompt',
                  onPressed: _playSampleVoicePrompt,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
