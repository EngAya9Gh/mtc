
import 'package:dio/dio.dart';
void main() async {
  final dio = Dio();
  dio.interceptors.add(LogInterceptor(requestBody: true));
  try {
    await dio.post('http://localhost:8000/api/samples/container/bags/add', data: [{'task_id': 1}]);
  } catch(e) { print(e); }
}
