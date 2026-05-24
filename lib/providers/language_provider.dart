import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _language = 'BN'; // Default is Bengali
  late Map<String, Map<String, String>> _translations;
  
  String get language => _language;
  Map<String, String> get t => _translations[_language]!;
  Map<String, Map<String, String>> get translations => _translations;

  LanguageProvider() {
    _translations = _buildTranslations();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('app_language') ?? 'BN';
    notifyListeners();
  }

  void toggleLanguage() {
    _language = _language == 'EN' ? 'BN' : 'EN';
    _saveLanguage();
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _saveLanguage();
    notifyListeners();
  }

  Future<void> _saveLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', _language);
  }

  String translate(String key) {
    return _translations[_language]?[key] ?? key;
  }

  Map<String, Map<String, String>> _buildTranslations() {
    return {
      'EN': {
        'home': 'Home',
        'mapViewer': 'Map Viewer',
        'organization': 'Organization',
        'committees': 'Committees',
        'technicalCommittee': 'Technical Committee',
        'executiveCommittee': 'Executive Committee',
        'subCommittees': 'Sub Committee',
        'tools': 'Tools',
        'dataViewer': 'Data Viewer',
        'integratedGeoportal': 'Integrated Geoportal',
        'timeSeriesAnalysis': 'Time Series Analysis',
        'others': 'Others',
        'focalPersons': 'Focal Points',
        'gallery': 'Gallery',
        'metadata': 'Metadata',
        'geocodeMap': 'Geocode Map',
        'geocodeManagement': 'Geocode Tabular',
        'signIn': 'Sign In',
        'learnMore': 'Learn More',
        'aboutBgisp': 'About BGISP',
        'aboutBgispDesc1': 'The Bangladesh GIS Platform (BGISP) is the centralized national initiative aimed at establishing a unified geospatial data infrastructure for Bangladesh.',
        'aboutBgispDesc2': 'Its vision is to create a single, coordinated national GIS platform to streamline mapping and spatial data activities across the country.',
        'aboutBgispDesc3': 'The primary mission is to foster collaboration among all GIS-related government offices, departments, and organizations to eliminate duplication of effort and prevent wastage of public resources.',
        'aboutBgispDesc4': 'The platform develops standardized guidelines for data archiving and sharing, provides technical support, and facilitates communication with international bodies.',
        'objective': 'Our Objective',
        'objectiveText': 'To establish a centralized geographic information system that facilitates efficient data sharing, promotes transparency in governance, supports sustainable development initiatives, and provides accessible geospatial services to all stakeholders across Bangladesh.',
        'mission': 'Our Mission',
        'missionText': 'To develop, maintain and promote the use of a standardized national geographic information infrastructure that facilitates data sharing, interoperability, and supports sustainable development goals across all government agencies and public institutions.',
        'vision': 'Our Vision',
        'visionText': 'To become a world-class spatial data infrastructure that empowers citizens, businesses and government with timely, accurate and accessible geographic information for a prosperous and digitally transformed Bangladesh.',
        'newsAndEvents': 'News & Events',
        'viewAll': 'View All',
        'readMore': 'Read More',
        'ourPartners': 'Our Partners',
        'quickLinks': 'Quick Links',
        'contactUs': 'Contact Us',
        'selectLanguage': 'Select Language',
        'english': 'English',
        'bengali': 'Bengali (বাংলা)',
        'organizationTitle': 'BGISP Members',
        'organizationSubtitle': 'Collaborating for Better Geospatial Solutions',
        'viewDetails': 'View Details',
        'errorLoading': 'Error loading organizations. Please try again later.',
        'showing': 'Showing',
        'organizations': 'organizations',
        'searchPlaceholder': 'Search organizations...',
        'noResults': 'No organizations found matching your search.',
        'noWebsite': 'No website available',
        'retry': 'Retry',
        'goBack': 'Go Back',
        'close': 'Close',
        'about': 'About',
        'contact': 'Contact',
        'version': 'Version 1.0.0',
        'description': 'Description',
        'website': 'Website',
        'data': 'Data',
        'map': 'Map',
        'service': 'Service',
        'comingSoon': 'Coming soon...',
        'geospatialDataInfrastructure': 'Geospatial Data Infrastructure',
      },
      'BN': {
        'home': 'হোম',
        'mapViewer': 'মানচিত্র দর্শক',
        'organization': 'সংগঠন',
        'committees': 'কমিটি',
        'technicalCommittee': 'প্রযুক্তিগত কমিটি',
        'executiveCommittee': 'নির্বাহী কমিটি',
        'subCommittees': 'উপ/অন্যান্য কমিটি',
        'tools': 'টুলস',
        'dataViewer': 'ডেটা দর্শক',
        'integratedGeoportal': 'সমন্বিত জিওপোর্টাল',
        'timeSeriesAnalysis': 'টাইম সিরিজ বিশ্লেষণ',
        'others': 'অন্যান্য',
        'focalPersons': 'ফোকাল পয়েন্টস',
        'gallery': 'গ্যালারি',
        'metadata': 'মেটাডেটা',
        'geocodeMap': 'জিওকোড মানচিত্র',
        'geocodeManagement': 'জিওকোড ট্যাবুলার',
        'signIn': 'সাইন ইন',
        'learnMore': 'আরও জানুন',
        'aboutBgisp': 'BGISP সম্পর্কে',
        'aboutBgispDesc1': 'বাংলাদেশ জিআইএস প্ল্যাটফর্ম (BGISP) হল একটি কেন্দ্রীভূত জাতীয় উদ্যোগ যা বাংলাদেশের জন্য একটি একক ভূ-স্থানিক ডেটা অবকাঠামো প্রতিষ্ঠার লক্ষ্যে কাজ করে।',
        'aboutBgispDesc2': 'এর দৃষ্টি হল একটি একক, সমন্বিত জাতীয় জিআইএস প্ল্যাটফর্ম তৈরি করা যা দেশের মানচিত্র এবং স্থানিক ডেটা কার্যক্রমকে সহজতর করবে।',
        'aboutBgispDesc3': 'প্রাথমিক মিশন হল সমস্ত জিআইএস-সম্পর্কিত সরকারি অফিস, বিভাগ এবং সংস্থাগুলির মধ্যে সহযোগিতা বৃদ্ধি করা যাতে প্রচেষ্টার পুনরাবৃত্তি দূর করা যায় এবং জনসম্পদের অপচয় প্রতিরোধ করা যায়।',
        'aboutBgispDesc4': 'প্ল্যাটফর্মটি ডেটা আর্কাইভিং এবং শেয়ারিংয়ের জন্য মানক নির্দেশিকা তৈরি করে, প্রযুক্তিগত সহায়তা প্রদান করে এবং আন্তর্জাতিক সংস্থাগুলির সাথে যোগাযোগ সহজতর করে।',
        'objective': 'আমাদের উদ্দেশ্য',
        'objectiveText': 'বাংলাদেশ জিআইএস পোর্টালের (BGISP) প্রধান উদ্দেশ্য হল একটি কেন্দ্রীভূত জাতীয় জিআইএস প্ল্যাটফর্ম প্রতিষ্ঠা করা যা সংশ্লিষ্ট সরকারি অফিস এবং সংস্থাগুলির মধ্যে সমস্ত ভূ-স্থানিক কার্যক্রমকে সমন্বিত করে।',
        'mission': 'আমাদের মিশন',
        'missionText': 'একটি মানক জাতীয় ভূ-তথ্য অবকাঠামো তৈরি, বজায় রাখা এবং প্রচার করা যা ডেটা শেয়ারিং, আন্তঃঅপারযোগ্যতা সক্ষম করে এবং বাংলাদেশের সমস্ত সরকারি সংস্থা এবং জন প্রতিষ্ঠান জুড়ে টেকসই উন্নয়ন লক্ষ্যগুলিকে সমর্থন করে।',
        'vision': 'আমাদের দৃষ্টি',
        'visionText': 'একটি বিশ্বমানের স্থানিক ডেটা অবকাঠামো হয়ে উঠতে যা নাগরিক, ব্যবসা এবং সরকারকে সময়মত, সঠিক এবং অ্যাক্সেসযোগ্য ভূ-তথ্য দিয়ে সমৃদ্ধ এবং ডিজিটালভাবে রূপান্তরিত বাংলাদেশের জন্য ক্ষমতায়ন করে।',
        'newsAndEvents': 'সংবাদ ও ইভেন্ট',
        'viewAll': 'সব দেখুন',
        'readMore': 'আরও পড়ুন',
        'ourPartners': 'আমাদের অংশীদার',
        'quickLinks': 'দ্রুত লিঙ্ক',
        'contactUs': 'যোগাযোগ করুন',
        'selectLanguage': 'ভাষা নির্বাচন করুন',
        'english': 'English',
        'bengali': 'Bengali (বাংলা)',
        'organizationTitle': 'BGISP সদস্য',
        'organizationSubtitle': 'উত্তরওয়াদী ভূ-স্থানিক সমাধানের জন্য সহযোগিতা',
        'viewDetails': 'বিস্তারিত দেখুন',
        'errorLoading': 'সংগঠন লোড করতে ত্রুটি হয়েছে। পরে আবার চেষ্টা করুন।',
        'showing': 'দেখানো হচ্ছে',
        'organizations': 'সংগঠন',
        'searchPlaceholder': 'সংগঠন খুঁজুন...',
        'noResults': 'আপনার অনুসন্ধানের সাথে মিলে যায় এমন কোন সংগঠন পাওয়া যায়নি।',
        'noWebsite': 'কোন ওয়েবসাইট উপলব্ধ নেই',
        'retry': 'পুনরায় চেষ্টা করুন',
        'goBack': 'ফিরে যান',
        'close': 'বন্ধ',
        'about': 'সম্পর্কে',
        'contact': 'যোগাযোগ',
        'version': 'সংস্করণ 1.0.0',
        'description': 'বিবরণ',
        'website': 'ওয়েবসাইট',
        'data': 'ডেটা',
        'map': 'মানচিত্র',
        'service': 'সেবা',
        'comingSoon': 'শীঘ্রই আসছে...',
        'geospatialDataInfrastructure': 'ভূ-স্থানিক ডেটা অবকাঠামো',
      },
    };
  }
}