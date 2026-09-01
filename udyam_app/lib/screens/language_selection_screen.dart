import 'package:flutter/material.dart';

import 'home_screen.dart';

/// Simple data holder for one language option.
class AppLanguage {
  final String code; // short code we'll store/send to backend, e.g. 'hi'
  final String nativeName; // shown in the language's own script
  final String englishName; // shown in English, smaller

  const AppLanguage({
    required this.code,
    required this.nativeName,
    required this.englishName,
  });
}

// The 12 languages. Adjust this list any time -- everything below
// reads from it automatically, nothing else needs to change.
const List<AppLanguage> kSupportedLanguages = [
  AppLanguage(code: 'hi', nativeName: 'हिंदी', englishName: 'Hindi'),
  AppLanguage(code: 'bn', nativeName: 'বাংলা', englishName: 'Bengali'),
  AppLanguage(code: 'mr', nativeName: 'मराठी', englishName: 'Marathi'),
  AppLanguage(code: 'te', nativeName: 'తెలుగు', englishName: 'Telugu'),
  AppLanguage(code: 'ta', nativeName: 'தமிழ்', englishName: 'Tamil'),
  AppLanguage(code: 'gu', nativeName: 'ગુજરાતી', englishName: 'Gujarati'),
  AppLanguage(code: 'ur', nativeName: 'اردو', englishName: 'Urdu'),
  AppLanguage(code: 'kn', nativeName: 'ಕನ್ನಡ', englishName: 'Kannada'),
  AppLanguage(code: 'or', nativeName: 'ଓଡ଼ିଆ', englishName: 'Odia'),
  AppLanguage(code: 'ml', nativeName: 'മലയാളം', englishName: 'Malayalam'),
  AppLanguage(code: 'pa', nativeName: 'ਪੰਜਾਬੀ', englishName: 'Punjabi'),
  AppLanguage(code: 'as', nativeName: 'অসমীয়া', englishName: 'Assamese'),
];

class LanguageSelectionScreen extends StatefulWidget {
  final String pehchanId;
  const LanguageSelectionScreen({super.key, required this.pehchanId});
  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? _selectedCode;

  void _onLanguageTap(AppLanguage lang) {
    setState(() => _selectedCode = lang.code);

    // TODO: persist this choice (e.g. shared_preferences) and/or save it
    // against the artisan's row in Supabase, then navigate to the home
    // screen (the 3-button screen) passing the selected language code.
    //
    // Example once wired up:
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (_) => HomeScreen(languageCode: lang.code)),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Your Language',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'अपनी भाषा चुनें',
                style: TextStyle(fontSize: 18, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  itemCount: kSupportedLanguages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.5,
                  ),
                  itemBuilder: (context, index) {
                    final lang = kSupportedLanguages[index];
                    final isSelected = _selectedCode == lang.code;

                    return _LanguageCard(
                      language: lang,
                      isSelected: isSelected,
                      onTap: () => _onLanguageTap(lang),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _selectedCode == null
                      ? null // disabled until a language is picked
                      : () {
                          // TODO: also persist _selectedCode with
                          // shared_preferences so it's remembered next time
                          // and login can skip straight to HomeScreen.
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HomeScreen(
                                languageCode: _selectedCode!,
                                pehchanId: widget.pehchanId,
                              ),
                            ),
                          );
                        },
                  child: const Text(
                    'Continue | जारी रखें',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final AppLanguage language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange.shade50 : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              language.nativeName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              language.englishName,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
