class AppStrings {
  static const String appName = 'Blazma Logistics';
  
  // Auth
  static const String login = 'تسجيل الدخول';
  static const String username = 'اسم المستخدم / رقم الجوال';
  static const String password = 'كلمة المرور';
  static const String loginError = 'خطأ في تسجيل الدخول';
  
  // Home
  static const String medicalTasks = 'المهام الطبية';
  static const String freezerPlacement = 'إضافة للحاوية (Container)';
  static const String samplesPullOut = 'سحب من الحاوية (Container)';
  static const String dropOffSamples = 'تسليم العينات';
  
  // Common
  static const String loading = 'جاري التحميل...';
  static const String confirm = 'تأكيد';
  static const String cancel = 'إلغاء';
  static const String retry = 'إعادة المحاولة';
  static const String success = 'تم بنجاح';
  static const String error = 'حدث خطأ ما';
  
  // Navigation
  static const String profile = 'الملف الشخصي';
  static const String schedule = 'الجدول الزمني';
  static const String notifications = 'الإشعارات';
  static const String logout = 'تسجيل الخروج';
  
  // Drop Off
  static const String loadingDropOffTasks = 'جاري تحميل مهام التسليم...';
  static const String driverDataNotFound = 'لم يتم العثور على بيانات السائق';
  
  // Swap Tasks
  static const String loadingSwapTasks = 'جاري تحميل مهام التبادل...';
  static const String acceptingTasks = 'جاري قبول المهام...';
  static const String rejectingTask = 'جاري رفض المهمة...';
  static const String confirmingTaskReceipt = 'جاري تأكيد استلام المهمة...';
  
  // Pull Out
  static const String fetchingTasks = 'جاري جلب المهام...';
  static const String invalidContainerBarcode = 'باركود الحاوية غير صالح. يجب أن ينتهي بـ -container';
  static const String invalidContainerNumber = 'رقم الحاوية غير صحيح.';
  static const String noContainersRegistered = 'لا توجد حاويات مسجلة لسيارتك. يرجى تحديث البيانات.';
  static const String bagNotInContainer = 'هذا الكيس غير موجود في هذه الحاوية!';
  static const String pullOutAllBagsBeforeClose = 'يرجى سحب جميع الأكياس من كافة الحاويات قبل إغلاق المهام.';
  static const String closingTasks = 'جاري إغلاق المهام...';
}
