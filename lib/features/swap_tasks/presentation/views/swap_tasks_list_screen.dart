import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_loader.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../bloc/swap_tasks_cubit.dart';
import '../bloc/swap_tasks_state.dart';
import '../../data/models/swap_task_model.dart';
import '../../../../core/navigation/app_router.dart';

class SwapTasksListScreen extends StatefulWidget {
  const SwapTasksListScreen({super.key});

  @override
  State<SwapTasksListScreen> createState() => _SwapTasksListScreenState();
}

class _SwapTasksListScreenState extends State<SwapTasksListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SwapTasksCubit>().getSwapTasks();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        centerTitle: true,
        title: AppText(
          isArabic ? 'مهام التبادل' : 'Swap Tasks',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<SwapTasksCubit, SwapTasksState>(
        listener: (context, state) {
          state.maybeWhen(
            error: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: AppText(message), backgroundColor: Colors.red),
              );
            },
            actionSuccess: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: AppText(message), backgroundColor: Colors.green),
              );
            },
            scanningBags: (selectedTask, remaining, scanned, allScanned) {
              // Navigate to scan bags screen if state becomes scanning
              context.push('/swap_scan_bags', extra: context.read<SwapTasksCubit>());
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          return state.maybeWhen(
            loading: (msg) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLoader(),
                  const SizedBox(height: 16),
                  AppText(msg, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            loaded: (tasks) {
              if (tasks.isEmpty) {
                return Center(
                  child: AppText(
                    isArabic ? 'لا يوجد مهام تبادل حالياً' : 'No swap tasks available',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                );
              }

              return Column(
                children: [
                  // Accept All Button Area
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<SwapTasksCubit>().acceptAllTasks(tasks);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: AppText(
                        isArabic ? 'قبول الكل' : 'Accept All',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // Tasks List
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: tasks.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildSwapTaskCard(context, tasks[index], isArabic);
                      },
                    ),
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  Widget _buildSwapTaskCard(BuildContext context, SwapTaskModel task, bool isArabic) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Trigger scan mode
            context.read<SwapTasksCubit>().proceedToScanBags(task);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              isArabic ? 'مهمة تبادل #${task.id}' : 'Swap Task #${task.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF263238),
                              ),
                            ),
                            AppText(
                              task.swapUserName ?? 'Unknown Driver',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AppText(
                        isArabic ? 'قيد الانتظار' : 'Pending',
                        style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        context.read<SwapTasksCubit>().rejectTask(task.id);
                      },
                      icon: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
                      label: AppText(
                        isArabic ? 'رفض' : 'Reject',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<SwapTasksCubit>().acceptAllTasks([task]);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: AppText(
                        isArabic ? 'قبول' : 'Accept',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
