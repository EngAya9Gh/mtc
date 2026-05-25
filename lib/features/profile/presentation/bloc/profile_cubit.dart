import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../../data/providers/user_info_provider.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _repository;

  ProfileCubit(this._repository) : super(const ProfileState.initial());

  Future<void> fetchProfile() async {
    emit(const ProfileState.loading());
    try {
      final driverId = UserInfo().userId;
      if (driverId == null) {
        emit(const ProfileState.error('لم يتم العثور على رقم السائق'));
        return;
      }
      final profile = await _repository.getProfile(driverId);
      emit(ProfileState.loaded(profile));
    } catch (e) {
      emit(ProfileState.error(e.toString()));
    }
  }
}
