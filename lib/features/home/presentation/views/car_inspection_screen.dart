import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hand_signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_elevated_button.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/services/di/di_container.dart';
import '../bloc/car_inspection_cubit.dart';
import '../bloc/car_inspection_state.dart';

class CarInspectionScreen extends StatelessWidget {
  const CarInspectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CarInspectionCubit>(),
      child: const _CarInspectionView(),
    );
  }
}

class _CarInspectionView extends StatefulWidget {
  const _CarInspectionView();

  @override
  State<_CarInspectionView> createState() => _CarInspectionViewState();
}

class _CarInspectionViewState extends State<_CarInspectionView> {
  final HandSignatureControl _signatureControl = HandSignatureControl();
  final Map<String, XFile?> _images = {
    'front': null,
    'back': null,
    'right': null,
    'left': null,
    'inside1': null,
    'inside2': null,
  };

  Future<void> _pickImage(String key) async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(AppLocalizations.of(context).isArabic ? 'المعرض' : 'Gallery'),
                onTap: () async {
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() => _images[key] = image);
                  }
                  if (mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(AppLocalizations.of(context).isArabic ? 'الكاميرا' : 'Camera'),
                onTap: () async {
                  final XFile? image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() => _images[key] = image);
                  }
                  if (mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onUpload() async {
    bool allImagesPicked = _images.values.every((file) => file != null);
    if (!allImagesPicked || _signatureControl.paths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture all images and provide a signature.')),
      );
      return;
    }

    // Convert signature to bytes
    final ByteData? byteData = await _signatureControl.toImage(
      color: Colors.black,
      background: Colors.white,
    );
    
    if (byteData == null) return;
    
    final Uint8List buffer = byteData.buffer.asUint8List();
    
    final actualImages = _images.map((key, value) => MapEntry(key, value!));

    if (mounted) {
      context.read<CarInspectionCubit>().uploadCarImages(
        signatureBytes: buffer,
        images: actualImages,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

          return BlocConsumer<CarInspectionCubit, CarInspectionState>(
            listener: (context, state) {
              state.whenOrNull(
                success: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Car inspection uploaded successfully!'), backgroundColor: Colors.green),
                  );
                  context.pop();
                },
                error: (msg) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg), backgroundColor: Colors.red),
                  );
                },
              );
            },
            builder: (context, state) {
              final isLoading = state.maybeWhen(loading: () => true, orElse: () => false);
              
              return Scaffold(
                backgroundColor: const Color(0xFFF7F9FC),
                appBar: AppBar(
                  title: AppText(isArabic ? 'صور السيارة' : 'Car Images'),
                  centerTitle: true,
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppText(
                        isArabic 
                          ? 'يرجى التقاط صور للسيارة من كافة الجوانب بالإضافة إلى صورتين من الداخل.'
                          : 'Please capture photos of the car from all sides and two photos from the inside.',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      
                      // Image Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        children: [
                          _buildImagePickerBox(isArabic ? 'الأمام' : 'Front', 'front'),
                          _buildImagePickerBox(isArabic ? 'الخلف' : 'Back', 'back'),
                          _buildImagePickerBox(isArabic ? 'اليمين' : 'Right', 'right'),
                          _buildImagePickerBox(isArabic ? 'اليسار' : 'Left', 'left'),
                          _buildImagePickerBox(isArabic ? 'الداخل 1' : 'Inside 1', 'inside1'),
                          _buildImagePickerBox(isArabic ? 'الداخل 2' : 'Inside 2', 'inside2'),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      AppText(
                        isArabic ? 'توقيع السائق:' : 'Driver Signature:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: HandSignature(
                            control: _signatureControl,
                            color: Colors.blueGrey.shade800,
                            width: 3.0,
                            maxWidth: 5.0,
                            type: SignatureDrawType.shape,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _signatureControl.clear(),
                          icon: const Icon(Icons.clear, color: Colors.red, size: 18),
                          label: AppText(
                            isArabic ? 'مسح التوقيع' : 'Clear',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      AppElevatedButton(
                        text: isArabic ? 'رفع البيانات' : 'UPLOAD',
                        isLoading: isLoading,
                        onPressed: _onUpload,
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildImagePickerBox(String title, String key) {
    final hasImage = _images[key] != null;
    return GestureDetector(
      onTap: () => _pickImage(key),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hasImage ? AppColors.primary : Colors.grey.shade300, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasImage ? Icons.check_circle : Icons.add_a_photo_rounded,
              color: hasImage ? AppColors.primary : Colors.grey.shade400,
              size: 32,
            ),
            const SizedBox(height: 12),
            AppText(
              title,
              style: TextStyle(
                color: hasImage ? AppColors.primary : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
