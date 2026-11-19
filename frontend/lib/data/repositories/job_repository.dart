import 'dart:convert';
import 'package:get/get_connect/connect.dart';
import '../models/job_model.dart';

abstract class JobRepository {
  Future<List<JobModel>> getJobs();
  Future<JobModel?> getJobById(String id);
  Future<bool> triggerCollection();
}

class ApiJobRepository extends GetConnect implements JobRepository {
  final String serverUrl;

  ApiJobRepository({String? serverUrl})
      : serverUrl = serverUrl ?? 'http://127.0.0.1:8000' {
    httpClient.baseUrl = this.serverUrl;
    httpClient.timeout = const Duration(seconds: 8);
  }

  @override
  Future<List<JobModel>> getJobs() async {
    Response response;
    try {
      response = await get('/api/v1/jobs?limit=100');
    } catch (e) {
      throw Exception('Disconnected: Could not reach backend server at $serverUrl. ($e)');
    }

    if (response.hasError) {
      final statusCode = response.statusCode ?? 0;
      final statusText = response.statusText ?? 'Unknown error';
      throw Exception(
        'Disconnected: Server returned status $statusCode ($statusText) from $serverUrl.',
      );
    }

    dynamic data = response.body;
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {}
    }

    if (data is Map<String, dynamic> && data['items'] is List) {
      final items = data['items'] as List;
      return items
          .map((json) => JobModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  @override
  Future<JobModel?> getJobById(String id) async {
    Response response;
    try {
      response = await get('/api/v1/jobs/$id');
    } catch (e) {
      throw Exception('Disconnected: Could not reach backend server at $serverUrl.');
    }

    if (response.hasError || response.body == null) {
      return null;
    }

    dynamic data = response.body;
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {}
    }

    if (data is Map<String, dynamic>) {
      return JobModel.fromJson(data);
    }

    return null;
  }

  @override
  Future<bool> triggerCollection() async {
    try {
      final response = await post('/api/v1/jobs/collect', {});
      return !response.hasError;
    } catch (_) {
      return false;
    }
  }
}
