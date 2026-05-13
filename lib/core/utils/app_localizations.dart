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
  String get freezer => isArabic ? 'الفريزر' : 'Freezer'; // Kept as extra if needed
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
}

