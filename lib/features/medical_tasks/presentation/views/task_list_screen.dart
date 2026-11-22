import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/app_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/services/di/di_container.dart';
import '../../../../data/providers/user_info_provider.dart';
import '../../data/models/task_model.dart';
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
  final MedicalTask task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          isArabic ? 'مهمة #${task.id}' : 'Task #${task.id}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        AppText(
                          task.localizedClientName(isArabic) ?? l.noClient,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _LocationLine(
                          icon: Icons.circle,
                          iconSize: 8,
                          color: Colors.green,
                          text: task.localizedFromLocation(isArabic),
                        ),
                        const SizedBox(height: 4),
                        _LocationLine(
                          icon: Icons.location_on,
                          iconSize: 12,
                          color: Colors.red,
                          text: task.localizedToLocation(isArabic),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusBadge(confirmed: task.confirmedByDriver == 1),
                ],
              ),
              Divider(height: 28, color: Colors.grey.shade200),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: isArabic ? 'تاريخ المهمة: ' : 'Task Date: ',
                value: task.date ?? '',
                ltrValue: true,
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.access_time,
                label: isArabic ? 'وقت الاستلام: ' : 'Pickup Time: ',
                value: task.pickupTime ?? task.time ?? '',
                ltrValue: true,
              ),
              if (task.taskType?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.category_outlined,
                  label: isArabic ? 'نوع المهمة: ' : 'Task Type: ',
                  value: l.taskTypeLabel(task.taskType!),
                ),
              ],
              if (task.boxCount != null || task.sampleCount != null) ...[
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.inventory_2_outlined,
                  label: isArabic ? 'الصناديق / العينات: ' : 'Boxes / Samples: ',
                  value: '${task.boxCount ?? 0} / ${task.sampleCount ?? 0}',
                  ltrValue: true,
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

class _LocationLine extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color color;
  final String text;

  const _LocationLine({
    required this.icon,
    required this.iconSize,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Same height as one text line so the icon stays on the first line when the name wraps.
        SizedBox(
          width: 14,
          height: 18,
          child: Center(child: Icon(icon, size: iconSize, color: color)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: AppText(
            text,
            style: const TextStyle(fontSize: 12, height: 1.5, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool ltrValue;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.ltrValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueText = AppText(
      value,
      style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        AppText(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Flexible(
          child: ltrValue
              ? Directionality(textDirection: TextDirection.ltr, child: valueText)
              : valueText,
        ),
      ],
    );
  }
}
