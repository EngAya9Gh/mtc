# f16 — إعدادات ماسح Scandit لتطبيق Flutter (Scandit Setup Guide)

هذا الملف يوثق الخطوات الدقيقة وما يلزم إضافته في مشروع فلاتر (`mtc_app`) لتهيئة وتشغيل مكتبة **Scandit Data Capture SDK** بنجاح استناداً إلى الترخيص والإعدادات من التطبيق القديم.

---

## 1. الحزم المطلوبة (Pubspec Dependencies)
يجب إضافة الحزم الرسمية الخاصة بـ Scandit في ملف `pubspec.yaml` بمشروعك:

```yaml
dependencies:
  # ... الحزم الأخرى ...
  scandit_flutter_datacapture_core: ^7.4.0
  scandit_flutter_datacapture_barcode: ^7.4.0
```
> **ملاحظة:** الإصدار `7.4.0` هو الأقرب والمستقر الذي كان يعتمد عليه الأندرويد القديم.

---

## 2. الصلاحيات وإعدادات النظام (Native Configuration)

### أ. نظام Android
مكتبة Scandit لها متطلبات خاصة بنظام الأندرويد لكي تعمل الكاميرا وتستدعي مكتبات الـ C++ المطلوبة.

1. **الحد الأدنى للإصدار (`minSdkVersion`):**
   في ملف `android/app/build.gradle`، يجب التأكد من أن الحد الأدنى للإصدار هو 23 على الأقل:
   ```gradle
   android {
       defaultConfig {
           minSdkVersion 23
           targetSdkVersion 34
           // ...
       }
   }
   ```

2. **صلاحية الكاميرا:**
   في ملف `android/app/src/main/AndroidManifest.xml`، أضف السطر التالي قبل وسوم الـ `<application>`:
   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   ```

### ب. نظام iOS
في حال تشغيل التطبيق على أجهزة الآيفون، يجب إعداد الصلاحيات وتحديث الـ Pods:

1. **رسالة الصلاحية:**
   في ملف `ios/Runner/Info.plist`، أضف صلاحية الكاميرا مع رسالة نصية للمستخدم:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>This app requires camera access to scan barcodes for logistics tasks.</string>
   ```

2. **تثبيت الـ Pods:**
   بعد الإضافة في `pubspec.yaml`، يجب تشغيل أمر التثبيت في مسار الآيفون:
   ```bash
   cd ios && pod install && cd ..
   ```

---

## 3. مفتاح الترخيص (License Key) الخاص بـ Scandit
هذا هو مفتاح الترخيص المدفوع والموثق الذي تم استخراجه من كود الأندرويد القديم (`strings.xml`)، وهو مرتبط بحزمة التطبيق (Bundle ID) الخاصة بـ Logistics. يجب تمريره عند تهيئة الـ Context.

```text
AS8ARpuBDytnQReAiwu/Ey4jPsx4D9nfU1754YcLeC85Qe99dWgHiuBLdLEqLolKenBDhklVcVAzXKoS70ocgSYr8oELWDwEwA3u04xmwCHAGsDXpHjwu9FR2/T+OH5t4TxB6BIeYXjKP2qqBMm3YTjFEfinK3PKo/HGgz2+8R100ZP6Y0nRM+/R89AWoiah8CBRzQ8MG5K5xQpztNT7b+uCXAbSUjEJ3P/KTmsBGuFHdIgexZ8HcINW3l11eOfnUju/Z1LtQF7GJrMtpXT59hfoV8sjYDxiS0/Tj+fmSdTTkL+zVr/yqBnBm9qf+eR6EvA0TEUWHLQOjrWiFS7tDOnS68CdyT0fE9XgBn9wfFJLQSNmMHAaqDtqlV1eC3PgYPig47E4mY38jTY2OzOA0d9LLcw5JOtZO8c+OZKc85fBcanJZaOnfoTE+7Jvw8ON3r6R3oP743zRhPfRyhCX6qZVxMPa/D47bJq+IWhlCTrFJsOgDVD2/bKC1du6kukN5LhAFaZxPKEJBgKcUzG4uHTdCYqFW1cVZTNzo6ktaDg7Fn9ywJrLF8xMjVqoiZyDQf37spX4RA0P7fmTC60o9A6veiIYQ2UkGebKQ5FTC+Ak+3RFgrnBv98kO84pN5p6cWEQiw3JlhRqRgCq0ZhHAtT3pLAg5A3FO5iaVqi9t993GlNb+gdT1lUo24bu4WhcAXhrgYrMatotDrbT3nbI75W56HKEUPcl81++jkSK2JVDckItmDtwWCW7bKRh2/HMiLG3+XOpFmevmDFNO/zN9eUylXpUoazLlF75nyDfCyqjaDz9OjY8zGGGPPU=
```

---

## 4. كود التهيئة المبدئي في فلاتر (Initialization Snippet)
لبناء خدمة الماسح (Scanner Service) مستقبلاً، ستحتاج إلى مقتطف الكود هذا لتهيئة المكتبة بشكل صحيح:

```dart
import 'package:scandit_flutter_datacapture_core/scandit_flutter_datacapture_core.dart';
import 'package:scandit_flutter_datacapture_barcode/scandit_flutter_datacapture_barcode.dart';

Future<void> initScanditScanner() async {
  // 1. مفتاح الترخيص
  final String licenseKey = "مفتاح الترخيص الموجود بالأعلى";

  // 2. تهيئة الـ Context
  DataCaptureContext context = DataCaptureContext.forLicenseKey(licenseKey);

  // 3. تفعيل الكاميرا الأساسية (الخلفية)
  Camera? camera = Camera.defaultCamera;
  if (camera != null) {
    context.setFrameSource(camera);
    camera.switchToDesiredState(FrameSourceState.on);
  }

  // 4. إعداد الأنواع المدعومة للباركود (QR, Code128, الخ..)
  BarcodeCaptureSettings settings = BarcodeCaptureSettings();
  settings.enableSymbology(Symbology.qr, true);
  settings.enableSymbology(Symbology.code128, true);

  // 5. ربط الإعدادات بمركز الالتقاط
  BarcodeCapture barcodeCapture = BarcodeCapture.forContext(context, settings);
  
  // (لاحقاً تقوم بتمرير الـ context لـ DataCaptureView في الـ UI الخاص بك)
}
```
