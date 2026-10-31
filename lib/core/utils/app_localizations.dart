import 'package:flutter/material.dart';

class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static AppLocalizations of(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    return AppLocalizations(locale?.languageCode ?? 'ar');
  }

  bool get isArabic => languageCode == 'ar';

  // App
  String get appName => isArabic ? 'MTC لوجستكس' : 'MTC Logistics';

  // Auth
  String get login => isArabic ? 'تسجيل الدخول' : 'Sign In';
  String get username => isArabic ? 'اسم المستخدم / رقم الجوال' : 'Username / Mobile';
  String get password => isArabic ? 'كلمة المرور' : 'Password';
  String get forgotPassword => isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?';
  String get rememberMe => isArabic ? 'تذكرني' : 'Remember Me';
  String get welcomeBack => isArabic ? 'مرحباً بعودتك!' : 'Welcome Back!';
  String get signInToContinue => isArabic ? 'سجل دخولك لمتابعة رحلتك' : 'Sign in to continue your journey';

  // Home
  String get quickActions => isArabic ? 'الإجراءات السريعة' : 'Quick Actions';
  String get latestTask => isArabic ? 'آخر مهمة نشطة' : 'LATEST ACTIVE TASK';
  String get medicalTasks => isArabic ? 'مهمة طبية' : 'MEDICAL TASK';
  String get medicalTasksSubtitle => isArabic ? 'راجع مهامك لهذا اليوم' : "Check your today tasks";
  String get pharmaTask => isArabic ? 'مهمة صيدلية' : 'PHARMA TASK';
  String get moneyTask => isArabic ? 'مهمة مالية' : 'MONEY TASK';
  String get freezer => isArabic ? 'الحاوية' : 'Container';
  String get freezerSubtitle => isArabic ? 'وضع وإخراج' : 'Placement & Out'; // Kept as extra
  String get delivery => isArabic ? 'التوصيل' : 'Delivery'; // Kept as extra
  String get deliverySubtitle => isArabic ? 'المهام المغلقة' : 'Closed tasks'; // Kept as extra
  String get swap => isArabic ? 'تبديل' : 'SWAP';
  String get swapSubtitle => isArabic ? 'تبديل الشحنات بين الناقلين' : 'Swap shipments between drivers';
  String get performanceGreat => isArabic ? 'أداؤك رائع!' : 'Your performance is great!';
  String get completedTasks => isArabic ? 'أتممت ١٢ مهمة هذا الأسبوع' : 'You completed 12 tasks this week';
  String get details => isArabic ? 'التفاصيل' : 'DETAILS';
  String get taskStatus => isArabic ? 'حالة المهمة' : 'Task Status';
  String get newBadge => isArabic ? 'جديد' : 'NEW';
  // Task Type Selector
  String get pickupSamples => isArabic ? 'استلام العينات' : 'PICKUP SAMPLES';
  String get samplesPlacement => isArabic ? 'وضع العينات في الحاوية' : 'SAMPLES PLACEMENT';
  String get dropOffSamples => isArabic ? 'تسليم العينات' : 'DROP OFF SAMPLES';

  String get pickup => isArabic ? 'نقطة الاستلام' : 'Pickup';
  String get dropoff => isArabic ? 'نقطة التسليم' : 'Dropoff';

  String taskTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'SAMPLE':
        return isArabic ? 'عينات' : 'Samples';
      case 'BOX':
        return isArabic ? 'صناديق' : 'Boxes';
      default:
        return type;
    }
  }

  // Counts
  String tasksCount(int n) => isArabic
      ? _arabicCount(n, 'مهمة واحدة', 'مهمتان', 'مهام', 'مهمة')
      : '$n ${n == 1 ? 'Task' : 'Tasks'}';
  String samplesCount(int n) => isArabic
      ? _arabicCount(n, 'عينة واحدة', 'عينتان', 'عينات', 'عينة')
      : '$n ${n == 1 ? 'Sample' : 'Samples'}';
  String bagsCount(int n) => isArabic
      ? _arabicCount(n, 'كيس واحد', 'كيسان', 'أكياس', 'كيس')
      : '$n ${n == 1 ? 'Bag' : 'Bags'}';

  // Arabic number agreement: 1 and 2 use their own forms, 3–10 take the plural, 11+ the singular.
  String _arabicCount(int n, String one, String two, String few, String many) {
    if (n == 1) return one;
    if (n == 2) return two;
    final lastTwo = n % 100;
    if (n == 0 || (lastTwo >= 3 && lastTwo <= 10)) return '$n $few';
    return '$n $many';
  }

  // Drawer
  String get profile => isArabic ? 'الملف الشخصي' : 'PROFILE';
  String get mySchedule => isArabic ? 'الجدول' : 'SCHEDULE';
  String get carImages => isArabic ? 'صور السيارة' : 'CAR IMAGES';
  String get privacyPolicy => isArabic ? 'سياسة الخصوصية' : 'POLICY';
  String get shareApp => isArabic ? 'شارك التطبيق' : 'SHARE APP';
  String get scannerSettings => isArabic ? 'إعدادات الماسح' : 'SCANNER SETTINGS';
  String get taskHistory => isArabic ? 'سجل المهام' : 'Task History'; // extra
  String get settings => isArabic ? 'الإعدادات' : 'Settings'; // extra
  String get logout => isArabic ? 'تسجيل الخروج' : 'LOGOUT';
  String get language => isArabic ? 'تغيير اللغة' : 'CHANGE LANGUAGE';
  String get notifications => isArabic ? 'الإشعارات' : 'Notifications'; // extra

  // Task Status Steps
  String get stepConfirmed => isArabic ? 'مؤكدة' : 'Confirmed';
  String get stepPickup => isArabic ? 'الاستلام' : 'Pickup';
  String get stepInTransit => isArabic ? 'في الطريق' : 'In Transit';
  String get stepDelivered => isArabic ? 'تم التسليم' : 'Delivered';

  // Common
  String get loading => isArabic ? 'جاري التحميل...' : 'Loading...';
  String get confirm => isArabic ? 'تأكيد' : 'Confirm';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get retry => isArabic ? 'إعادة المحاولة' : 'Retry';
  String get success => isArabic ? 'تم بنجاح' : 'Success';
  String get error => isArabic ? 'حدث خطأ ما' : 'Something went wrong';
  String get noTasksFound => isArabic ? 'لا توجد مهام' : 'No tasks found';
  String get acceptAll => isArabic ? 'قبول الكل' : 'Accept All';

  // Dynamic Translations (Errors & Success Messages)
  String translate(String key, [List<String>? args]) {
    String translated = _dynamicTranslations[key]?[isArabic ? 'ar' : 'en'] ?? key;
    if (args != null && args.isNotEmpty) {
      for (int i = 0; i < args.length; i++) {
        translated = translated.replaceFirst('{$i}', args[i]);
      }
    }
    return translated;
  }

  // Helper for dynamic error messages (translates static Arabic strings and parameterized keys)
  String translateError(String err) {
    if (err.isEmpty) return error;

    // Check if it's a dynamic key with arguments separated by ||
    if (err.contains('||')) {
      final parts = err.split('||');
      final key = parts[0];
      final args = parts.sublist(1);
      if (_dynamicTranslations.containsKey(key)) {
        return translate(key, args);
      }
    }

    // Check if it's a direct key
    if (_dynamicTranslations.containsKey(err)) {
      return isArabic ? _dynamicTranslations[err]!['ar']! : _dynamicTranslations[err]!['en']!;
    }

    // Check if it's already translated dynamically
    for (var key in _dynamicTranslations.keys) {
      final arText = _dynamicTranslations[key]!['ar']!;
      final enText = _dynamicTranslations[key]!['en']!;
      
      // If the message exactly matches either English or Arabic, return the one for the CURRENT language
      if (err == arText || err == enText) {
        return isArabic ? arText : enText;
      }
    }

    return err;
  }

  static const Map<String, Map<String, String>> _dynamicTranslations = {

    'verifying_location': {
      'ar': 'جاري التحقق من الموقع...',
      'en': 'Verifying location...',
    },
    'invalid_location_code': {
      'ar': 'رمز الموقع غير صالح',
      'en': 'Invalid location code',
    },
    'invalid_location_number': {
      'ar': 'رقم الموقع غير صالح',
      'en': 'Invalid location number',
    },
    'verifying_token': {
      'ar': 'جاري التحقق من التوكن...',
      'en': 'Verifying token...',
    },
    'enable_gps_service': {
      'ar': 'يرجى تشغيل خدمة تحديد الموقع (GPS)',
      'en': 'Please enable GPS location service',
    },
    'grant_location_permission': {
      'ar': 'يرجى منح صلاحية الوصول للموقع',
      'en': 'Please grant location access permission',
    },
    'location_permission_denied_forever': {
      'ar': 'صلاحية الموقع مرفوضة دائماً، يرجى تفعيلها من إعدادات الجهاز',
      'en': 'Location permission is permanently denied, please enable it from device settings',
    },
    'failed_get_current_location': {
      'ar': 'فشل في الحصول على الموقع الحالي، تأكد من جودة الإشارة والمحاولة مجدداً.',
      'en': 'Failed to get current location, please check your signal and try again.',
    },
    'confirming_location_arrival': {
      'ar': 'جاري تأكيد الوصول للموقع...',
      'en': 'Confirming arrival at location...',
    },
    'unknown_location': {
      'ar': 'الموقع غير معروف',
      'en': 'Unknown location',
    },
    'bag_not_required': {
      'ar': 'عذراً، هذا الكيس غير مطلوب لهذه الوجهة أو تم مسحه بالفعل.',
      'en': 'Sorry, this bag is not required for this destination or has already been scanned.',
    },
    'bag_not_required_swap': {
      'ar': 'عذراً، هذا الكيس غير مطلوب لهذه المهمة أو تم مسحه بالفعل.',
      'en': 'Sorry, this bag is not required for this task or has already been scanned.',
    },
    'container_verified': {
      'ar': 'تم التحقق من الحاوية بنجاح!',
      'en': 'Container verified successfully!',
    },
    'bag_already_scanned': {
      'ar': 'تم مسح هذا الكيس مسبقاً!',
      'en': 'This bag has already been scanned!',
    },
    'sent_and_confirmed': {
      'ar': 'تم الإرسال والتأكيد بنجاح!',
      'en': 'Sent and confirmed successfully!',
    },
    'container_no_bags': {
      'ar': 'الحاوية ({0}) لا تحتوي على أكياس لهذه الوجهة!',
      'en': 'Container ({0}) does not contain bags for this destination!',
    },
    'all_tasks_accepted': {
      'ar': 'تم قبول جميع المهام بنجاح',
      'en': 'All tasks accepted successfully',
    },
    'task_rejected': {
      'ar': 'تم رفض المهمة بنجاح',
      'en': 'Task rejected successfully',
    },
    'task_receipt_confirmed': {
      'ar': 'تم تأكيد استلام المهمة بنجاح!',
      'en': 'Task receipt confirmed successfully!',
    },
    'emergency_request_sent': {
      'ar': 'تم إرسال طلب الطوارئ بنجاح',
      'en': 'Emergency request sent successfully',
    },
    'no_tasks_found': {
      'ar': 'لا توجد مهام',
      'en': 'No tasks found',
    },
    // Added Hardcoded Errors Translations
    'network_error': {
      'ar': 'خطأ في الشبكة. الرجاء التأكد من اتصالك بالإنترنت.',
      'en': 'Network error. Please check your internet connection.',
    },
    'car_images_upload_failed': {
      'ar': 'تعذر رفع صور السيارة، يرجى المحاولة لاحقاً.',
      'en': 'Failed to upload car images, please try again later.',
    },
    'driver_data_not_found': {
      'ar': 'لم يتم العثور على بيانات السائق',
      'en': 'Driver data not found',
    },
    'driver_number_not_found': {
      'ar': 'لم يتم العثور على رقم السائق',
      'en': 'Driver number not found',
    },
    'driver_data_unavailable': {
      'ar': 'بيانات السائق غير متوفرة',
      'en': 'Driver data not available',
    },
    'container_not_found_custody': {
      'ar': 'الحاوية غير موجودة أو غير مسجلة في عهدتك',
      'en': 'Container not found or not registered under your custody',
    },
    'container_mismatch': {
      'ar': 'الحاوية الممسوحة ({0}) لا تتطابق مع نوع العينات المطلوبة ({1})',
      'en': 'The scanned container ({0}) does not match the required sample type ({1})',
    },
    'driver_car_data_missing': {
      'ar': 'بيانات السائق أو السيارة مفقودة',
      'en': 'Driver or car data missing',
    },
    'car_release_failed': {
      'ar': 'فشل في إخلاء السيارة',
      'en': 'Failed to release the car',
    },
    'car_release_server_error': {
      'ar': 'حدث خطأ في الخادم أثناء محاولة إخلاء السيارة. يرجى المحاولة لاحقاً.',
      'en': 'A server error occurred while attempting to release the car. Please try again later.',
    },
    'invalid_container_barcode': {
      'ar': 'باركود الحاوية غير صالح. يجب أن ينتهي بـ -container',
      'en': 'Invalid container barcode. It must end with -container',
    },
    'invalid_container_number': {
      'ar': 'رقم الحاوية غير صحيح.',
      'en': 'Invalid container number.',
    },
    'no_containers_registered': {
      'ar': 'لا توجد حاويات مسجلة لسيارتك. يرجى تحديث البيانات.',
      'en': 'No containers registered for your car. Please update data.',
    },
    'bag_not_in_container': {
      'ar': 'هذا الكيس غير موجود في هذه الحاوية!',
      'en': 'This bag does not exist in this container!',
    },
    'pull_out_all_bags_before_close': {
      'ar': 'يرجى سحب جميع الأكياس من كافة الحاويات قبل إغلاق المهام.',
      'en': 'Please pull out all bags from all containers before closing tasks.',
    },
    'emergency_request_failed': {
      'ar': 'فشل إرسال طلب الطوارئ',
      'en': 'Failed to send emergency request',
    },
  };

  // Helper for dynamic loading messages
  String translateLoading(String message) {
    if (message.isEmpty) return loading;

    // Check dynamic translations first for direct key
    if (_dynamicTranslations.containsKey(message)) {
      return isArabic ? _dynamicTranslations[message]!['ar']! : _dynamicTranslations[message]!['en']!;
    }

    // Check loading translations for direct key
    if (_loadingTranslations.containsKey(message)) {
      return isArabic ? _loadingTranslations[message]!['ar']! : _loadingTranslations[message]!['en']!;
    }

    // Check if it's already translated dynamically
    for (var key in _loadingTranslations.keys) {
      final arText = _loadingTranslations[key]!['ar']!;
      final enText = _loadingTranslations[key]!['en']!;
      
      // If the message exactly matches either English or Arabic, return the one for the CURRENT language
      if (message == arText || message == enText) {
        return isArabic ? arText : enText;
      }
    }

    // Handle generic matches like "Uploading ROOM samples..."
    if (message.contains('Uploading') || message.contains('رفع')) {
      return isArabic ? 'جاري رفع العينات...' : 'Uploading samples...';
    }

    return message;
  }

  static const Map<String, Map<String, String>> _loadingTranslations = {
    'loading_bags': {
      'ar': 'جاري تحميل الحقائب...',
      'en': 'Loading bags...',
    },
    'closing_containers': {
      'ar': 'جاري إغلاق الحاويات...',
      'en': 'Closing containers...',
    },
    'loading_swap_tasks': {
      'ar': 'جاري تحميل مهام التبادل...',
      'en': 'Loading swap tasks...',
    },
    'accepting_tasks': {
      'ar': 'جاري قبول المهام...',
      'en': 'Accepting tasks...',
    },
    'rejecting_task': {
      'ar': 'جاري رفض المهمة...',
      'en': 'Rejecting task...',
    },
    'confirming_receipt': {
      'ar': 'جاري تأكيد استلام المهمة...',
      'en': 'Confirming task receipt...',
    },
    'loading_drop_off': {
      'ar': 'جاري تحميل مهام التسليم...',
      'en': 'Loading drop off tasks...',
    },
    'verify_location': {
      'ar': 'جاري التحقق من الموقع...',
      'en': 'Verifying location...',
    },
    'verify_token': {
      'ar': 'جاري التحقق من التوكن...',
      'en': 'Verifying token...',
    },
    'confirm_location': {
      'ar': 'جاري تأكيد الوصول للموقع...',
      'en': 'Confirming location arrival...',
    },
    'loading_pull_out': {
      'ar': 'جاري جلب المهام...',
      'en': 'Fetching tasks...',
    },
    'closing_tasks': {
      'ar': 'جاري إغلاق المهام...',
      'en': 'Closing tasks...',
    },
    'reporting_no_samples': {
      'ar': 'جاري الإبلاغ عن عدم وجود عينات...',
      'en': 'Reporting no samples...',
    }
  };
}

