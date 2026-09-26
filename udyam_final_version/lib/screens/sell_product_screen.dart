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

// --- Seller Details -----------------------------------------------------
// TODO: the user asked for these to be hardcoded dummy values (not pulled
// from the login screen, since login currently only collects Pehchan ID +
// password). Swap these for real artisan-profile data whenever that becomes
// available.
const String kDummySellerName = 'Ramesh Kumar';
const String kDummySellerLocation = 'Varanasi, Uttar Pradesh';
const String kDummySellerCraft = 'Wood Carving';

/// One photo "slot" in the swipeable carousel: the main product photo, or
/// one of the four extra angle shots (back / upper / lower / side).
class _PhotoSlot {
  final String key; // 'main' | 'back' | 'upper' | 'lower' | 'side'
  File? file;
  bool isEnhancing = false;
  bool isEnhanced = false;
  Uint8List? enhancedBytes;
  _PhotoSlot(this.key);
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
  final _dimensionController = TextEditingController();
  final _weightController = TextEditingController();
  final _materialController = TextEditingController();
  final _colorController = TextEditingController();
  final _craftTechniqueController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _descriptionHindiController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _aiDescriptionController = TextEditingController();

  // --- Photo carousel: main photo + back/upper/lower/side views ---
  final PageController _photoPageController = PageController();
  int _currentPhotoPage = 0;
  late final List<_PhotoSlot> _photoSlots = [
    _PhotoSlot('main'),
    _PhotoSlot('back'),
    _PhotoSlot('upper'),
    _PhotoSlot('lower'),
    _PhotoSlot('side'),
  ];

  // --- Voice recording, per field-group ---
  // Group 0: Name, Material, Category
  // Group 1: Size, Dimension, Weight
  // Group 2: Crafting Technique, Description, Description (Hindi), Color
  // Group 3: Stock
  final List<bool> _isRecordingGroup = List.filled(4, false);
  final List<bool> _isTranscribingGroup = List.filled(4, false);
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _samplePlayer = AudioPlayer();

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _sizeController.dispose();
    _dimensionController.dispose();
    _weightController.dispose();
    _materialController.dispose();
    _colorController.dispose();
    _craftTechniqueController.dispose();
    _descriptionController.dispose();
    _descriptionHindiController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _aiDescriptionController.dispose();
    _photoPageController.dispose();
    _audioRecorder.dispose();
    _samplePlayer.dispose();
    super.dispose();
  }

  // --- Photo helpers (used by every slot in the carousel) ---

  Future<void> _pickPhoto(int index) async {
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
      final slot = _photoSlots[index];
      slot.file = File(picked.path);
      slot.isEnhanced = false; // a freshly picked photo isn't submitted yet
      slot.enhancedBytes = null;
    });
  }

  /// Submits whichever photo slot is passed in to the SAME `/image` API the
  /// main photo has always used.
  Future<void> _submitPhoto(int index) async {
    final slot = _photoSlots[index];
    if (slot.file == null || slot.isEnhancing) return;

    setState(() => slot.isEnhancing = true);

    try {
      final uri = Uri.parse('$_apiBaseUrl/image');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', slot.file!.path));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() {
          slot.enhancedBytes = response.bodyBytes; // raw PNG bytes
          slot.isEnhancing = false;
          slot.isEnhanced = true;
        });
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      setState(() => slot.isEnhancing = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Enhancement failed: $e')));
      }
    }
  }

  String _photoSlotTitle(String key, AppText t) {
    switch (key) {
      case 'back':
        return 'Back View | पिछला दृश्य | ${t.backView}';
      case 'upper':
        return 'Upper View | ऊपरी दृश्य | ${t.upperView}';
      case 'lower':
        return 'Lower View | निचला दृश्य | ${t.lowerView}';
      case 'side':
        return 'Side View | साइड दृश्य | ${t.sideView}';
      default:
        return '';
    }
  }

  /// Moves the photo carousel one page forward/back. Used by the on-screen
  /// arrow buttons -- a reliable alternative to swipe/drag, which some
  /// input devices (mouse without drag support, some emulators) don't
  /// trigger consistently.
  void _goToPhotoPage(int delta) {
    final next = (_currentPhotoPage + delta).clamp(0, _photoSlots.length - 1);
    _photoPageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // --- Voice helpers ---

  Future<void> _playSampleVoicePrompt(int group) async {
    try {
      await _samplePlayer.stop();
      await _samplePlayer.play(
        AssetSource('voice_prompts/${widget.languageCode}_$group.mp3'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not play sample: $e')));
      }
    }
  }

  Future<void> _playOverviewVoicePrompt() async {
    try {
      await _samplePlayer.stop();
      await _samplePlayer.play(
        AssetSource('voice_prompts/${widget.languageCode}_overview.mp3'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not play sample: $e')));
      }
    }
  }

  Future<void> _playFinalCheckVoicePrompt() async {
    try {
      await _samplePlayer.stop();
      await _samplePlayer.play(
        AssetSource('voice_prompts/${widget.languageCode}_final.mp3'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not play sample: $e')));
      }
    }
  }

  /// Starts/stops recording for one field-group's mic button. Only one
  /// group can record at a time since there's a single physical mic.
  Future<void> _toggleRecording(int group) async {
    if (!_isRecordingGroup[group]) {
      // --- Start recording ---
      if (_isRecordingGroup.contains(true) ||
          _isTranscribingGroup.contains(true)) {
        // Another group is already busy recording/transcribing.
        return;
      }

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
          '${tempDir.path}/product_voice_g${group}_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() => _isRecordingGroup[group] = true);
    } else {
      // --- Stop recording, then upload for transcription/parsing ---
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecordingGroup[group] = false;
        _isTranscribingGroup[group] = path != null;
      });
      if (path == null) return;

      try {
        // Same /process-voice API used by every group's mic button.
        final endpoint = switch (group) {
          0 => '/process-voice-1',
          1 => '/process-voice-2',
          2 => '/process-voice-3',
          3 => '/process-voice-4',
          _ => throw Exception('Invalid voice group'),
        };

        final uri = Uri.parse('$_apiBaseUrl$endpoint');
        final request = http.MultipartRequest('POST', uri)
          ..files.add(await http.MultipartFile.fromPath('audio_file', path))
          ..fields['native_lang'] = widget.languageCode;
        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 120),
        );
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          print('DEBUG group=$group data=$data');
          _applyVoiceResponse(group, data);
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
        if (mounted) setState(() => _isTranscribingGroup[group] = false);
      }
    }
  }

  /// Routes the /process-voice JSON response to the right controllers for
  /// whichever group's mic was used.
  /// TODO: match these keys to whatever your FastAPI /process-voice
  /// endpoint actually returns -- 'dimension', 'weight' and 'ai_description'
  /// are guesses (the backend doesn't return them yet) and should be
  /// confirmed/renamed with whoever owns that service.
  void _applyVoiceResponse(int group, Map<String, dynamic> data) {
    switch (group) {
      case 0: // Name, Material, Category
        _fillIfPresent(_nameController, data['product_Name']);
        _fillIfPresent(_materialController, data['Material']);
        _fillIfPresent(_categoryController, data['category']);
        break;
      case 1: // Size, Dimension, Weight
        _fillIfPresent(_sizeController, data['size']);
        _fillIfPresent(_dimensionController, data['dimension']);
        _fillIfPresent(_weightController, data['weight']);
        break;
      case 2: // Crafting Technique, Description, Description (Hindi), Color
        _fillIfPresent(_craftTechniqueController, data['crafting_technique']);
        _fillIfPresent(_descriptionController, data['Description']);
        _fillIfPresent(_descriptionHindiController, data['hindi_dec']);
        _fillIfPresent(_colorController, data['color']);
        break;
      case 3: // Stock
        _fillIfPresent(_stockController, data['stock']);
        break;
    }
    // Price and AI Description have no mic button of their own, but any
    // group's response may carry them -- same behaviour as the old single
    // central mic, just spread across the 4 new buttons.
    _fillIfPresent(_priceController, data['suggested_price']);
    _fillIfPresent(_aiDescriptionController, data['ai_description']);
  }

  /// Sets [controller]'s text from [value] if it isn't null/empty.
  /// Handles the field arriving as a String or a number from the API.
  void _fillIfPresent(TextEditingController controller, dynamic value) {
    if (value == null) return;
    final text = value.toString();
    if (text.isNotEmpty) controller.text = text;
  }

  Future<void> _handleUpload() async {
    final mainSlot = _photoSlots[0];
    if (mainSlot.file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a photo first | कृपया पहले फोटो जोड़ें'),
        ),
      );
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      // 1. Upload every photo slot that has an image (enhanced version if
      // available, else original). Slots left empty just get a null URL.
      final Map<String, String?> imageUrls = {};
      for (final slot in _photoSlots) {
        if (slot.file == null) {
          imageUrls[slot.key] = null;
          continue;
        }
        final Uint8List bytesToUpload =
            (slot.isEnhanced && slot.enhancedBytes != null)
            ? slot.enhancedBytes!
            : await slot.file!.readAsBytes();

        final fileName =
            '${widget.pehchanId}_${slot.key}_${DateTime.now().millisecondsSinceEpoch}.png';

        await supabase.storage
            .from('product-photos')
            .uploadBinary(
              fileName,
              bytesToUpload,
              fileOptions: const FileOptions(contentType: 'image/png'),
            );

        imageUrls[slot.key] = supabase.storage
            .from('product-photos')
            .getPublicUrl(fileName);
      }

      // 2. Insert the product row.
      // TODO: 'dimension', 'weight', 'ai_description', 'back_view_url',
      // 'upper_view_url', 'lower_view_url', 'side_view_url', 'seller_name',
      // 'seller_location' and 'seller_craft' are NEW columns -- add them to
      // the 'Udyam-data' table in Supabase before this will succeed.
      await supabase.from('Udyam-data').insert({
        'product_name': _nameController.text,
        'size': _sizeController.text,
        'dimension': _dimensionController.text,
        'weight': _weightController.text,
        'hindi_description': _descriptionHindiController.text,
        'english_description': _descriptionController.text,
        'ai_description': _aiDescriptionController.text,
        'price': double.tryParse(_priceController.text) ?? 0,
        'color': _colorController.text,
        'material': _materialController.text,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'craft_technique': _craftTechniqueController.text,
        'category': _categoryController.text,
        'image_url': imageUrls['main'],
        'back_view_url': imageUrls['back'],
        'upper_view_url': imageUrls['upper'],
        'lower_view_url': imageUrls['lower'],
        'side_view_url': imageUrls['side'],
        'pehchan_id': widget.pehchanId,
        'seller_name': kDummySellerName,
        'seller_location': kDummySellerLocation,
        'seller_craft': kDummySellerCraft,
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
    final currentSlot = _photoSlots[_currentPhotoPage];

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
            // --- Photo carousel: swipe (or use the arrow buttons) for
            // Back / Upper / Lower / Side view windows. Every slot uses the
            // SAME /image API. ---
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _photoPageController,
                    itemCount: _photoSlots.length,
                    onPageChanged: (i) => setState(() => _currentPhotoPage = i),
                    itemBuilder: (context, index) {
                      final slot = _photoSlots[index];
                      final title = _photoSlotTitle(slot.key, t);
                      return GestureDetector(
                        onTap: () => _pickPhoto(index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            border: Border.all(
                              color: slot.isEnhanced
                                  ? Colors.green
                                  : Colors.grey.shade300,
                              width: slot.isEnhanced ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: slot.isEnhancing
                              ? const Center(child: CircularProgressIndicator())
                              : (slot.file != null)
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child:
                                          (slot.isEnhanced &&
                                              slot.enhancedBytes != null)
                                          ? Image.memory(
                                              slot.enhancedBytes!,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.file(
                                              slot.file!,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    if (title.isNotEmpty)
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (slot.isEnhanced)
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
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
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
                                        title.isEmpty
                                            ? 'Upload Photo | फोटो अपलोड करें | ${t.uploadPhoto}'
                                            : '$title\n${t.uploadPhoto}',
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                  // Left / right arrow buttons -- a reliable way to move
                  // between photo slots on any input device (mouse without
                  // drag, some emulators, etc.), alongside normal swiping.
                  if (_currentPhotoPage > 0)
                    Positioned(
                      left: 4,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _PhotoNavArrow(
                          icon: Icons.chevron_left,
                          onTap: () => _goToPhotoPage(-1),
                        ),
                      ),
                    ),
                  if (_currentPhotoPage < _photoSlots.length - 1)
                    Positioned(
                      right: 4,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _PhotoNavArrow(
                          icon: Icons.chevron_right,
                          onTap: () => _goToPhotoPage(1),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Page indicator dots for the 5-slot carousel.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_photoSlots.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPhotoPage == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPhotoPage == i
                        ? Colors.deepOrange
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              'Swipe for Back / Upper / Lower / Side views | पिछला/ऊपरी/निचला/साइड दृश्य के लिए स्वाइप करें',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),

            // --- Submit Photo button: applies to whichever slot is
            // currently showing in the carousel. ---
            if (currentSlot.file != null && !currentSlot.isEnhanced) ...[
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
                  onPressed: currentSlot.isEnhancing
                      ? null
                      : () => _submitPhoto(_currentPhotoPage),
                  icon: currentSlot.isEnhancing
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

            // --- Central speaker only (mic removed from here; each field
            // group below now has its own mic + speaker instead). ---
            Center(
              child: IconButton(
                iconSize: 48,
                icon: const Icon(Icons.volume_up, color: Colors.deepOrange),
                tooltip: 'Play instructions | निर्देश सुनें',
                onPressed: _playOverviewVoicePrompt,
              ),
            ),
            Text(
              'Play Instructions | निर्देश सुनें | ${t.recordVoice}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // --- Group 1: Name, Material, Category ---
            _VoiceGroupHeader(
              label:
                  'Name, Material & Category | नाम, सामग्री और श्रेणी | ${t.productName} / ${t.material} / ${t.category}',
              isRecording: _isRecordingGroup[0],
              isTranscribing: _isTranscribingGroup[0],
              onMicTap: () => _toggleRecording(0),
              onSpeakerTap: () => _playSampleVoicePrompt(0),
            ),
            const SizedBox(height: 10),
            _LabeledField(
              label: 'Product Name | उत्पाद का नाम | ${t.productName}',
              controller: _nameController,
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Material | सामग्री | ${t.material}',
              controller: _materialController,
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Category | श्रेणी | ${t.category}',
              controller: _categoryController,
            ),

            const SizedBox(height: 24),

            // --- Group 2: Size, Dimension, Weight ---
            _VoiceGroupHeader(
              label:
                  'Size, Dimension & Weight | आकार, आयाम और वज़न | ${t.size} / ${t.dimension} / ${t.weight}',
              isRecording: _isRecordingGroup[1],
              isTranscribing: _isTranscribingGroup[1],
              onMicTap: () => _toggleRecording(1),
              onSpeakerTap: () => _playSampleVoicePrompt(1),
            ),
            const SizedBox(height: 10),
            _LabeledField(
              label: 'Size / capacity | आकार / क्षमता | ${t.size}',
              controller: _sizeController,
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Dimension | आयाम | ${t.dimension}',
              controller: _dimensionController,
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Weight | वज़न | ${t.weight}',
              controller: _weightController,
            ),

            const SizedBox(height: 24),

            // --- Group 3: Crafting Technique, Description, Description
            // (Hindi), Color ---
            _VoiceGroupHeader(
              label:
                  'Crafting Technique, Description & Color | शिल्प तकनीक, विवरण और रंग | ${t.craftTechnique} / ${t.description} / ${t.color}',
              isRecording: _isRecordingGroup[2],
              isTranscribing: _isTranscribingGroup[2],
              onMicTap: () => _toggleRecording(2),
              onSpeakerTap: () => _playSampleVoicePrompt(2),
            ),
            const SizedBox(height: 10),
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
              label: 'Color | रंग | ${t.color}',
              controller: _colorController,
            ),

            const SizedBox(height: 24),

            // --- Group 4: Stock ---
            _VoiceGroupHeader(
              label: 'Current Stock | वर्तमान स्टॉक | ${t.currentStock}',
              isRecording: _isRecordingGroup[3],
              isTranscribing: _isTranscribingGroup[3],
              onMicTap: () => _toggleRecording(3),
              onSpeakerTap: () => _playSampleVoicePrompt(3),
            ),
            const SizedBox(height: 10),
            _LabeledField(
              label: 'Current Stock | वर्तमान स्टॉक | ${t.currentStock}',
              controller: _stockController,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 24),

            // --- Price (unchanged, no mic/speaker) ---
            _LabeledField(
              label: 'Price | कीमत | ${t.price}',
              controller: _priceController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),

            // --- New: AI Description (no mic/speaker, linked to the same
            // /process-voice backend response via the 'ai_description' key
            // -- see TODO above _applyVoiceResponse). ---
            _LabeledField(
              label: 'About | परिचय | ${t.aiDescription}',
              controller: _aiDescriptionController,
              maxLines: 4,
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
                  onPressed: _playFinalCheckVoicePrompt,
                ),
              ],
            ),

            // --- Seller Details: fixed dummy block, not editable ---
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seller Details | विक्रेता विवरण | ${t.sellerDetails}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SellerDetailRow(
                    label: 'Name | नाम',
                    value: kDummySellerName,
                  ),
                  const SizedBox(height: 6),
                  _SellerDetailRow(
                    label: 'Location | स्थान | ${t.location}',
                    value: kDummySellerLocation,
                  ),
                  const SizedBox(height: 6),
                  _SellerDetailRow(
                    label: 'Craft | शिल्प | ${t.craft}',
                    value: kDummySellerCraft,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoNavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _PhotoNavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

class _VoiceGroupHeader extends StatelessWidget {
  final String label;
  final bool isRecording;
  final bool isTranscribing;
  final VoidCallback onMicTap;
  final VoidCallback onSpeakerTap;

  const _VoiceGroupHeader({
    required this.label,
    required this.isRecording,
    required this.isTranscribing,
    required this.onMicTap,
    required this.onSpeakerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.deepOrange,
            ),
          ),
        ),
        isTranscribing
            ? const SizedBox(
                width: 36,
                height: 36,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                iconSize: 28,
                icon: Icon(
                  isRecording ? Icons.mic : Icons.mic_none,
                  color: isRecording ? Colors.red : Colors.deepOrange,
                ),
                tooltip: 'Record Voice | आवाज़ रिकॉर्ड करें',
                onPressed: onMicTap,
              ),
        IconButton(
          iconSize: 24,
          icon: const Icon(Icons.volume_up, color: Colors.grey),
          tooltip: 'Play sample prompt',
          onPressed: onSpeakerTap,
        ),
      ],
    );
  }
}

class _SellerDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _SellerDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
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
