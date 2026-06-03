import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_elevated_button.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../data/models/task_model.dart';
import '../../../../core/common/widgets/app_scanner_screen.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/di/di_container.dart';
import '../bloc/sample_collection_cubit.dart';
import '../bloc/sample_collection_state.dart';

class SampleCollectionScreen extends StatelessWidget {
  final MedicalTask task;
  final String? initialTemp;
  final String? initialType;

  const SampleCollectionScreen({
    super.key, 
    required this.task,
    this.initialTemp,
    this.initialType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SampleCollectionCubit>(),
      child: _SampleCollectionScreenView(
        task: task,
        initialTemp: initialTemp,
        initialType: initialType,
      ),
    );
  }
}

class _SampleCollectionScreenView extends StatefulWidget {
  final MedicalTask task;
  final String? initialTemp;
  final String? initialType;

  const _SampleCollectionScreenView({
    required this.task,
    this.initialTemp,
    this.initialType,
  });

  @override
  State<_SampleCollectionScreenView> createState() => _SampleCollectionScreenViewState();
}

class _SampleCollectionScreenViewState extends State<_SampleCollectionScreenView> {
  late String _selectedTemp;
  late String _selectedSampleType;
  final TextEditingController _manualScanController = TextEditingController();
  final List<Map<String, String>> _scannedBarcodes = [];

  @override
  void dispose() {
    _manualScanController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedTemp = widget.initialTemp ?? 'ROOM';
    _selectedSampleType = widget.initialType ?? 'Tubes';
    
    // Auto-scan the first barcode upon entry if we came from settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialTemp != null) {
        _onScanBarcode();
      }
    });
  }

  final List<String> _tempOptions = ['ROOM', 'REFRIGERATE', 'FROZEN'];
  final List<Map<String, String>> _sampleTypes = [
    {'api': 'Tubes', 'ar': 'أنابيب', 'en': 'Tubes'},
    {'api': 'Swabs', 'ar': 'مسحة', 'en': 'Swabs'},
    {'api': 'Body Fluids', 'ar': 'سوائل الجسم', 'en': 'Body Fluids'},
    {'api': 'UBT', 'ar': 'فحص التنفس', 'en': 'UBT'},
    {'api': 'NBS', 'ar': 'كروت الدم', 'en': 'NBS'},
    {'api': 'Blood Bags', 'ar': 'أكياس الدم', 'en': 'Blood Bags'},
    {'api': 'Others', 'ar': 'أخرى', 'en': 'Others'},
  ];

  void _onScanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AppScannerScreen(multiScan: true, allowDuplicates: true, title: 'Scan Samples')),
    );
    if (result is List<String> && result.isNotEmpty) {
      for (final code in result) {
        _addBarcode(_selectedSampleType, code);
      }
    } else if (result is String && result.isNotEmpty) {
      _addBarcode(_selectedSampleType, result);
    }
  }

  void _addBarcode(String sampleType, String barcode) {
    // if (_scannedBarcodes.any((e) => e['barcode'] == barcode)) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(AppLocalizations.of(context).isArabic ? 'تم مسح هذا الباركود مسبقاً' : 'This barcode is already scanned'),
    //       backgroundColor: Colors.orange,
    //     ),
    //   );
    //   return;
    // }

    setState(() {
      _scannedBarcodes.add({
        'barcode': barcode,
        'temp': _selectedTemp,
        'type': sampleType,
      });
    });
  }

  void _onSaveSamples() async {
    if (_scannedBarcodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).isArabic ? 'يرجى مسح عينة واحدة على الأقل.' : 'Please scan at least one sample.')),
      );
      return;
    }

    if (widget.task.taskType == 'BOX') {
      context.push('/first_task_count', extra: {
        'task': widget.task,
        'scannedSamples': _scannedBarcodes,
        'onBoxSaved': () {
          setState(() {
            _scannedBarcodes.clear();
          });
        },
      });
      return;
    }

    final cubit = context.read<SampleCollectionCubit>();
    final combinations = _scannedBarcodes.map((e) => '${e['temp']}|${e['type']}').toSet().toList();

    bool allSavedSuccessfully = true;
    final List<Map<String, String>> savedBarcodes = [];

    for (var combo in combinations) {
      final parts = combo.split('|');
      final temp = parts[0];
      final type = parts[1];

      final comboSamples = _scannedBarcodes
          .where((e) => e['temp'] == temp && e['type'] == type)
          .toList();

      if (comboSamples.isNotEmpty) {
        // 1. Navigate to BagScanScreen to get the bag barcode for this specific category
        final bagCode = await context.push<String>('/bag_scan', extra: {
          'temp': temp,
          'type': type,
        });
        
        if (bagCode == null || bagCode.isEmpty) {
          allSavedSuccessfully = false;
          break; // User cancelled scanning bag for this category, stop loop
        }

        await cubit.saveSamplesSequentially(
          taskId: widget.task.id,
          locationId: widget.task.fromLocation ?? 0,
          scannedSamples: comboSamples,
          bagCode: bagCode,
        );

        // Check if last state was success
        if (cubit.state.maybeWhen(success: (_) => true, orElse: () => false)) {
          savedBarcodes.addAll(comboSamples);
        } else {
          allSavedSuccessfully = false;
          break; // Stop on error
        }
      }
    }

    // Remove saved barcodes from the scanned list
    if (savedBarcodes.isNotEmpty) {
      setState(() {
        _scannedBarcodes.removeWhere((item) => savedBarcodes.contains(item));
      });
    }

    if (allSavedSuccessfully && savedBarcodes.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).isArabic 
              ? 'تم حفظ جميع العينات بنجاح!' 
              : 'All samples saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _onNoSamples() {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: AppText(isArabic ? 'هل أنت متأكد؟' : 'Are you sure?'),
        content: AppText(isArabic ? 'أنت على وشك الإبلاغ عن عدم وجود عينات لهذه المهمة.' : 'You are about to report no samples for this task.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: AppText(isArabic ? 'إلغاء' : 'CANCEL')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SampleCollectionCubit>().reportNoSamples(widget.task.id);
            },
            child: AppText(isArabic ? 'تأكيد' : 'CONFIRM', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _onFinishCollecting() {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;
    if (_scannedBarcodes.isNotEmpty) {
      if (widget.task.taskType == 'BOX') {
        context.push('/first_task_count', extra: {
          'task': widget.task,
          'scannedSamples': _scannedBarcodes,
          'onBoxSaved': () {
            setState(() {
              _scannedBarcodes.clear();
            });
          },
        });
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: AppText(isArabic ? 'تنبيه' : 'Warning'),
            content: AppText(
              isArabic
                  ? 'لديك عينات ممسوحة غير محفوظة. يرجى حفظها أولاً أو حذفها.'
                  : 'You have scanned samples that are not saved. Please save them first or delete them.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: AppText(isArabic ? 'موافق' : 'OK'),
              ),
            ],
          ),
        );
      }
      return;
    }
    
    if (widget.task.taskType == 'BOX') {
      context.push('/first_task_count', extra: {
        'task': widget.task,
        'scannedSamples': <Map<String, String>>[],
        'onBoxSaved': () {},
      });
    } else {
      context.push('/signature', extra: widget.task);
    }
  }

  Color _getTempColor(String temp) {
    switch (temp) {
      case 'ROOM': return Colors.orange;
      case 'REFRIGERATE': return Colors.blue;
      case 'FROZEN': return Colors.deepPurple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return BlocConsumer<SampleCollectionCubit, SampleCollectionState>(
      listener: (context, state) {
        state.whenOrNull(
          success: (msg) {
            // Show snackbar for reportNoSamples or generic success
            if (msg.toLowerCase().contains('no samples') || msg.contains('لا يوجد')) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(msg), backgroundColor: Colors.green),
              );
              context.push('/signature', extra: widget.task);
            }
          },
          error: (msg) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.red),
            );
          },
        );
      },
      builder: (context, state) {
        final isLoading = state.maybeWhen(loading: (_) => true, orElse: () => false);

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            title: AppText(isArabic ? 'جمع العينات' : 'Sample Collection'),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Top Stats Card
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(isArabic ? 'إجمالي الباركودات' : 'Total Barcodes', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              const SizedBox(height: 4),
                              AppText('${_scannedBarcodes.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.primary)),
                            ],
                          ),
                          // Temp Dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getTempColor(_selectedTemp).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _getTempColor(_selectedTemp).withOpacity(0.3)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedTemp,
                                icon: Icon(Icons.thermostat, color: _getTempColor(_selectedTemp), size: 16),
                                style: TextStyle(color: _getTempColor(_selectedTemp), fontWeight: FontWeight.bold, fontSize: 12),
                                items: _tempOptions.map((String value) {
                                  final itemColor = _getTempColor(value);
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: AppText(
                                      value,
                                      style: TextStyle(color: itemColor, fontWeight: FontWeight.bold),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedTemp = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      // Sample Type Selector
                      Row(
                        children: [
                          Icon(Icons.category_outlined, color: Colors.grey.shade400, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _sampleTypes.map((type) {
                                  final isSelected = _selectedSampleType == type['api'];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: AppText(
                                        isArabic ? type['ar']! : type['en']!,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.black,
                                          fontSize: 11,
                                        ),
                                      ),
                                      selected: isSelected,
                                      selectedColor: AppColors.primary,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() => _selectedSampleType = type['api']!);
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _scannedBarcodes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_scanner, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              AppText(
                                isArabic ? 'لم يتم مسح أي عينة بعد' : 'No samples scanned yet',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _scannedBarcodes.length,
                          itemBuilder: (context, index) {
                            final bCode = _scannedBarcodes[index];
                            final tempColor = _getTempColor(bCode['temp']!);
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: tempColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.qr_code, color: tempColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AppText(bCode['barcode'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            // Temp Label
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: tempColor,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: AppText(
                                                bCode['temp'] ?? '',
                                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            // Type Label
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                              ),
                                              child: AppText(
                                                isArabic 
                                                    ? _sampleTypes.firstWhere((t) => t['api'] == bCode['type'], orElse: () => {'ar': bCode['type'] ?? ''})['ar']!
                                                    : bCode['type'] ?? '',
                                                style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () {
                                      setState(() => _scannedBarcodes.removeAt(index));
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 6),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _manualScanController,
                        decoration: InputDecoration(
                          hintText: isArabic ? 'إدخال يدوي للباركود' : 'Manual barcode',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        if (_manualScanController.text.trim().isNotEmpty) {
                          _addBarcode(_selectedSampleType, _manualScanController.text.trim());
                          _manualScanController.clear();
                        }
                      },
                      child: AppText(isArabic ? 'إضافة' : 'ADD', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: isLoading ? null : _onScanBarcode,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppElevatedButton(
                        text: isArabic ? 'حفظ العينات' : 'SAVE SAMPLES',
                        isLoading: isLoading,
                        onPressed: _onSaveSamples,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isLoading ? null : _onNoSamples,
                        child: AppText(isArabic ? 'لا توجد عينات' : 'NO SAMPLES', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: isLoading ? null : _onFinishCollecting,
                    child: AppText(
                      isArabic ? 'إنهاء الجمع' : 'FINISH COLLECTING',
                      style: TextStyle(color: isLoading ? Colors.grey : AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
