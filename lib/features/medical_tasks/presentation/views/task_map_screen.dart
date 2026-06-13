import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/navigation/app_router.dart';
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

  double? _distanceInMeters;
  double? _driverLat;
  double? _driverLng;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _setupMarkers();
    _calculateDistance();
  }

  Future<void> _calculateDistance() async {
    try {
      final clientLat = _currentTask.fromLocationLat ?? 24.688629;
      final clientLng = _currentTask.fromLocationLng ?? 46.644596;
      
      // Get current location (fallback to some default if fails or no permission)
      Position? position;
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
           position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        } else {
           permission = await Geolocator.requestPermission();
           if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
             position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
           }
        }
      }

      final driverLat = position?.latitude ?? 24.671086;
      final driverLng = position?.longitude ?? 46.749398;

      final distance = Geolocator.distanceBetween(
        driverLat, driverLng, 
        clientLat, clientLng
      );
      
      if (mounted) {
        setState(() {
          _driverLat = driverLat;
          _driverLng = driverLng;
          _distanceInMeters = distance;
        });
      }
    } catch (e) {
      debugPrint("Error calculating distance: $e");
    }
  }

  void _openGoogleMaps(double lat, double lng) async {
    final url = 'http://maps.google.com/maps?daddr=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _setupMarkers() {
    final clientLat = _currentTask.fromLocationLat ?? 24.688629;
    final clientLng = _currentTask.fromLocationLng ?? 46.644596;
    final clientLoc = LatLng(clientLat, clientLng);

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('client'),
          position: clientLoc,
          infoWindow: InfoWindow(title: _currentTask.fromLocationName),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () => _openGoogleMaps(clientLat, clientLng),
        ),
      };
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
    
    Future.delayed(const Duration(milliseconds: 500), () {
      final clientLoc = LatLng(_currentTask.fromLocationLat ?? 24.688629, _currentTask.fromLocationLng ?? 46.644596);

      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: clientLoc, zoom: 14),
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
    final bool isConfirmed = _currentTask.driverConfirmFromLocation == 1 || _currentTask.driverConfirmFromLocation == '1';
    final bool isStarted = _currentTask.driverStartDate != null;

    String buttonText = '';
    if (!isConfirmed) {
      buttonText = isArabic ? 'تأكيد الوصول للموقع' : 'CONFIRM LOCATION';
    } else if (!isStarted) {
      buttonText = isArabic ? 'بدء المهمة' : 'START TASK';
    } else {
      buttonText = isArabic ? 'جمع العينات' : 'COLLECT SAMPLES';
    }
    
    return BlocConsumer<TaskMapCubit, TaskMapState>(
      listener: (context, state) {
        state.whenOrNull(
          success: (msg) {
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
            // Error is handled in builder now
          },
        );
      },
      builder: (context, state) {
        final isLoading = state.maybeWhen(loading: () => true, orElse: () => false);

        return Scaffold(
          extendBody: true,
          appBar: AppBar(
            title: AppText(isArabic ? 'خريطة المهمة' : 'Task Map'),
            centerTitle: true,
          ),
          body: GoogleMap(
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
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
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
                      if (_currentTask.otp != null && _currentTask.otp!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.security, color: AppColors.primary),
                              const SizedBox(width: 8),
                              AppText(
                                isArabic 
                                  ? 'رمز التحقق الخاص بالعميل: ${_currentTask.otp}' 
                                  : 'Client OTP: ${_currentTask.otp}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                        title: isArabic ? 'موقع العميل:' : 'Client Location:',
                        value: _currentTask.fromLocationName,
                      ),
                      
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.route, color: Colors.blue, size: 16),
                          const SizedBox(width: 8),
                          AppText(
                            isArabic ? 'المسافة:' : 'Distance:',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          AppText(
                            _distanceInMeters != null 
                              ? '${(_distanceInMeters! / 1000).toStringAsFixed(2)} KM'
                              : '...',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ],
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
                      
                      const SizedBox(height: 8),
                      AppElevatedButton(
                        text: buttonText,
                        isLoading: isLoading,
                        onPressed: () {
                          if (!isConfirmed) {
                            context.read<TaskMapCubit>().confirmLocation(
                              taskId: _currentTask.id,
                              locationId: _currentTask.fromLocation ?? 0,
                              lat: _driverLat ?? 24.671086, 
                              lng: _driverLng ?? 46.749398,
                            );
                          } else if (!isStarted) {
                            context.read<TaskMapCubit>().startTask(
                              taskId: _currentTask.id,
                              lat: _driverLat ?? 24.671086,
                              lng: _driverLng ?? 46.749398,
                            );
                          } else {
                            context.push(AppRouter.sampleCollection, extra: _currentTask);
                          }
                        },
                      ),
                      state.maybeWhen(
                        success: (msg) => Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AppText(
                                  msg,
                                  style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        error: (msg) => Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AppText(
                                  msg,
                                  style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
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
