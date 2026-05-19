import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/app_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/common/widgets/app_text.dart';
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
    return BlocProvider(
      create: (context) {
        final driverId = UserInfo().userId ?? 0;
        return getIt<MedicalTaskBloc>()
          ..add(MedicalTaskEvent.getTasks(driverId: driverId, status: status));
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getTitle()),
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
                    label: const Text('Accept All'),
                    icon: const Icon(Icons.done_all),
                  );
                }
                return const SizedBox.shrink();
              },
              orElse: () => const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }

  String _getTitle() {
    switch (status) {
      case 'NEW':
        return 'Pickup Samples';
      case 'COLLECTED':
        return 'Samples Placement';
      case 'OUT_FREEZER':
        return 'Drop Off Samples';
      default:
        return 'Tasks';
    }
  }
}

class _TaskCard extends StatelessWidget {
  final dynamic task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (task.status == 'NEW') {
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
                    child: AppText(
                      task.clientName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  _StatusBadge(confirmed: task.confirmedByDriver == 1),
                ],
              ),
              const Divider(height: 24),
              _LocationRow(
                icon: Icons.location_on_outlined,
                label: 'From',
                value: task.fromLocationName,
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              _LocationRow(
                icon: Icons.location_on,
                label: 'To',
                value: task.toLocationName,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  AppText('${task.date} - ${task.time}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: confirmed ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: AppText(
        confirmed ? 'CONFIRMED' : 'PENDING',
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
