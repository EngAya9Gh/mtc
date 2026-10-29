import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../navigation/app_router.dart';
import '../../../data/providers/user_info_provider.dart';
import '../../../features/medical_tasks/data/models/task_model.dart';
import '../../../features/medical_tasks/domain/repositories/task_repository.dart';

/// Opens the screen that matches a tapped push notification.
/// The backend payload is documented in PUSH_NOTIFICATIONS_AR.md.
class NotificationNavigator {
  NotificationNavigator._();

  static Future<void> open(Map<String, dynamic> data) async {
    final type = data['notification_type'];
    final taskId = int.tryParse('${data['task_id'] ?? ''}');

    switch (type) {
      case 'new_task':
      case 'task_accepted':
      case 'task_started':
      case 'pickup_delayed':
      case 'dropoff_delayed':
      case 'placement_delayed':
      case 'delivery_delayed':
      case 'swap_created':
      case 'swap_rejected':
        await _openTask(taskId, data['task_object']);
        break;
      case 'new_task_generic':
        AppRouter.router.push('/task_list/NEW');
        break;
      case 'swap_request':
        AppRouter.router.push('/swap_tasks');
        break;
      case 'swap_accepted':
        // The task now belongs to the other driver, so only the task list is opened
        AppRouter.router.push(AppRouter.taskType);
        break;
      default:
        // attendance_late (no attendance screen yet), swap_received and unknown types
        // only open the app.
        debugPrint('No navigation for notification_type: $type');
    }
  }

  /// Opens the task on the screen of its current step.
  static Future<void> _openTask(int? taskId, dynamic taskObject) async {
    // Swaps of several tasks arrive without a task_id
    if (taskId == null) {
      AppRouter.router.push(AppRouter.taskType);
      return;
    }

    final status = _statusFrom(taskObject);
    switch (status) {
      case 'IN_FREEZER':
        AppRouter.router.push(AppRouter.pullOutTasks);
        return;
      case 'OUT_FREEZER':
        AppRouter.router.push(AppRouter.dropOffTasks);
        return;
      case 'CLOSED':
        return;
    }

    final task = await _findTask(
      taskId,
      status == 'COLLECTED' ? ['COLLECTED', 'NEW'] : ['NEW', 'COLLECTED'],
    );

    if (task == null) {
      AppRouter.router.push(AppRouter.taskType);
    } else if (task.status == 'COLLECTED') {
      AppRouter.router.push(AppRouter.freezerOutBags, extra: task);
    } else if (task.confirmedByDriver == 0) {
      // Tasks must be accepted from the list before they can be started
      AppRouter.router.push('/task_list/NEW');
    } else {
      AppRouter.router.push(AppRouter.taskMap, extra: task);
    }
  }

  /// There is no endpoint for a single task, so it's looked up in the driver's task lists.
  static Future<MedicalTask?> _findTask(int taskId, List<String> statuses) async {
    final driverId = UserInfo().userId;
    if (driverId == null) return null;

    final repository = GetIt.instance<TaskRepository>();
    for (final status in statuses) {
      try {
        final response = await repository.getTasks(driverId, status);
        for (final task in response.data) {
          if (task.id == taskId) return task;
        }
      } catch (e) {
        debugPrint('Task lookup failed for $status: $e');
      }
    }
    return null;
  }

  /// Status of the task when the notification was sent, read from the task_object JSON string.
  static String? _statusFrom(dynamic taskObject) {
    if (taskObject is! String || taskObject.isEmpty) return null;
    try {
      final json = jsonDecode(taskObject);
      return json is Map ? json['status']?.toString() : null;
    } catch (e) {
      return null;
    }
  }
}
