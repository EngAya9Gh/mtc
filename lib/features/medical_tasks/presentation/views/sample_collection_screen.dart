import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_elevated_button.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../data/models/task_model.dart';

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
  final List<Map<String, String>> _scannedBarcodes = [];

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

  void _onScanBarcode() {
    _addBarcode(_selectedSampleType);
  }

  void _addBarcode(String sampleType) {
    setState(() {
      _scannedBarcodes.add({
        'barcode': 'BLZ-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        'temp': _selectedTemp,
        'type': sampleType,
      });
    });
  }

  void _onSaveSamples() async {
    if (_scannedBarcodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan at least one sample.')),
      );
      return;
    }

    // 1. Navigate to BagScanScreen to get the bag barcode
    final bagCode = await context.push<String>('/bag_scan');
    
    if (bagCode == null || bagCode.isEmpty) {
      return; // User cancelled or didn't scan
    }

    // Group barcodes by (temp, type) to send correct API calls
    final cubit = context.read<SampleCollectionCubit>();
    
    // We get unique combinations of temp and type
    final combinations = _scannedBarcodes.map((e) => '${e['temp']}|${e['type']}').toSet();

    for (var combo in combinations) {
      final parts = combo.split('|');
      final temp = parts[0];
      final type = parts[1];

      final barcodes = _scannedBarcodes
          .where((e) => e['temp'] == temp && e['type'] == type)
          .map((e) => e['barcode']!)
          .toList();

      if (barcodes.isNotEmpty) {
        await cubit.saveSamplesSequentially(
          taskId: widget.task.id,
          locationId: widget.task.fromLocation ?? 0,
          scannedSamples: _scannedBarcodes.where((e) => e['temp'] == temp && e['type'] == type).toList(),
          bagCode: bagCode,
        );
      }
    }
  }

  void _onNoSamples() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: AppText('Are you sure?'),
        content: AppText('You are about to report no samples for this task.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const AppText('CANCEL')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SampleCollectionCubit>().reportNoSamples(widget.task.id);
            },
            child: const AppText('CONFIRM', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _onFinishCollecting() {
    context.push('/signature', extra: widget.task);
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.green),
            );
            // Navigate to signature screen automatically
            context.push('/signature', extra: widget.task);
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
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Top Stats Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                const SizedBox(height: 20),

                // Barcodes List
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
                                        Row(
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
                                            const SizedBox(width: 6),
                                            // Type Label
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                              ),
                                              child: AppText(
                                                bCode['type'] ?? '',
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
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: AppElevatedButton(
                        text: isArabic ? 'لا يوجد عينات' : 'NO SAMPLES',
                        onPressed: isLoading ? null : _onNoSamples,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppElevatedButton(
                        text: isArabic ? 'مسح باركود' : 'SCAN BARCODE',
                        onPressed: isLoading ? null : _onScanBarcode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppElevatedButton(
                  text: isArabic ? 'حفظ العينات' : 'SAVE SAMPLES',
                  isLoading: isLoading,
                  onPressed: _onSaveSamples,
                ),
                const SizedBox(height: 12),
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
