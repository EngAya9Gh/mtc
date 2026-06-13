import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_elevated_button.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../data/providers/user_info_provider.dart';
import '../bloc/car_inspection_cubit.dart';
import '../../data/models/car_images_response_model.dart';

class CarInspectionScreen extends StatefulWidget {
  const CarInspectionScreen({super.key});

  @override
  State<CarInspectionScreen> createState() => _CarInspectionScreenState();
}

class _CarInspectionScreenState extends State<CarInspectionScreen> {
  final ImagePicker _picker = ImagePicker();
  
  final Map<String, Uint8List> _images = {};
  
  CarImagesMapModel? _existingImagesMap;
  CarImageItemModel? _existingSignature;

  late final SignatureController _signatureController;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 4,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final carId = UserInfo().loginInfo?.car?.id ?? 0;
      context.read<CarInspectionCubit>().fetchCarImages(carId);
    });
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String side) async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (photo != null) {
      final bytes = await photo.readAsBytes();
      setState(() {
        _images[side] = bytes;
      });
    }
  }

  void _submit() async {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    final requiredKeys = ['front', 'back', 'right', 'left', 'inside1', 'inside2'];
    bool hasAllImages = requiredKeys.every((key) => _images.containsKey(key));

    bool hasAnyExisting = _existingImagesMap != null && (
        _existingImagesMap!.imageFront != null ||
        _existingImagesMap!.imageBack != null ||
        _existingImagesMap!.imageRight != null ||
        _existingImagesMap!.imageLeft != null ||
        _existingImagesMap!.imageInside1 != null ||
        _existingImagesMap!.imageInside2 != null ||
        _existingImagesMap!.otherImages.isNotEmpty
    );

    if (!hasAnyExisting && !hasAllImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'الرجاء التقاط جميع صور السيارة الستة' : 'Please take all 6 car images'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_existingSignature == null && _signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'الرجاء إضافة التوقيع' : 'Please provide a signature'), backgroundColor: Colors.red),
      );
      return;
    }

    final signatureBytes = await _signatureController.toPngBytes();
    if (signatureBytes == null) return;

    final driverId = UserInfo().userId ?? 0;
    final carId = UserInfo().loginInfo?.car?.id ?? 0;

    if (!mounted) return;
    context.read<CarInspectionCubit>().submitInspection(
      driverId: driverId,
      carId: carId,
      imagesBytes: _images.map((key, value) => MapEntry(key, value.toList())),
      signatureBytes: signatureBytes.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: AppText(isArabic ? 'استلام السيارة' : 'Receive Car'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: BlocConsumer<CarInspectionCubit, CarInspectionState>(
        listener: (context, state) {
          if (state is CarInspectionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isArabic ? 'تم استلام السيارة بنجاح' : 'Car received successfully'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          } else if (state is CarImagesLoaded) {
            setState(() {
              _existingImagesMap = state.data.images;
              _existingSignature = state.data.signature;
            });
          } else if (state is CarInspectionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is CarImagesFetching) {
            return const Center(child: CircularProgressIndicator());
          }

          final isLoading = state is CarInspectionLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText(
                  isArabic ? 'صور السيارة' : 'Car Images',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                
                // if (_existingImagesMap?.otherImages.isNotEmpty == true) ...[
                //   AppText(
                //     isArabic ? 'صور أخرى سابقة' : 'Other Previous Images',
                //     style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                //   ),
                //   const SizedBox(height: 8),
                //   SizedBox(
                //     height: 100,
                //     child: ListView.separated(
                //       scrollDirection: Axis.horizontal,
                //       itemCount: _existingImagesMap!.otherImages.length,
                //       separatorBuilder: (_, __) => const SizedBox(width: 8),
                //       itemBuilder: (context, index) {
                //         return ClipRRect(
                //           borderRadius: BorderRadius.circular(12),
                //           child: Image.network(
                //             _existingImagesMap!.otherImages[index].url,
                //             width: 100,
                //             height: 100,
                //             fit: BoxFit.cover,
                //           ),
                //         );
                //       },
                //     ),
                //   ),
                //   const SizedBox(height: 16),
                // ],
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildImagePickerCard('front', isArabic ? 'الأمام' : 'Front'),
                    _buildImagePickerCard('back', isArabic ? 'الخلف' : 'Back'),
                    _buildImagePickerCard('right', isArabic ? 'اليمين' : 'Right'),
                    _buildImagePickerCard('left', isArabic ? 'اليسار' : 'Left'),
                    _buildImagePickerCard('inside1', isArabic ? 'الداخل 1' : 'Inside 1'),
                    _buildImagePickerCard('inside2', isArabic ? 'الداخل 2' : 'Inside 2'),
                  ],
                ),
                
                const SizedBox(height: 32),
                AppText(
                  isArabic ? 'التوقيع' : 'Signature',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 16),

                if (_existingSignature != null) ...[
                  AppText(
                    isArabic ? 'التوقيع السابق' : 'Previous Signature',
                    style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      image: DecorationImage(
                        image: NetworkImage(_existingSignature!.url),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    children: [
                      Signature(
                        controller: _signatureController,
                        height: 200,
                        backgroundColor: Colors.white,
                      ),
                      Container(
                        color: Colors.grey.shade50,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _signatureController.clear(),
                              icon: const Icon(Icons.clear, color: Colors.red, size: 18),
                              label: AppText(isArabic ? 'مسح التوقيع' : 'Clear', style: const TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  AppElevatedButton(
                    text: isArabic ? 'تأكيد واستلام' : 'Confirm & Receive',
                    onPressed: _submit,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePickerCard(String side, String label) {
    final imageBytes = _images[side];
    String? networkUrl;
    if (imageBytes == null && _existingImagesMap != null) {
      switch (side) {
        case 'front': networkUrl = _existingImagesMap!.imageFront?.url; break;
        case 'back': networkUrl = _existingImagesMap!.imageBack?.url; break;
        case 'right': networkUrl = _existingImagesMap!.imageRight?.url; break;
        case 'left': networkUrl = _existingImagesMap!.imageLeft?.url; break;
        case 'inside1': networkUrl = _existingImagesMap!.imageInside1?.url; break;
        case 'inside2': networkUrl = _existingImagesMap!.imageInside2?.url; break;
      }
    }

    return GestureDetector(
      onTap: () => _pickImage(side),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: (imageBytes != null || networkUrl != null) ? AppColors.primary : Colors.grey.shade300, width: 2),
          image: imageBytes != null 
              ? DecorationImage(image: MemoryImage(imageBytes), fit: BoxFit.cover) 
              : (networkUrl != null 
                  ? DecorationImage(image: NetworkImage(networkUrl), fit: BoxFit.cover)
                  : null),
        ),
        child: (imageBytes == null && networkUrl == null)
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 32),
                  const SizedBox(height: 8),
                  AppText(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: AppText(
                    label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
      ),
    );
  }
}
