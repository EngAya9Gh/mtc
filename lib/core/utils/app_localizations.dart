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

  static const Map<String, Map<String, String>> _dynamicTranslations = {
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
  };

  // Helper for dynamic loading messages
  String translateLoading(String message) {
    if (message.isEmpty) return loading;

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

