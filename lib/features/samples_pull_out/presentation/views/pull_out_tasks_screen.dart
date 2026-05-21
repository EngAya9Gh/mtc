import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_loader.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/services/di/di_container.dart';
import '../../../../core/navigation/app_router.dart';
import '../bloc/pull_out_cubit.dart';
import '../bloc/pull_out_state.dart';
import '../../data/models/client_task_model.dart';

class PullOutTasksScreen extends StatelessWidget {
  const PullOutTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<PullOutCubit>()..loadTasks(),
      child: const _PullOutTasksScreenView(),
    );
  }
}

class _PullOutTasksScreenView extends StatelessWidget {
  const _PullOutTasksScreenView();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: AppText(isArabic ? 'سحب العينات من الحاوية' : 'Samples Pull Out'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: BlocConsumer<PullOutCubit, PullOutState>(
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
                        isArabic ? 'لا توجد مهام حالياً في الثلاجات للسحب' : 'No tasks in freezers ready for pull out',
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<PullOutCubit>().loadTasks();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final destinationGroup = tasks[index];
                    return _DestinationCard(
                      destination: destinationGroup,
                      isArabic: isArabic,
                      onTap: () {
                        context.push(
                          AppRouter.pullOutScanContainer,
                          extra: destinationGroup,
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

class _DestinationCard extends StatelessWidget {
  final ClientTaskModel destination;
  final bool isArabic;
  final VoidCallback onTap;

  const _DestinationCard({
    required this.destination,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    int totalBags = 0;
    for (var t in destination.tasks) {
      totalBags += t.samplesSummary.length;
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
                      '${destination.taskIds.length} ${isArabic ? "مهام" : "Tasks"}',
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
                    '${isArabic ? "إجمالي الأكياس للسحب:" : "Total Bags to Pull Out:"} $totalBags',
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
