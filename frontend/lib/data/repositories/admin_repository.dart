import 'dart:convert';
import 'package:get/get_connect/connect.dart';
import '../models/admin_models.dart';

abstract class AdminRepository {
  Future<DashboardMetricsModel> getDashboardMetrics();
  Future<PaginatedAdminJobsModel> listJobs({
    int page = 1,
    int pageSize = 25,
    String? etlStatus,
    String? sourceName,
    String? search,
    double? maxConfidence,
  });
  Future<AdminJobDetailModel?> getJobDetail(String jobId);
  Future<AdminBulkActionResponse> retryFailedJobs({List<String>? jobIds});
  Future<AdminBulkActionResponse> reclassifyJobs({
    String? promptVersion,
    double? maxConfidence,
  });
  Future<AdminBulkActionResponse> purgeJobs({
    String? etlStatus,
    int? olderThanDays,
  });
  Future<AdminBulkActionResponse> deleteJob(String jobId);
  Future<AdminBulkActionResponse> triggerPipeline();
}

class ApiAdminRepository extends GetConnect implements AdminRepository {
  final String serverUrl;

  ApiAdminRepository({String? serverUrl})
      : serverUrl = serverUrl ?? 'http://127.0.0.1:8000' {
    httpClient.baseUrl = this.serverUrl;
    httpClient.timeout = const Duration(seconds: 12);
  }

  dynamic _parseResponse(Response response, String endpoint) {
    if (response.hasError) {
      final code = response.statusCode ?? 0;
      final statusText = response.statusText ?? 'Unknown error';
      String errorDetail = statusText;
      try {
        if (response.body is Map && response.body['detail'] != null) {
          errorDetail = response.body['detail'].toString();
        } else if (response.body is String) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['detail'] != null) {
            errorDetail = decoded['detail'].toString();
          }
        }
      } catch (_) {}
      throw Exception('Server error ($code) on $endpoint: $errorDetail');
    }

    dynamic data = response.body;
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {}
    }
    return data;
  }

  @override
  Future<DashboardMetricsModel> getDashboardMetrics() async {
    Response response;
    try {
      response = await get('/api/admin/dashboard');
    } catch (e) {
      throw Exception('Disconnected: Could not reach backend server at $serverUrl. ($e)');
    }

    final data = _parseResponse(response, '/api/admin/dashboard');
    if (data is Map<String, dynamic>) {
      return DashboardMetricsModel.fromJson(data);
    }
    throw Exception('Invalid metrics response format from server.');
  }

  @override
  Future<PaginatedAdminJobsModel> listJobs({
    int page = 1,
    int pageSize = 25,
    String? etlStatus,
    String? sourceName,
    String? search,
    double? maxConfidence,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (etlStatus != null && etlStatus.isNotEmpty && etlStatus != 'ALL') {
      params['etl_status'] = etlStatus;
    }
    if (sourceName != null && sourceName.isNotEmpty && sourceName != 'ALL') {
      params['source_name'] = sourceName;
    }
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (maxConfidence != null) {
      params['max_confidence'] = maxConfidence.toString();
    }

    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    Response response;
    try {
      response = await get('/api/admin/jobs?$queryString');
    } catch (e) {
      throw Exception('Disconnected: Could not reach backend server at $serverUrl. ($e)');
    }

    final data = _parseResponse(response, '/api/admin/jobs');
    if (data is Map<String, dynamic>) {
      return PaginatedAdminJobsModel.fromJson(data);
    }
    throw Exception('Invalid job list response format from server.');
  }

  @override
  Future<AdminJobDetailModel?> getJobDetail(String jobId) async {
    Response response;
    try {
      response = await get('/api/admin/jobs/$jobId');
    } catch (e) {
      throw Exception('Disconnected: Could not reach backend server at $serverUrl. ($e)');
    }

    if (response.statusCode == 404) {
      return null;
    }

    final data = _parseResponse(response, '/api/admin/jobs/$jobId');
    if (data is Map<String, dynamic>) {
      return AdminJobDetailModel.fromJson(data);
    }
    return null;
  }

  @override
  Future<AdminBulkActionResponse> retryFailedJobs({List<String>? jobIds}) async {
    Response response;
    final body = jobIds != null && jobIds.isNotEmpty ? {'job_ids': jobIds} : {};
    try {
      response = await post('/api/admin/jobs/retry-failed', body);
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }

    final data = _parseResponse(response, '/api/admin/jobs/retry-failed');
    if (data is Map<String, dynamic>) {
      return AdminBulkActionResponse.fromJson(data);
    }
    throw Exception('Invalid retry response format from server.');
  }

  @override
  Future<AdminBulkActionResponse> reclassifyJobs({
    String? promptVersion,
    double? maxConfidence,
  }) async {
    final params = <String, String>{};
    if (promptVersion != null && promptVersion.isNotEmpty) {
      params['prompt_version'] = promptVersion;
    }
    if (maxConfidence != null) {
      params['max_confidence'] = maxConfidence.toString();
    }
    final qs = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final path = qs.isNotEmpty ? '/api/admin/jobs/reclassify?$qs' : '/api/admin/jobs/reclassify';

    Response response;
    try {
      response = await post(path, {});
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }

    final data = _parseResponse(response, '/api/admin/jobs/reclassify');
    if (data is Map<String, dynamic>) {
      return AdminBulkActionResponse.fromJson(data);
    }
    throw Exception('Invalid reclassify response format from server.');
  }

  @override
  Future<AdminBulkActionResponse> purgeJobs({
    String? etlStatus,
    int? olderThanDays,
  }) async {
    final params = <String, String>{};
    if (etlStatus != null && etlStatus.isNotEmpty) {
      params['etl_status'] = etlStatus;
    }
    if (olderThanDays != null) {
      params['older_than_days'] = olderThanDays.toString();
    }
    final qs = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final path = qs.isNotEmpty ? '/api/admin/jobs/purge?$qs' : '/api/admin/jobs/purge';

    Response response;
    try {
      response = await delete(path);
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }

    final data = _parseResponse(response, '/api/admin/jobs/purge');
    if (data is Map<String, dynamic>) {
      return AdminBulkActionResponse.fromJson(data);
    }
    throw Exception('Invalid purge response format from server.');
  }

  @override
  Future<AdminBulkActionResponse> deleteJob(String jobId) async {
    Response response;
    try {
      response = await delete('/api/admin/jobs/$jobId');
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }

    final data = _parseResponse(response, '/api/admin/jobs/$jobId');
    if (data is Map<String, dynamic>) {
      return AdminBulkActionResponse.fromJson(data);
    }
    throw Exception('Invalid delete response format from server.');
  }

  @override
  Future<AdminBulkActionResponse> triggerPipeline() async {
    Response response;
    try {
      response = await post('/api/admin/pipeline/trigger', {});
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }

    final data = _parseResponse(response, '/api/admin/pipeline/trigger');
    if (data is Map<String, dynamic>) {
      return AdminBulkActionResponse.fromJson(data);
    }
    throw Exception('Invalid pipeline trigger response format from server.');
  }
}

