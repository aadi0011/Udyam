/// Holds the native-language text for every UI label we need.
/// NOTE: These are best-effort translations. Please have a native speaker
/// of each language review before shipping to real users -- machine/AI
/// translation can miss regional phrasing or sound unnatural.
class AppText {
  final String sell;
  final String stock;
  final String track;
  final String accountCenter;
  final String logout;
  final String uploadPhoto;
  final String submitPhoto;
  final String recordVoice;
  final String currentStock;
  final String upload;
  final String productName;
  final String description;
  final String price;
  final String category;
  final String size;
  final String material;
  final String color;
  final String craftTechnique;
  final String dimension;
  final String weight;
  final String backView;
  final String upperView;
  final String lowerView;
  final String sideView;
  final String sellerDetails;
  final String location;
  final String craft;
  final String aiDescription;

  const AppText({
    required this.sell,
    required this.stock,
    required this.track,
    required this.accountCenter,
    required this.logout,
    required this.uploadPhoto,
    required this.submitPhoto,
    required this.recordVoice,
    required this.currentStock,
    required this.upload,
    required this.productName,
    required this.description,
    required this.price,
    required this.category,
    required this.size,
    required this.material,
    required this.color,
    required this.craftTechnique,
    required this.dimension,
    required this.weight,
    required this.backView,
    required this.upperView,
    required this.lowerView,
    required this.sideView,
    required this.sellerDetails,
    required this.location,
    required this.craft,
    required this.aiDescription,
  });
}

final Map<String, AppText> kTranslations = {
  'hi': const AppText(
    sell: 'उत्पाद बेचें', stock: 'स्टॉक और कैटलॉग', track: 'भुगतान और ऑर्डर',
    accountCenter: 'खाता केंद्र', logout: 'लॉग आउट', uploadPhoto: 'फोटो अपलोड करें',
    recordVoice: 'आवाज़ रिकॉर्ड करें', currentStock: 'वर्तमान स्टॉक',
    upload: 'अपलोड करें', productName: 'उत्पाद का नाम', description: 'विवरण',
    price: 'कीमत', category: 'श्रेणी',
    size: 'आकार', material: 'सामग्री', color: 'रंग', craftTechnique: 'शिल्प तकनीक', submitPhoto: 'फोटो सबमिट करें',
    dimension: 'आयाम', weight: 'वज़न', backView: 'पिछला दृश्य', upperView: 'ऊपरी दृश्य',
    lowerView: 'निचला दृश्य', sideView: 'साइड दृश्य', sellerDetails: 'विक्रेता विवरण',
    location: 'स्थान', craft: 'शिल्प', aiDescription: 'एआई विवरण',
  ),
  'bn': const AppText(
    sell: 'পণ্য বিক্রি করুন', stock: 'স্টক ও ক্যাটালগ', track: 'পেমেন্ট ও অর্ডার',
    accountCenter: 'অ্যাকাউন্ট কেন্দ্র', logout: 'লগ আউট', uploadPhoto: 'ছবি আপলোড করুন',
    recordVoice: 'ভয়েস রেকর্ড করুন', currentStock: 'বর্তমান স্টক',
    upload: 'আপলোড করুন', productName: 'পণ্যের নাম', description: 'বিবরণ',
    price: 'দাম', category: 'বিভাগ',
    size: 'আকার', material: 'উপাদান', color: 'রং', craftTechnique: 'কারুকৌশল', submitPhoto: 'ছবি জমা দিন',
    dimension: 'মাত্রা', weight: 'ওজন', backView: 'পেছনের দৃশ্য', upperView: 'উপরের দৃশ্য',
    lowerView: 'নিচের দৃশ্য', sideView: 'পাশের দৃশ্য', sellerDetails: 'বিক্রেতার বিবরণ',
    location: 'অবস্থান', craft: 'কারুশিল্প', aiDescription: 'এআই বিবরণ',
  ),
  'mr': const AppText(
    sell: 'उत्पादन विका', stock: 'साठा आणि कॅटलॉग', track: 'पेमेंट आणि ऑर्डर',
    accountCenter: 'खाते केंद्र', logout: 'लॉग आउट', uploadPhoto: 'फोटो अपलोड करा',
    recordVoice: 'आवाज रेकॉर्ड करा', currentStock: 'सध्याचा साठा',
    upload: 'अपलोड करा', productName: 'उत्पादनाचे नाव', description: 'वर्णन',
    price: 'किंमत', category: 'श्रेणी',
    size: 'आकार', material: 'साहित्य', color: 'रंग', craftTechnique: 'कारागिरी तंत्र', submitPhoto: 'फोटो सबमिट करा',
    dimension: 'परिमाण', weight: 'वजन', backView: 'मागील दृश्य', upperView: 'वरचे दृश्य',
    lowerView: 'खालचे दृश्य', sideView: 'बाजूचे दृश्य', sellerDetails: 'विक्रेता तपशील',
    location: 'स्थान', craft: 'हस्तकला', aiDescription: 'एआय वर्णन',
  ),
  'te': const AppText(
    sell: 'ఉత్పత్తిని అమ్మండి', stock: 'స్టాక్ & కేటలాగ్', track: 'చెల్లింపులు & ఆర్డర్లు',
    accountCenter: 'ఖాతా కేంద్రం', logout: 'లాగ్ అవుట్', uploadPhoto: 'ఫోటో అప్‌లోడ్ చేయండి',
    recordVoice: 'వాయిస్ రికార్డ్ చేయండి', currentStock: 'ప్రస్తుత స్టాక్',
    upload: 'అప్‌లోడ్ చేయండి', productName: 'ఉత్పత్తి పేరు', description: 'వివరణ',
    price: 'ధర', category: 'వర్గం',
    size: 'పరిమాణం', material: 'పదార్థం', color: 'రంగు', craftTechnique: 'హస్తకళ సాంకేతికత', submitPhoto: 'ఫోటో సమర్పించండి',
    dimension: 'కొలతలు', weight: 'బరువు', backView: 'వెనుక వీక్షణ', upperView: 'పై వీక్షణ',
    lowerView: 'దిగువ వీక్షణ', sideView: 'పక్క వీక్షణ', sellerDetails: 'విక్రేత వివరాలు',
    location: 'ప్రాంతం', craft: 'హస్తకళ', aiDescription: 'AI వివరణ',
  ),
  'ta': const AppText(
    sell: 'பொருளை விற்கவும்', stock: 'ஸ்டாக் & பட்டியல்', track: 'பணம் & ஆர்டர்கள்',
    accountCenter: 'கணக்கு மையம்', logout: 'வெளியேறு', uploadPhoto: 'புகைப்படம் பதிவேற்றவும்',
    recordVoice: 'குரலைப் பதிவு செய்யவும்', currentStock: 'தற்போதைய இருப்பு',
    upload: 'பதிவேற்று', productName: 'பொருளின் பெயர்', description: 'விளக்கம்',
    price: 'விலை', category: 'வகை',
    size: 'அளவு', material: 'பொருள்', color: 'நிறம்', craftTechnique: 'கைவினை நுட்பம்', submitPhoto: 'புகைப்படத்தை சமர்ப்பிக்கவும்',
    dimension: 'பரிமாணம்', weight: 'எடை', backView: 'பின் காட்சி', upperView: 'மேல் காட்சி',
    lowerView: 'கீழ் காட்சி', sideView: 'பக்க காட்சி', sellerDetails: 'விற்பனையாளர் விவரங்கள்',
    location: 'இடம்', craft: 'கைவினை', aiDescription: 'AI விளக்கம்',
  ),
  'gu': const AppText(
    sell: 'ઉત્પાદન વેચો', stock: 'સ્ટોક અને કેટલોગ', track: 'ચુકવણી અને ઓર્ડર',
    accountCenter: 'ખાતું કેન્દ્ર', logout: 'લૉગ આઉટ', uploadPhoto: 'ફોટો અપલોડ કરો',
    recordVoice: 'અવાજ રેકોર્ડ કરો', currentStock: 'હાલનો સ્ટોક',
    upload: 'અપલોડ કરો', productName: 'ઉત્પાદનનું નામ', description: 'વર્ણન',
    price: 'કિંમત', category: 'શ્રેણી',
    size: 'કદ', material: 'સામગ્રી', color: 'રંગ', craftTechnique: 'કારીગરી તકનીક', submitPhoto: 'ફોટો સબમિટ કરો',
    dimension: 'પરિમાણ', weight: 'વજન', backView: 'પાછળનું દ્રશ્ય', upperView: 'ઉપરનું દ્રશ્ય',
    lowerView: 'નીચેનું દ્રશ્ય', sideView: 'બાજુનું દ્રશ્ય', sellerDetails: 'વિક્રેતાની વિગતો',
    location: 'સ્થાન', craft: 'હસ્તકલા', aiDescription: 'AI વર્ણન',
  ),
  'ur': const AppText(
    sell: 'پروڈکٹ بیچیں', stock: 'اسٹاک اور کیٹلاگ', track: 'ادائیگی اور آرڈرز',
    accountCenter: 'اکاؤنٹ سینٹر', logout: 'لاگ آؤٹ', uploadPhoto: 'تصویر اپ لوڈ کریں',
    recordVoice: 'آواز ریکارڈ کریں', currentStock: 'موجودہ اسٹاک',
    upload: 'اپ لوڈ کریں', productName: 'پروڈکٹ کا نام', description: 'تفصیل',
    price: 'قیمت', category: 'قسم',
    size: 'سائز', material: 'میٹریل', color: 'رنگ', craftTechnique: 'دستکاری کی تکنیک', submitPhoto: 'تصویر جمع کروائیں',
    dimension: 'طول و عرض', weight: 'وزن', backView: 'پچھلا منظر', upperView: 'اوپری منظر',
    lowerView: 'نچلا منظر', sideView: 'سائیڈ منظر', sellerDetails: 'بیچنے والے کی تفصیلات',
    location: 'مقام', craft: 'دستکاری', aiDescription: 'اے آئی تفصیل',
  ),
  'kn': const AppText(
    sell: 'ಉತ್ಪನ್ನ ಮಾರಾಟ ಮಾಡಿ', stock: 'ಸ್ಟಾಕ್ ಮತ್ತು ಕ್ಯಾಟಲಾಗ್', track: 'ಪಾವತಿ ಮತ್ತು ಆರ್ಡರ್‌ಗಳು',
    accountCenter: 'ಖಾತೆ ಕೇಂದ್ರ', logout: 'ಲಾಗ್ ಔಟ್', uploadPhoto: 'ಫೋಟೋ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ',
    recordVoice: 'ಧ್ವನಿ ರೆಕಾರ್ಡ್ ಮಾಡಿ', currentStock: 'ಪ್ರಸ್ತುತ ಸ್ಟಾಕ್',
    upload: 'ಅಪ್‌ಲೋಡ್ ಮಾಡಿ', productName: 'ಉತ್ಪನ್ನದ ಹೆಸರು', description: 'ವಿವರಣೆ',
    price: 'ಬೆಲೆ', category: 'ವರ್ಗ',
    size: 'ಗಾತ್ರ', material: 'ವಸ್ತು', color: 'ಬಣ್ಣ', craftTechnique: 'ಕರಕುಶಲ ತಂತ್ರ', submitPhoto: 'ಫೋಟೋ ಸಲ್ಲಿಸಿ',
    dimension: 'ಆಯಾಮ', weight: 'ತೂಕ', backView: 'ಹಿಂಬದಿ ನೋಟ', upperView: 'ಮೇಲ್ಭಾಗದ ನೋಟ',
    lowerView: 'ಕೆಳಭಾಗದ ನೋಟ', sideView: 'ಬದಿಯ ನೋಟ', sellerDetails: 'ಮಾರಾಟಗಾರರ ವಿವರಗಳು',
    location: 'ಸ್ಥಳ', craft: 'ಕರಕುಶಲ', aiDescription: 'AI ವಿವರಣೆ',
  ),
  'or': const AppText(
    sell: 'ଉତ୍ପାଦ ବିକ୍ରୟ କରନ୍ତୁ', stock: 'ଷ୍ଟକ୍ ଏବଂ କାଟାଲଗ୍', track: 'ଦେୟ ଏବଂ ଅର୍ଡର',
    accountCenter: 'ଖାତା କେନ୍ଦ୍ର', logout: 'ଲଗ୍ ଆଉଟ୍', uploadPhoto: 'ଫଟୋ ଅପଲୋଡ୍ କରନ୍ତୁ',
    recordVoice: 'ସ୍ୱର ରେକର୍ଡ କରନ୍ତୁ', currentStock: 'ବର୍ତ୍ତମାନ ଷ୍ଟକ୍',
    upload: 'ଅପଲୋଡ୍ କରନ୍ତୁ', productName: 'ଉତ୍ପାଦର ନାମ', description: 'ବର୍ଣ୍ଣନା',
    price: 'ମୂଲ୍ୟ', category: 'ବର୍ଗ',
    size: 'ଆକାର', material: 'ସାମଗ୍ରୀ', color: 'ରଙ୍ଗ', craftTechnique: 'କାରିଗରି କୌଶଳ', submitPhoto: 'ଫଟୋ ଦାଖଲ କରନ୍ତୁ',
    dimension: 'ପରିମାଣ', weight: 'ଓଜନ', backView: 'ପଛ ଦୃଶ୍ୟ', upperView: 'ଉପର ଦୃଶ୍ୟ',
    lowerView: 'ତଳ ଦୃଶ୍ୟ', sideView: 'ପାର୍ଶ୍ୱ ଦୃଶ୍ୟ', sellerDetails: 'ବିକ୍ରେତା ବିବରଣୀ',
    location: 'ସ୍ଥାନ', craft: 'କାରିଗରି', aiDescription: 'AI ବର୍ଣ୍ଣନା',
  ),
  'ml': const AppText(
    sell: 'ഉൽപ്പന്നം വിൽക്കുക', stock: 'സ്റ്റോക്കും കാറ്റലോഗും', track: 'പേയ്‌മെന്റും ഓർഡറും',
    accountCenter: 'അക്കൗണ്ട് സെന്റർ', logout: 'ലോഗ് ഔട്ട്', uploadPhoto: 'ഫോട്ടോ അപ്‌ലോഡ് ചെയ്യുക',
    recordVoice: 'ശബ്ദം റെക്കോർഡ് ചെയ്യുക', currentStock: 'നിലവിലെ സ്റ്റോക്ക്',
    upload: 'അപ്‌ലോഡ് ചെയ്യുക', productName: 'ഉൽപ്പന്നത്തിന്റെ പേര്', description: 'വിവരണം',
    price: 'വില', category: 'വിഭാഗം',
    size: 'വലിപ്പം', material: 'വസ്തു', color: 'നിറം', craftTechnique: 'കരകൗശല സാങ്കേതികം', submitPhoto: 'ഫോട്ടോ സമർപ്പിക്കുക',
    dimension: 'അളവുകൾ', weight: 'ഭാരം', backView: 'പിന്നിലെ കാഴ്ച', upperView: 'മുകളിലെ കാഴ്ച',
    lowerView: 'താഴെയുള്ള കാഴ്ച', sideView: 'വശക്കാഴ്ച', sellerDetails: 'വിൽപ്പനക്കാരന്റെ വിവരങ്ങൾ',
    location: 'സ്ഥലം', craft: 'കരകൗശലം', aiDescription: 'AI വിവരണം',
  ),
  'pa': const AppText(
    sell: 'ਉਤਪਾਦ ਵੇਚੋ', stock: 'ਸਟਾਕ ਅਤੇ ਕੈਟਾਲਾਗ', track: 'ਭੁਗਤਾਨ ਅਤੇ ਆਰਡਰ',
    accountCenter: 'ਖਾਤਾ ਕੇਂਦਰ', logout: 'ਲੌਗ ਆਉਟ', uploadPhoto: 'ਫੋਟੋ ਅੱਪਲੋਡ ਕਰੋ',
    recordVoice: 'ਆਵਾਜ਼ ਰਿਕਾਰਡ ਕਰੋ', currentStock: 'ਮੌਜੂਦਾ ਸਟਾਕ',
    upload: 'ਅੱਪਲੋਡ ਕਰੋ', productName: 'ਉਤਪਾਦ ਦਾ ਨਾਮ', description: 'ਵੇਰਵਾ',
    price: 'ਕੀਮਤ', category: 'ਸ਼੍ਰੇਣੀ',
    size: 'ਆਕਾਰ', material: 'ਸਮੱਗਰੀ', color: 'ਰੰਗ', craftTechnique: 'ਦਸਤਕਾਰੀ ਤਕਨੀਕ', submitPhoto: 'ਫੋਟੋ ਜਮ੍ਹਾਂ ਕਰੋ',
    dimension: 'ਮਾਪ', weight: 'ਭਾਰ', backView: 'ਪਿਛਲਾ ਦ੍ਰਿਸ਼', upperView: 'ਉੱਪਰਲਾ ਦ੍ਰਿਸ਼',
    lowerView: 'ਹੇਠਲਾ ਦ੍ਰਿਸ਼', sideView: 'ਪਾਸੇ ਦਾ ਦ੍ਰਿਸ਼', sellerDetails: 'ਵਿਕਰੇਤਾ ਵੇਰਵੇ',
    location: 'ਟਿਕਾਣਾ', craft: 'ਦਸਤਕਾਰੀ', aiDescription: 'AI ਵੇਰਵਾ',
  ),
  'as': const AppText(
    sell: 'সামগ্ৰী বিক্ৰী কৰক', stock: 'ষ্টক আৰু কেটেলগ', track: 'পৰিশোধ আৰু অৰ্ডাৰ',
    accountCenter: 'একাউণ্ট কেন্দ্ৰ', logout: 'লগ আউট', uploadPhoto: 'ফটো আপল\u200cড কৰক',
    recordVoice: 'কণ্ঠস্বৰ ৰেকৰ্ড কৰক', currentStock: 'বৰ্তমানৰ ষ্টক',
    upload: 'আপল\u200cড কৰক', productName: 'সামগ্ৰীৰ নাম', description: 'বিৱৰণ',
    price: 'দাম', category: 'শ্ৰেণী',
    size: 'আকাৰ', material: 'সামগ্ৰী', color: 'ৰং', craftTechnique: 'শিল্পকলা কৌশল', submitPhoto: 'ফটো দাখিল কৰক',
    dimension: 'পৰিমাপ', weight: 'ওজন', backView: 'পিছফালৰ দৃশ্য', upperView: 'ওপৰৰ দৃশ্য',
    lowerView: 'তলৰ দৃশ্য', sideView: 'কাষৰ দৃশ্য', sellerDetails: 'বিক্ৰেতাৰ বিৱৰণ',
    location: 'স্থান', craft: 'শিল্পকলা', aiDescription: 'AI বিৱৰণ',
  ),
};

/// Safe getter -- falls back to Hindi if a language code is somehow missing.
AppText textFor(String languageCode) =>
    kTranslations[languageCode] ?? kTranslations['hi']!;
