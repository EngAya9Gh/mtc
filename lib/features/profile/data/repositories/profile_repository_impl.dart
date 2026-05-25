import '../../domain/repositories/profile_repository.dart';
import '../data_sources/profile_remote_data_source.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<ProfileModel> getProfile(int driverId) {
    return _remoteDataSource.getProfile(driverId);
  }
}
