import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_elevated_button.dart';
import '../../../../core/common/widgets/app_loader.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/services/di/di_container.dart';
import '../bloc/schedule_cubit.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ScheduleCubit>()..getSchedule(),
      child: const _ScheduleScreenView(),
    );
  }
}

class _ScheduleScreenView extends StatelessWidget {
  const _ScheduleScreenView();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: AppText(isArabic ? 'الجدول الزمني' : 'Work Schedule'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ScheduleCubit>().getSchedule(),
          ),
        ],
      ),
      body: BlocBuilder<ScheduleCubit, ScheduleState>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox.shrink(),
            loading: () => const Center(child: AppLoader()),
            error: (msg) => Center(child: AppText(msg, style: const TextStyle(color: Colors.red))),
            success: (schedule) {
              if (schedule.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      AppText(isArabic ? 'لا يوجد مواعيد حالياً' : 'No schedule found', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: schedule.length,
                      itemBuilder: (context, index) {
                        final item = schedule[index];
                        return _buildScheduleItem(item, isArabic);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: AppElevatedButton(
                      text: isArabic ? 'قبول جميع المواعيد' : 'ACCEPT ALL SCHEDULES',
                      onPressed: () => context.read<ScheduleCubit>().acceptAll(),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildScheduleItem(dynamic item, bool isArabic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Status bar
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: item['is_accepted'] == 1 ? Colors.green : AppColors.primary,
                borderRadius: BorderRadius.horizontal(
                  left: isArabic ? Radius.zero : const Radius.circular(16),
                  right: isArabic ? const Radius.circular(16) : Radius.zero,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          item['date'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (item['is_accepted'] == 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: AppText(
                              isArabic ? 'مقبول' : 'Accepted',
                              style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        AppText(
                          '${item['start_time']} - ${item['end_time']}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.directions_car_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        AppText(
                          item['car_plate'] ?? '---',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
