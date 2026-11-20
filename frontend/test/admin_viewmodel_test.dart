import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:frontend/core/config/env_config.dart';
import 'package:frontend/data/models/admin_models.dart';
import 'package:frontend/data/repositories/admin_repository.dart';
import 'package:frontend/features/admin/viewmodels/admin_viewmodel.dart';

class MockAdminRepository implements AdminRepository {
  DashboardMetricsModel metricsToReturn = DashboardMetricsModel(
    pipelineLive: PipelineLiveStatus(batchRunning: false, llmQueueDepth: 3),
    funnel: FunnelMetrics(
      totalJobs: 15,
      raw: 2,
      filteredPendingLlm: 3,
      classified: 9,
      failed: 1,
    ),
    llmEconomics: LLMEconomics(
      totalCostUsd: 0.0452,
      costLast24hUsd: 0.0125,
      avgCostPerJobUsd: 0.0031,
      totalInputTokens: 120500,
      totalOutputTokens: 38400,
    ),
    quality: QualityMetrics(
      avgConfidence: 0.925,
      lowConfidenceJobs: 2,
      staleJobsOver14d: 0,
    ),
    bySource: [
      SourceMetric(
        sourceName: 'Greenhouse',
        total: 10,
        classified: 8,
        failed: 1,
        avgConfidence: 0.94,
      ),
      SourceMetric(
        sourceName: 'Lever',
        total: 5,
        classified: 1,
        failed: 0,
        avgConfidence: 0.91,
      ),
    ],
    byPromptVersion: [
      PromptVersionMetric(
        llmModel: 'gemini-1.5-flash',
        promptVersion: 'v1.0.0',
        jobsProcessed: 9,
        avgConfidence: 0.925,
        avgCostUsd: 0.0031,
      ),
    ],
    topErrors: [
      TopErrorMetric(error: 'LLM Rate limit reached', count: 1),
    ],
  );

  List<AdminJobListItem> jobsList = [
    AdminJobListItem(
      id: '00000000-0000-0000-0000-000000000001',
      companyName: 'Stripe',
      rawTitle: 'Senior Backend Engineer',
      rawLocation: 'San Francisco, CA',
      sourceName: 'Greenhouse',
      etlStatus: 'CLASSIFIED',
      inferredRole: 'Backend Engineer',
      inferredCity: 'San Francisco',
      inferredWorkMode: 'Hybrid',
      inferredExperience: 'Senior',
      classificationConfidence: 0.95,
      processingAttempts: 1,
      llmCostUsd: 0.0032,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    AdminJobListItem(
      id: '00000000-0000-0000-0000-000000000002',
      companyName: 'Figma',
      rawTitle: 'Frontend Engineer',
      sourceName: 'Lever',
      etlStatus: 'FAILED',
      classificationConfidence: 0.50,
      processingAttempts: 3,
      lastError: 'Syntax error parsing LLM response',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Future<DashboardMetricsModel> getDashboardMetrics() async {
    return metricsToReturn;
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
    var filtered = List<AdminJobListItem>.from(jobsList);
    if (etlStatus != null && etlStatus != 'ALL') {
      filtered = filtered.where((j) => j.etlStatus == etlStatus).toList();
    }
    if (sourceName != null && sourceName != 'ALL') {
      filtered = filtered.where((j) => j.sourceName == sourceName).toList();
    }
    if (search != null && search.isNotEmpty) {
      filtered = filtered
          .where((j) =>
              j.rawTitle.toLowerCase().contains(search.toLowerCase()) ||
              j.companyName.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }
    if (maxConfidence != null) {
      filtered = filtered
          .where((j) =>
              (j.classificationConfidence ?? 0.0) <= maxConfidence)
          .toList();
    }

    return PaginatedAdminJobsModel(
      items: filtered,
      total: filtered.length,
      page: page,
      pageSize: pageSize,
      totalPages: 1,
    );
  }

  @override
  Future<AdminJobDetailModel?> getJobDetail(String jobId) async {
    final item = jobsList.firstWhere((j) => j.id == jobId);
    return AdminJobDetailModel(
      id: item.id,
      companyName: item.companyName,
      rawTitle: item.rawTitle,
      sourceName: item.sourceName,
      etlStatus: item.etlStatus,
      inferredRole: item.inferredRole,
      classificationConfidence: item.classificationConfidence,
      processingAttempts: item.processingAttempts,
      llmCostUsd: item.llmCostUsd,
      lastError: item.lastError,
      sourceUrl: 'https://careers.stripe.com/job/1',
      description: 'We are seeking a senior backend engineer...',
      inferredSkills: ['Python', 'PostgreSQL', 'FastAPI'],
      llmModel: 'gemini-1.5-flash',
      promptVersion: 'v1.0.0',
      llmInputTokens: 1400,
      llmOutputTokens: 250,
    );
  }

  @override
  Future<AdminBulkActionResponse> retryFailedJobs({List<String>? jobIds}) async {
    return AdminBulkActionResponse(
      affectedCount: jobIds?.length ?? 1,
      message: 'Retry scheduled.',
    );
  }

  @override
  Future<AdminBulkActionResponse> reclassifyJobs({
    String? promptVersion,
    double? maxConfidence,
  }) async {
    return AdminBulkActionResponse(
      affectedCount: 2,
      message: 'Reclassification queued.',
    );
  }

  @override
  Future<AdminBulkActionResponse> purgeJobs({
    String? etlStatus,
    int? olderThanDays,
  }) async {
    return AdminBulkActionResponse(
      affectedCount: 1,
      message: 'Purged matching records.',
    );
  }

  @override
  Future<AdminBulkActionResponse> deleteJob(String jobId) async {
    jobsList.removeWhere((j) => j.id == jobId);
    return AdminBulkActionResponse(
      affectedCount: 1,
      message: 'Job deleted.',
    );
  }

  @override
  Future<AdminBulkActionResponse> triggerPipeline() async {
    return AdminBulkActionResponse(
      affectedCount: 1,
      message: 'Pipeline batch run started.',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAdminRepository mockRepo;
  late AdminViewModel viewModel;

  setUp(() {
    Get.reset();
    EnvConfig.setMockValues({'ADMIN_USERNAME': 'admin', 'ADMIN_PASSWORD': 'admin'});
    mockRepo = MockAdminRepository();
    Get.put<AdminRepository>(mockRepo);
    viewModel = AdminViewModel(repository: mockRepo);
    viewModel.isAuthenticated.value = true;
  });

  tearDown(() {
    viewModel.onClose();
    Get.reset();
  });

  group('Admin Authentication & EnvConfig Tests', () {
    test('EnvConfig parses key value pairs from string', () {
      EnvConfig.parse('''
# Comment line
ADMIN_USERNAME="admin"
ADMIN_PASSWORD='secretpassword'
OTHER_KEY=12345
''');
      expect(EnvConfig.adminUsername, 'admin');
      expect(EnvConfig.adminPassword, 'secretpassword');
      expect(EnvConfig.get('OTHER_KEY'), '12345');
    });

    test('AdminViewModel login authenticates valid admin and rejects invalid', () {
      EnvConfig.setMockValues({'ADMIN_USERNAME': 'admin', 'ADMIN_PASSWORD': 'admin'});
      final vm = AdminViewModel(repository: mockRepo);

      expect(vm.isAuthenticated.value, isFalse);
      final failed = vm.login('wrong', 'admin');
      expect(failed, isFalse);
      expect(vm.isAuthenticated.value, isFalse);
      expect(vm.authError.value, isNotNull);

      final success = vm.login('admin', 'admin');
      expect(success, isTrue);
      expect(vm.isAuthenticated.value, isTrue);
      expect(vm.authError.value, isNull);

      vm.logout();
      expect(vm.isAuthenticated.value, isFalse);
    });
  });

  group('Admin Model Serialization Tests', () {
    test('DashboardMetricsModel fromJson correctly parses nested models', () {
      final json = {
        'pipeline_live': {'batch_running': true, 'llm_queue_depth': 5},
        'funnel': {
          'total_jobs': 20,
          'raw': 2,
          'filtered_pending_llm': 4,
          'classified': 13,
          'failed': 1,
        },
        'llm_economics': {
          'total_cost_usd': 0.12,
          'cost_last_24h_usd': 0.05,
          'avg_cost_per_job_usd': 0.006,
          'total_input_tokens': 50000,
          'total_output_tokens': 12000,
        },
        'quality': {
          'avg_confidence': 0.88,
          'low_confidence_jobs': 3,
          'stale_jobs_over_14d': 0,
        },
        'by_source': [
          {
            'source_name': 'Greenhouse',
            'total': 15,
            'classified': 10,
            'failed': 1,
            'avg_confidence': 0.90,
          }
        ],
        'by_prompt_version': [
          {
            'llm_model': 'gemini-1.5-flash',
            'prompt_version': 'v1.0.0',
            'jobs_processed': 10,
            'avg_confidence': 0.90,
            'avg_cost_usd': 0.005,
          }
        ],
        'top_errors': [
          {'error': 'Connection timed out', 'count': 2}
        ],
      };

      final model = DashboardMetricsModel.fromJson(json);
      expect(model.pipelineLive.batchRunning, isTrue);
      expect(model.pipelineLive.llmQueueDepth, 5);
      expect(model.funnel.totalJobs, 20);
      expect(model.llmEconomics.totalCostUsd, 0.12);
      expect(model.quality.avgConfidence, 0.88);
      expect(model.bySource.first.sourceName, 'Greenhouse');
      expect(model.byPromptVersion.first.llmModel, 'gemini-1.5-flash');
      expect(model.topErrors.first.error, 'Connection timed out');
      expect(model.topErrors.first.count, 2);
    });

    test('AdminJobDetailModel parses all fields including skills and payload', () {
      final json = {
        'id': '11111111-1111-1111-1111-111111111111',
        'company_name': 'Google',
        'raw_title': 'Software Engineer III',
        'source_name': 'Direct',
        'etl_status': 'CLASSIFIED',
        'source_url': 'https://google.com/jobs/123',
        'description': 'Build distributed systems at scale.',
        'raw_payload': {'title': 'SWE III', 'location': 'Mountain View'},
        'inferred_skills': ['Go', 'Kubernetes', 'gRPC'],
        'llm_model': 'gemini-1.5-flash',
        'llm_cost_usd': 0.0042,
      };

      final detail = AdminJobDetailModel.fromJson(json);
      expect(detail.id, '11111111-1111-1111-1111-111111111111');
      expect(detail.companyName, 'Google');
      expect(detail.inferredSkills, contains('Kubernetes'));
      expect(detail.rawPayload?['title'], 'SWE III');
      expect(detail.llmCostUsd, 0.0042);
    });
  });

  group('AdminViewModel Reactive Operations Tests', () {
    test('Initializes and fetches dashboard metrics and jobs', () async {
      await viewModel.refreshAll();
      expect(viewModel.metrics.value, isNotNull);
      expect(viewModel.metrics.value!.funnel.totalJobs, 15);
      expect(viewModel.jobs.length, 2);
      expect(viewModel.totalJobs.value, 2);
      expect(viewModel.isBatchRunning, isFalse);
      expect(viewModel.llmQueueDepth, 3);
    });

    test('Filter by status reactively limits jobs', () async {
      viewModel.onStatusChanged('CLASSIFIED');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(viewModel.selectedStatus.value, 'CLASSIFIED');
      expect(viewModel.jobs.length, 1);
      expect(viewModel.jobs.first.companyName, 'Stripe');
    });

    test('Filter by keyword search filters jobs', () async {
      viewModel.onSearchChanged('Figma');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(viewModel.jobs.length, 1);
      expect(viewModel.jobs.first.companyName, 'Figma');
    });

    test('Low confidence toggle filters jobs below 80%', () async {
      viewModel.toggleLowConfidenceOnly(true);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(viewModel.lowConfidenceOnly.value, isTrue);
      expect(viewModel.jobs.length, 1);
      expect(viewModel.jobs.first.companyName, 'Figma');
      expect(viewModel.jobs.first.classificationConfidence, 0.50);
    });

    test('Inspect job fetches detail and opens inspector', () async {
      await viewModel.inspectJob('00000000-0000-0000-0000-000000000001');
      expect(viewModel.selectedJobDetail.value, isNotNull);
      expect(viewModel.selectedJobDetail.value!.rawTitle, 'Senior Backend Engineer');
      expect(viewModel.selectedJobDetail.value!.inferredSkills, contains('Python'));

      viewModel.closeInspector();
      expect(viewModel.selectedJobDetail.value, isNull);
    });

    test('Auto-polling toggle toggles state cleanly', () {
      expect(viewModel.isAutoPolling.value, isFalse);
      viewModel.toggleAutoPolling();
      expect(viewModel.isAutoPolling.value, isTrue);
      viewModel.toggleAutoPolling();
      expect(viewModel.isAutoPolling.value, isFalse);
    });
  });
}

