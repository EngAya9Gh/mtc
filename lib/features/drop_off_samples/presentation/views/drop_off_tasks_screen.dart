import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_loader.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/services/di/di_container.dart';
import '../../../../core/navigation/app_router.dart';
import '../bloc/drop_off_cubit.dart';
import '../bloc/drop_off_state.dart';
import '../../../samples_pull_out/data/models/client_task_model.dart';

class DropOffTasksScreen extends StatelessWidget {
  const DropOffTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DropOffCubit>()..getDropOffTasks(),
      child: const _DropOffTasksScreenView(),
    );
  }
}

class _DropOffTasksScreenView extends StatelessWidget {
  const _DropOffTasksScreenView();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: AppText(isArabic ? 'تسليم العينات' : 'Drop Off Samples'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: BlocConsumer<DropOffCubit, DropOffState>(
        listener: (context, state) {
          state.whenOrNull(
            error: (msg) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: AppText(msg), backgroundColor: Colors.red),
              );
            },
          );
        },
        builder: (context, state) {
          return state.maybeWhen(
            loading: (msg) => const Center(child: AppLoader()),
            tasksLoaded: (tasks) {
              if (tasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      AppText(
                        isArabic ? 'لا توجد عينات حالياً للتسليم' : 'No samples ready for drop off',
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<DropOffCubit>().getDropOffTasks();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final destinationGroup = tasks[index];
                    return _DropOffDestinationCard(
                      destination: destinationGroup,
                      isArabic: isArabic,
                      onTap: () {
                        context.read<DropOffCubit>().proceedToScanBags(destinationGroup);
                        context.push(
                          AppRouter.dropOffScanBags,
                          extra: context.read<DropOffCubit>(), // Pass cubit to maintain state
                        );
                      },
                    );
                  },
                ),
              );
            },
            orElse: () => const Center(child: AppLoader()),
          );
        },
      ),
    );
  }
}

class _DropOffDestinationCard extends StatelessWidget {
  final ClientTaskModel destination;
  final bool isArabic;
  final VoidCallback onTap;

  const _DropOffDestinationCard({
    required this.destination,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    int totalBags = 0;
    if (destination.tasks != null) {
      for (var t in destination.tasks!) {
        if (t.samplesSummary != null) {
          totalBags += t.samplesSummary!.length;
        }
      }
    }
    
    final destinationName = isArabic 
        ? (destination.arabicName ?? destination.name ?? 'وجهة غير معروفة')
        : (destination.englishName ?? destination.name ?? 'Unknown Destination');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: AppText(
                      destinationName,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppText(
                      '${destination.tasks?.length ?? 0} ${isArabic ? "مهام" : "Tasks"}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.outbox_rounded, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  AppText(
                    '${isArabic ? "إجمالي الأكياس للتسليم:" : "Total Bags to Drop Off:"} $totalBags',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
