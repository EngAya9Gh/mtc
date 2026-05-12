# قواعد بنية المشروع (Project Architectural Rules)

هذا الملف يحدد القواعد الأساسية لبناء وتنظيم المشروع لضمان الاستمرارية، سهولة الصيانة، وقابلية التوسع. يعتمد المشروع على **البنية النظيفة (Clean Architecture)** مع تنظيم يعتمد على **المميزات (Feature-driven structure)**.

---

## 1. هيكلية المجلدات (Folder Structure)

يتم تقسيم المشروع إلى قسمين رئيسيين داخل مجلد `lib`:

### أ. مجلد `core` (الأساسيات المشتركة)
يحتوي على الأجزاء التي تستخدم في كامل المشروع:
- `common`: الأدوات، العناصر المشتركة (Widgets)، الثوابت، والنماذج العامة.
- `config`: إعدادات التطبيق، الثيمات (Themes)، الألوان، والخطوط.
- `services`: الخدمات العامة مثل حقن التبعيات (Dependency Injection) وخدمات التنبيهات.
- `utils`: فئات المساعدة، النصوص الموحدة (`AppStrings`) ونقاط النهاية (`EndPoints`).

### ب. مجلد `features` (المميزات)
يحتوي على منطق العمل مقسماً حسب الميزة (مثل: `auth`, `sales`, `clients_care`). داخل كل ميزة أو ميزة فرعية، نتبع تقسيم البنية النظيفة:
- `data`: المستودعات (Repositories)، مصادر البيانات (Data Sources)، والنماذج (Models).
- `domain`: الكيانات (Entities)، حالات الاستخدام (Use Cases)، وواجهات المستودعات.
- `presentation`: الواجهات (UI)، والكتل البرمجية لإدارة الحالة (Bloc/Cubit).

---

## 2. توحيد التصميم والعناصر (UI Consistency)

يمنع استخدام العناصر الأساسية لـ Flutter مباشرة في الواجهات (مثل `Text`, `TextField`, `Dropdown`) دون تغليفها في عناصر موحدة خاصة بالمشروع.

### أ. النصوص (Typography)
- استخدم دائماً عنصر `AppText` الموجود في `features/app/presentation/widgets/app_text.dart`.
- لا تقم بتحديد نوع الخط أو الحجم يدوياً؛ اعتمد على الثيم المعرف في `core/config/theme/typography.dart`.

### ب. الألوان (Colors)
- استخدم لوحة الألوان المعرفة في `core/config/theme/color_scheme.dart`.
- يمنع استخدام أكواد الألوان مباشرة (مثل `0xFF...`) داخل الواجهات.

### ج. المكونات الموحدة (Unified Components)
اعتمد دائماً على المكونات الموجودة في `core/common/widgets`:
- `AppTextField`: للحقول النصية.
- `CustomDropdown` أو `AppDropDown`: للقوائم المنسدلة.
- `AppElevatedButton`: للأزرار الرئيسية.
- `AppLoader`: لعلامات التحميل.

---

## 3. التعامل مع الشبكة (Network & API)

- **EndPoints**: يتم تعريف جميع الروابط ونقاط النهاية داخل ملف مركزي واحد `lib/core/utils/end_points.dart`.
- **API Client**: يتم التعامل مع طلبات الشبكة عبر طبقة موحدة تدير الأخطاء والتوثيق (Tokens).

---

## 4. حقن التبعيات (Dependency Injection)

- نستخدم مكتبة `get_it` لإدارة حقن التبعيات.
- يتم تسجيل جميع الـ `Repositories`, `DataSources`, و `Cubit/Bloc` داخل `lib/core/services/di/di_container.dart`.
- يتم الوصول لأي خدمة عبر `getIt<ServiceName>()`.

---

## 5. إدارة النصوص واللغات (Text Management)

- يتم تخزين جميع النصوص الثابتة في ملف `lib/core/utils/app_strings.dart`.
- يسهل هذا الملف عملية تغيير أي نص في كامل المشروع من مكان واحد دون البحث في الواجهات.

---

## 6. قواعد برمجية عامة (General Coding Standards)

- **تسمية الملفات**: استخدم `snake_case` لجميع الملفات والمجلدات.
- **تسمية الفئات**: استخدم `PascalCase` لأسماء الكلاسات.
- **تسمية المتغيرات**: استخدم `camelCase` للمتغيرات والدوال.
- **فصل المهام**: الواجهة (Widget) يجب أن تحتوي فقط على كود التصميم، بينما المنطق (Logic) يجب أن يكون داخل الـ `Bloc` أو `Cubit`.

---

## 7. آلية إضافة ميزة جديدة (Adding a New Feature)

1. أنشئ مجلد الميزة داخل `lib/features`.
2. قسمه إلى `data`, `domain`, `presentation`.
3. عرف نقاط النهاية الجديدة في `EndPoints`.
4. سجل الخدمات الجديدة في `di_container.dart`.
5. استخدم العناصر الموحدة (`AppText`, `AppTextField`, الخ) لبناء الواجهات.