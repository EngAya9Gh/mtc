import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../../../../core/common/widgets/app_elevated_button.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/services/di/di_container.dart';
import '../../data/models/task_model.dart';
import '../bloc/task_map_cubit.dart';
import '../bloc/task_map_state.dart';

class TaskMapScreen extends StatelessWidget {
  final MedicalTask task;

  const TaskMapScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TaskMapCubit>(),
      child: _TaskMapScreenView(task: task),
    );
  }
}

class _TaskMapScreenView extends StatefulWidget {
  final MedicalTask task;

  const _TaskMapScreenView({required this.task});

  @override
  State<_TaskMapScreenView> createState() => _TaskMapScreenViewState();
}

class _TaskMapScreenViewState extends State<_TaskMapScreenView> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  Set<Marker> _markers = {};
  late MedicalTask _currentTask;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _setupMarkers();
  }

  void _setupMarkers() {
    final fromLoc = LatLng(_currentTask.fromLocationLat ?? 24.671086, _currentTask.fromLocationLng ?? 46.749398);
    final toLoc = LatLng(_currentTask.toLocationLat ?? 24.688629955350198, _currentTask.toLocationLng ?? 46.644596757671906);

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('from'),
          position: fromLoc,
          infoWindow: InfoWindow(title: _currentTask.fromLocationName),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('to'),
          position: toLoc,
          infoWindow: InfoWindow(title: _currentTask.toLocationName),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
    
    Future.delayed(const Duration(milliseconds: 500), () {
      final fromLoc = LatLng(_currentTask.fromLocationLat ?? 24.671086, _currentTask.fromLocationLng ?? 46.749398);
      final toLoc = LatLng(_currentTask.toLocationLat ?? 24.688629955350198, _currentTask.toLocationLng ?? 46.644596757671906);

      controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: fromLoc.latitude < toLoc.latitude ? fromLoc : toLoc,
            northeast: fromLoc.latitude > toLoc.latitude ? fromLoc : toLoc,
          ),
          50.0,
        ),
      );
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isArabic = l.isArabic;
    
    // Determine button state based on task logic
    final bool isConfirmed = _currentTask.driverConfirmFromLocation == 1;
    final bool isStarted = _currentTask.driverStartDate != null;

    String buttonText = '';
    if (!isConfirmed) {
      buttonText = isArabic ? 'تأكيد الوصول للموقع' : 'CONFIRM LOCATION';
    } else if (!isStarted) {
      buttonText = isArabic ? 'بدء المهمة' : 'START TASK';
    } else {
      buttonText = isArabic ? 'إعدادات العينة' : 'Setting SAMPLES';
    }
    
    return BlocConsumer<TaskMapCubit, TaskMapState>(
      listener: (context, state) {
        state.whenOrNull(
          success: (msg) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.green),
            );
            
            // Update local task state to refresh UI
            setState(() {
              if (!isConfirmed) {
                _currentTask = _currentTask.copyWith(driverConfirmFromLocation: 1);
              } else if (!isStarted) {
                _currentTask = _currentTask.copyWith(driverStartDate: DateTime.now().toString());
              }
            });
          },
          error: (msg) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.red),
            );
          },
        );
      },
      builder: (context, state) {
        final isLoading = state.maybeWhen(loading: () => true, orElse: () => false);

        return Scaffold(
          appBar: AppBar(
            title: AppText(isArabic ? 'خريطة المهمة' : 'Task Map'),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: CameraPosition(
                  target: LatLng(_currentTask.fromLocationLat ?? 24.671086, _currentTask.fromLocationLng ?? 46.749398),
                  zoom: 12,
                ),
                markers: _markers,
                onMapCreated: _onMapCreated,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
              ),
              
              // Bottom Details Card
              Positioned(
                left: 16,
                right: 16,
                bottom: 30,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: AppText(
                              _currentTask.clientName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: AppText(
                              'Task #${_currentTask.id}',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      
                      // Locations
                      _LocationRow(
                        icon: Icons.circle,
                        color: Colors.green,
                        title: isArabic ? 'من:' : 'From:',
                        value: _currentTask.fromLocationName,
                      ),
                      const SizedBox(height: 12),
                      _LocationRow(
                        icon: Icons.location_on,
                        color: Colors.red,
                        title: isArabic ? 'إلى:' : 'To:',
                        value: _currentTask.toLocationName,
                      ),
                      
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          AppText(
                            '${_currentTask.date ?? ''} - ${_currentTask.pickupTime ?? _currentTask.time ?? ''}',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _makePhoneCall('0500000000'), // Replace with actual phone if available
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.call, color: Colors.green, size: 20),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      AppElevatedButton(
                        text: buttonText,
                        isLoading: isLoading,
                        onPressed: () {
                          if (!isConfirmed) {
                            context.read<TaskMapCubit>().confirmLocation(
                              taskId: _currentTask.id,
                              locationId: _currentTask.fromLocation ?? 0,
                              lat: 24.671086, // In real app, use geolocator
                              lng: 46.749398,
                            );
                          } else if (!isStarted) {
                            context.read<TaskMapCubit>().startTask(
                              taskId: _currentTask.id,
                              lat: 24.671086,
                              lng: 46.749398,
                            );
                          } else {
                            context.push('/first_sample_info', extra: _currentTask);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;

  const _LocationRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        AppText(
          title,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: AppText(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
