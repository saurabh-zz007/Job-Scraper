import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/admin_models.dart';
import '../../../data/repositories/admin_repository.dart';

class AdminViewModel extends GetxController {
  final AdminRepository _repository;

  AdminViewModel({AdminRepository? repository})
    : _repository = repository ?? Get.find<AdminRepository>();

  // State Observables
  final metrics = Rxn<DashboardMetricsModel>();
  final jobs = <AdminJobListItem>[].obs;
  final isLoadingMetrics = false.obs;
  final isLoadingJobs = false.obs;
  final isActionLoading = false.obs;
  final errorMessage = RxnString();

  // Pagination Observables
  final currentPage = 1.obs;
  final pageSize = 25.obs;
  final totalPages = 1.obs;
  final totalJobs = 0.obs;

  // Filters
  final selectedStatus = 'ALL'.obs; // ALL, RAW, FILTERED, CLASSIFIED, FAILED
  final selectedSource = 'ALL'.obs;
  final searchQuery = ''.obs;
  final lowConfidenceOnly = false.obs;

  // Selected Detail for Inspection
  final selectedJobDetail = Rxn<AdminJobDetailModel>();
  final isLoadingDetail = false.obs;

  // Polling
  final isAutoPolling = false.obs;
  Timer? _pollTimer;

  // Status Filter Options
  final statusOptions = const [
    'ALL',
    'RAW',
    'FILTERED',
    'CLASSIFIED',
    'FAILED',
  ];

  List<String> get availableSources {
    final list = <String>{'ALL'};
    final bySrc = metrics.value?.bySource;
    if (bySrc != null) {
      for (final s in bySrc) {
        if (s.sourceName.isNotEmpty) {
          list.add(s.sourceName);
        }
      }
    }
    list.addAll(['Greenhouse', 'Lever', 'Workday']);
    return list.toList();
  }

  bool get isBatchRunning => metrics.value?.pipelineLive.batchRunning ?? false;
  int get llmQueueDepth => metrics.value?.pipelineLive.llmQueueDepth ?? 0;

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  void toggleAutoPolling() {
    isAutoPolling.value = !isAutoPolling.value;
    _pollTimer?.cancel();
    if (isAutoPolling.value) {
      _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        refreshAll(silent: true);
      });
      _showSnackbar(
        title: 'Auto-Polling Enabled',
        message: 'Dashboard and job statuses refresh every 15s.',
        isError: false,
      );
    } else {
      _showSnackbar(
        title: 'Auto-Polling Paused',
        message: 'Live updates paused.',
        isError: false,
      );
    }
  }

  Future<void> refreshAll({bool silent = false}) async {
    await Future.wait([
      fetchDashboard(silent: silent),
      fetchJobs(page: currentPage.value, silent: silent),
    ]);
  }

  Future<void> fetchDashboard({bool silent = false}) async {
    if (!silent) isLoadingMetrics.value = true;
    try {
      final res = await _repository.getDashboardMetrics();
      metrics.value = res;
      errorMessage.value = null;
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      if (!silent) {
        _showSnackbar(
          title: 'Metrics Error',
          message: errorMessage.value ?? 'Failed to load metrics.',
          isError: true,
        );
      }
    } finally {
      if (!silent) isLoadingMetrics.value = false;
    }
  }

  Future<void> fetchJobs({int? page, bool silent = false}) async {
    if (page != null) currentPage.value = page;
    if (!silent) isLoadingJobs.value = true;

    try {
      final res = await _repository.listJobs(
        page: currentPage.value,
        pageSize: pageSize.value,
        etlStatus: selectedStatus.value == 'ALL' ? null : selectedStatus.value,
        sourceName: selectedSource.value == 'ALL' ? null : selectedSource.value,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        maxConfidence: lowConfidenceOnly.value ? 0.80 : null,
      );
      jobs.assignAll(res.items);
      totalJobs.value = res.total;
      totalPages.value = res.totalPages > 0 ? res.totalPages : 1;
      currentPage.value = res.page;
    } catch (e) {
      if (!silent) {
        _showSnackbar(
          title: 'Job Feed Error',
          message: e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (!silent) isLoadingJobs.value = false;
    }
  }

  void onStatusChanged(String status) {
    if (selectedStatus.value != status) {
      selectedStatus.value = status;
      currentPage.value = 1;
      fetchJobs();
    }
  }

  void onSourceChanged(String? source) {
    if (source != null && selectedSource.value != source) {
      selectedSource.value = source;
      currentPage.value = 1;
      fetchJobs();
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    currentPage.value = 1;
    fetchJobs();
  }

  void toggleLowConfidenceOnly(bool? value) {
    lowConfidenceOnly.value = value ?? false;
    currentPage.value = 1;
    fetchJobs();
  }

  void onPageSizeChanged(int? newSize) {
    if (newSize != null && newSize != pageSize.value) {
      pageSize.value = newSize;
      currentPage.value = 1;
      fetchJobs();
    }
  }

  void goToNextPage() {
    if (currentPage.value < totalPages.value) {
      fetchJobs(page: currentPage.value + 1);
    }
  }

  void goToPrevPage() {
    if (currentPage.value > 1) {
      fetchJobs(page: currentPage.value - 1);
    }
  }

  Future<void> inspectJob(String jobId) async {
    isLoadingDetail.value = true;
    selectedJobDetail.value = null;
    try {
      final detail = await _repository.getJobDetail(jobId);
      selectedJobDetail.value = detail;
    } catch (e) {
      _showSnackbar(
        title: 'Inspector Error',
        message: 'Could not load job details: $e',
        isError: true,
      );
    } finally {
      isLoadingDetail.value = false;
    }
  }

  void closeInspector() {
    selectedJobDetail.value = null;
  }

  Future<void> retryFailedJobs({List<String>? jobIds}) async {
    isActionLoading.value = true;
    try {
      final res = await _repository.retryFailedJobs(jobIds: jobIds);
      _showSnackbar(
        title: 'Retry Enqueued',
        message: res.message,
        isError: false,
      );
      await refreshAll();
    } catch (e) {
      _showSnackbar(
        title: 'Retry Failed',
        message: e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> reclassifyJobs({
    String? promptVersion,
    double? maxConfidence,
  }) async {
    isActionLoading.value = true;
    try {
      final res = await _repository.reclassifyJobs(
        promptVersion: promptVersion,
        maxConfidence: maxConfidence,
      );
      _showSnackbar(
        title: 'Reclassification Triggered',
        message: res.message,
        isError: false,
      );
      await refreshAll();
    } catch (e) {
      _showSnackbar(
        title: 'Reclassification Failed',
        message: e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> purgeJobs({String? etlStatus, int? olderThanDays}) async {
    isActionLoading.value = true;
    try {
      final res = await _repository.purgeJobs(
        etlStatus: etlStatus,
        olderThanDays: olderThanDays,
      );
      _showSnackbar(
        title: 'Purge Completed',
        message: res.message,
        isError: false,
      );
      await refreshAll();
    } catch (e) {
      _showSnackbar(
        title: 'Purge Failed',
        message: e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> deleteJob(String jobId) async {
    isActionLoading.value = true;
    try {
      final res = await _repository.deleteJob(jobId);
      if (selectedJobDetail.value?.id == jobId) {
        closeInspector();
      }
      _showSnackbar(title: 'Job Deleted', message: res.message, isError: false);
      await refreshAll();
    } catch (e) {
      _showSnackbar(
        title: 'Deletion Failed',
        message: e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> triggerPipeline() async {
    isActionLoading.value = true;
    try {
      final res = await _repository.triggerPipeline();
      _showSnackbar(
        title: 'Pipeline Ingestion Triggered',
        message: res.message,
        isError: false,
      );
      await refreshAll();
    } catch (e) {
      _showSnackbar(
        title: 'Trigger Failed',
        message: e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> openExternalUrl(String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackbar(
          title: 'Invalid URL',
          message: 'Unable to open: $url',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackbar(
        title: 'Navigation Error',
        message: 'Could not launch URL: $e',
        isError: true,
      );
    }
  }

  void _showSnackbar({
    required String title,
    required String message,
    required bool isError,
  }) {
    if (Get.context == null) return;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? AppTheme.danger : const Color(0xFF1E293B),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 10,
      duration: const Duration(seconds: 4),
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: Colors.white,
      ),
    );
  }
}
