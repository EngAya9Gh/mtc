import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/app_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/services/di/di_container.dart';
import '../../../../data/providers/user_info_provider.dart';
import '../bloc/medical_task_bloc.dart';
import '../bloc/medical_task_event.dart';
import '../bloc/medical_task_state.dart';

class TaskListScreen extends StatelessWidget {
  final String status;

  const TaskListScreen({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLocalizations.of(context).isArabic;
    return BlocProvider(
      create: (context) {
        final driverId = UserInfo().userId ?? 0;
        return getIt<MedicalTaskBloc>()
          ..add(MedicalTaskEvent.getTasks(driverId: driverId, status: status));
      },
      child: Scaffold(
        appBar: AppBar(
          title: AppText(_getTitle(isArabic)),
          centerTitle: true,
        ),
        body: BlocBuilder<MedicalTaskBloc, MedicalTaskState>(
          builder: (context, state) {
            return state.when(
              initial: () => const Center(child: CircularProgressIndicator()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (message) => Center(child: AppText(message, style: const TextStyle(color: Colors.red))),
              success: (tasks) {
                if (tasks.isEmpty) {
                  return const Center(child: AppText('No tasks found'));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    final driverId = UserInfo().userId ?? 0;
                    context.read<MedicalTaskBloc>().add(
                        MedicalTaskEvent.getTasks(driverId: driverId, status: status));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _TaskCard(task: task);
                    },
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: BlocBuilder<MedicalTaskBloc, MedicalTaskState>(
          builder: (context, state) {
            return state.maybeWhen(
              success: (tasks) {
                final unconfirmedTasks = tasks
                    .where((t) => t.confirmedByDriver == 0)
                    .map((t) => t.id)
                    .toList();
                if (unconfirmedTasks.isNotEmpty) {
                  return FloatingActionButton.extended(
                    onPressed: () {
                      final driverId = UserInfo().userId ?? 0;
                      context.read<MedicalTaskBloc>().add(
                          MedicalTaskEvent.confirmTasks(
                              taskIds: unconfirmedTasks,
                              driverId: driverId,
                              status: status));
                    },
                    label: AppText(isArabic ? 'قبول الكل' : 'Accept All'),
                    icon: const Icon(Icons.done_all),
                  );
                }
                return const SizedBox.shrink();
              },
              orElse: () => const SizedBox.shrink(),
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
  }

  String _getTitle(bool isArabic) {
    switch (status) {
      case 'NEW':
        return isArabic ? 'استلام العينات' : 'Pickup Samples';
      case 'COLLECTED':
        return isArabic ? 'إيداع العينات' : 'Samples Placement';
      case 'OUT_FREEZER':
        return isArabic ? 'تسليم العينات' : 'Drop Off Samples';
      default:
        return isArabic ? 'المهام' : 'Tasks';
    }
  }
}

class _TaskCard extends StatelessWidget {
  final dynamic task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLocalizations.of(context).isArabic;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (task.status == 'NEW') {
            if (task.confirmedByDriver == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isArabic 
                      ? 'يرجى قبول المهام أولاً للتمكن من البدء بها.' 
                      : 'Please accept tasks first to start them.'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            context.push(AppRouter.taskMap, extra: task);
          } else if (task.status == 'COLLECTED') {
            context.push(AppRouter.freezerOutBags, extra: task);
          } else if (task.status == 'OUT_FREEZER') {
            // context.push(AppRouter.deliveryLocation, extra: task);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          isArabic ? 'مهمة #${task.id}' : 'Task #${task.id}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        AppText(
                          task.clientName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.circle, size: 8, color: Colors.green),
                                const SizedBox(width: 6),
                                Expanded(child: AppText(task.fromLocationName, style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 10, color: Colors.red),
                                const SizedBox(width: 4),
                                Expanded(child: AppText(task.toLocationName, style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(confirmed: task.confirmedByDriver == 1),
                ],
              ),
              const Divider(height: 24),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      AppText(isArabic ? 'تاريخ المهمة: ' : 'Task Date: ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: AppText('${task.date ?? ''}', style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      AppText(isArabic ? 'وقت الاستلام: ' : 'Pickup Time: ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: AppText('${task.pickupTime ?? task.time ?? ''}', style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ],
              ),
              if (task.taskType != null && task.taskType.toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.category_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    AppText(isArabic ? 'نوع المهمة: ${task.taskType}' : 'Task Type: ${task.taskType}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
              if (task.boxCount != null || task.sampleCount != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    AppText(isArabic 
                        ? 'الصناديق: ${task.boxCount ?? 0}  |  العينات: ${task.sampleCount ?? 0}' 
                        : 'Boxes: ${task.boxCount ?? 0}  |  Samples: ${task.sampleCount ?? 0}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool confirmed;

  const _StatusBadge({required this.confirmed});

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLocalizations.of(context).isArabic;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: confirmed ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: AppText(
        confirmed 
            ? (isArabic ? 'مؤكد' : 'CONFIRMED') 
            : (isArabic ? 'قيد الانتظار' : 'PENDING'),
        style: TextStyle(
          color: confirmed ? Colors.blue : Colors.orange,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _LocationRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              AppText(value, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
