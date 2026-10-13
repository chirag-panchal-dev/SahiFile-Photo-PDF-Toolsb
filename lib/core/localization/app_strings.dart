enum AppLanguage {
  english,
  hindi;

  String get displayName => switch (this) {
    AppLanguage.english => 'English',
    AppLanguage.hindi => 'हिंदी (Hindi)',
  };
}

class AppStrings {
  final AppLanguage language;
  const AppStrings(this.language);

  bool get isHindi => language == AppLanguage.hindi;

  // App General
  String get appName => 'SahiFile';
  String get appTagline =>
      isHindi ? 'फोटो और पीडीएफ टूल्स' : 'Photo & PDF Tools';
  String get appSlogan =>
      isHindi
          ? 'हर फाइल को अपलोड के लिए तैयार करें।'
          : 'Make every file upload-ready.';

  // Navigation
  String get navHome => isHindi ? 'होम' : 'Home';
  String get navTools => isHindi ? 'टूल्स' : 'Tools';
  String get navMyFiles => isHindi ? 'मेरी फाइलें' : 'My Files';
  String get navSettings => isHindi ? 'सेटिंग्स' : 'Settings';

  // Home Screen
  String get heroTitle =>
      isHindi ? 'फाइलें तैयार करें' : 'Make files upload-ready';
  String get heroSubtitle =>
      isHindi
          ? 'फोटो रीसाइज करें, सटीक KB में कंप्रेस करें, हस्ताक्षर सेट करें, और पीडीएफ बनाएं।'
          : 'Resize photos, compress to exact KB, format signatures, and convert to PDF.';
  String get heroCta => isHindi ? 'फोटो तैयार करें' : 'Prepare a photo';
  String get quickActions => isHindi ? 'त्वरित टूल्स' : 'Quick Actions';
  String get recentFiles => isHindi ? 'हाल की फाइलें' : 'Recent Files';
  String get seeAll => isHindi ? 'सभी देखें' : 'See all';
  String get noRecentFiles =>
      isHindi ? 'कोई हालिया फाइल नहीं है' : 'No recent files yet';
  String get noRecentFilesDesc =>
      isHindi
          ? 'नीचे दिए गए टूल्स से एक फोटो या पीडीएफ बनाएं।'
          : 'Create a photo or PDF using any tool below to see it here.';

  // Tools
  String get toolPhotoSignature =>
      isHindi ? 'फोटो और हस्ताक्षर' : 'Photo & Signature';
  String get toolPhotoSignatureDesc =>
      isHindi
          ? 'सटीक पिक्सेल, आकार और केबी सीमा में क्रॉप व रीसाइज करें'
          : 'Crop, resize & compress to exact pixel dimensions and KB limit';

  String get toolCompressImage =>
      isHindi ? 'इमेज कंप्रेस करें' : 'Compress Image';
  String get toolCompressImageDesc =>
      isHindi
          ? 'गुणवत्ता खोए बिना फाइल का आकार (KB/MB) घटाएं'
          : 'Reduce file size (KB/MB) while preserving maximum visual clarity';

  String get toolImagesToPdf => isHindi ? 'फोटो से पीडीएफ' : 'Images to PDF';
  String get toolImagesToPdfDesc =>
      isHindi
          ? 'कई तस्वीरों को क्रमबद्ध करके A4 या लेटर पीडीएफ बनाएं'
          : 'Combine multiple photos into a clean A4 or Letter PDF document';

  String get toolMergePdf => isHindi ? 'पीडीएफ मर्ज करें' : 'Merge PDFs';
  String get toolMergePdfDesc =>
      isHindi
          ? 'दो या अधिक पीडीएफ फाइलों को एक में सुरक्षित जोड़ें'
          : 'Combine multiple PDF files into one clean document on-device';

  String get toolPdfCompress =>
      isHindi ? 'पीडीएफ साइज घटाएं' : 'Optimize PDF Size';
  String get toolPdfCompressDesc =>
      isHindi
          ? 'दस्तावेज़ का आकार सुरक्षित रूप से ऑन-डिवाइस कम करें'
          : 'Safely reduce document size locally without uploading to servers';

  String get toolOrganizePdf =>
      isHindi ? 'पीडीएफ पेज क्रम बदलें' : 'Organize PDF Pages';
  String get toolOrganizePdfDesc =>
      isHindi
          ? 'पेज का क्रम बदलें, घुमाएं, हटाएं या डुप्लिकेट करें (iLovePDF की तरह)'
          : 'Reorder page sequence, rotate, delete, or duplicate pages';

  String get toolPresets => isHindi ? 'फॉर्म प्रीसेट्स' : 'Form Presets';
  String get toolPresetsDesc =>
      isHindi
          ? 'पासपोर्ट, पैन कार्ड, एसएससी, यूपीएससी फॉर्म आकार'
          : 'Ready-to-use sizes for passport, exams, and job portals';

  // Common Actions
  String get pickImage => isHindi ? 'फोटो चुनें' : 'Select Photo';
  String get pickAnotherImage => isHindi ? 'दूसरी फोटो चुनें' : 'Change Photo';
  String get pickPdfs => isHindi ? 'पीडीएफ चुनें' : 'Select PDFs';
  String get addMoreImages => isHindi ? 'और फोटो जोड़ें' : 'Add More Photos';
  String get continueBtn => isHindi ? 'आगे बढ़ें' : 'Continue';
  String get applyCrop => isHindi ? 'क्रॉप लागू करें' : 'Apply Crop';
  String get resetCrop => isHindi ? 'रीसेट' : 'Reset';
  String get rotate => isHindi ? 'घुमाएं' : 'Rotate';
  String get preparePhoto => isHindi ? 'फोटो तैयार करें' : 'Prepare Photo';
  String get createPdf => isHindi ? 'पीडीएफ बनाएं' : 'Create PDF';
  String get mergePdfs => isHindi ? 'मर्ज करें' : 'Merge PDFs';
  String get optimizePdf => isHindi ? 'ऑप्टिमाइज़ करें' : 'Optimize PDF';
  String get saveToDevice => isHindi ? 'डिवाइस में सहेजें' : 'Save to Device';
  String get share => isHindi ? 'शेयर करें' : 'Share';
  String get done => isHindi ? 'पूर्ण' : 'Done';
  String get cancel => isHindi ? 'रद्द करें' : 'Cancel';
  String get delete => isHindi ? 'हटाएं' : 'Delete';
  String get editAgain => isHindi ? 'फिर से एडिट करें' : 'Edit Again';
  String get retry => isHindi ? 'पुनः प्रयास करें' : 'Retry';
  String get search => isHindi ? 'खोजें...' : 'Search...';
  String get filterAll => isHindi ? 'सभी' : 'All';
  String get filterImages => isHindi ? 'इमेज' : 'Images';
  String get filterPdfs => isHindi ? 'पीडीएफ' : 'PDFs';

  // Photo Setup Form
  String get presetTab => isHindi ? 'प्रीसेट' : 'Preset';
  String get customTab => isHindi ? 'कस्टम साइज़' : 'Custom Size';
  String get widthPx => isHindi ? 'चौड़ाई (px)' : 'Width (px)';
  String get heightPx => isHindi ? 'ऊंचाई (px)' : 'Height (px)';
  String get lockAspect => isHindi ? 'अनुपात लॉक करें' : 'Lock Aspect Ratio';
  String get maxFileSizeKb =>
      isHindi ? 'अधिकतम आकार (KB)' : 'Max File Size (KB)';
  String get format => isHindi ? 'फॉर्मेट' : 'Format';
  String get backgroundFill =>
      isHindi ? 'बैकग्राउंड रंग (पारदर्शी के लिए)' : 'Background Fill';

  // Dialog Titles & Messages
  String get errorTitle => isHindi ? 'त्रुटि हुई' : 'Action Needed';
  String get successTitle => isHindi ? 'सफल!' : 'Success!';
  String get confirmTitle => isHindi ? 'पुष्टि करें' : 'Confirm Action';
  String get confirmDeleteFile =>
      isHindi
          ? 'क्या आप इस ऐप-प्रबंधित फाइल को हटाना चाहते हैं?'
          : 'Do you want to delete this app-managed file copy?';
  String get confirmClearHistory =>
      isHindi
          ? 'क्या आप पूरी हिस्ट्री साफ करना चाहते हैं?'
          : 'Are you sure you want to clear your local history?';

  // Settings
  String get appearance => isHindi ? 'दिखावट' : 'Appearance';
  String get languageTitle => isHindi ? 'भाषा' : 'Language';
  String get privacyPolicy => isHindi ? 'गोपनीयता नीति' : 'Privacy Policy';
  String get aboutApp => isHindi ? 'सहीफाइल के बारे में' : 'About SahiFile';
  String get clearCache => isHindi ? 'कैश साफ करें' : 'Clear Temp Cache';
  String get cacheCleared =>
      isHindi ? 'अस्थायी कैश साफ कर दिया गया' : 'Temporary cache cleared';
  String get localFirstNotice =>
      isHindi
          ? 'आपकी सभी फाइलें 100% आपके फोन पर प्रोसेस होती हैं।'
          : '100% on-device processing. No files ever leave your phone.';
}
