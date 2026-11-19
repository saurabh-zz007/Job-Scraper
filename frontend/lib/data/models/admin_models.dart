class PipelineLiveStatus {
  final bool batchRunning;
  final int llmQueueDepth;

  PipelineLiveStatus({
    required this.batchRunning,
    required this.llmQueueDepth,
  });

  factory PipelineLiveStatus.fromJson(Map<String, dynamic> json) {
    return PipelineLiveStatus(
      batchRunning: json['batch_running'] == true,
      llmQueueDepth: (json['llm_queue_depth'] as num?)?.toInt() ?? 0,
    );
  }
}

class FunnelMetrics {
  final int totalJobs;
  final int raw;
  final int filteredPendingLlm;
  final int classified;
  final int failed;

  FunnelMetrics({
    required this.totalJobs,
    required this.raw,
    required this.filteredPendingLlm,
    required this.classified,
    required this.failed,
  });

  factory FunnelMetrics.fromJson(Map<String, dynamic> json) {
    return FunnelMetrics(
      totalJobs: (json['total_jobs'] as num?)?.toInt() ?? 0,
      raw: (json['raw'] as num?)?.toInt() ?? 0,
      filteredPendingLlm: (json['filtered_pending_llm'] as num?)?.toInt() ?? 0,
      classified: (json['classified'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
    );
  }
}

class LLMEconomics {
  final double totalCostUsd;
  final double costLast24hUsd;
  final double avgCostPerJobUsd;
  final int totalInputTokens;
  final int totalOutputTokens;

  LLMEconomics({
    required this.totalCostUsd,
    required this.costLast24hUsd,
    required this.avgCostPerJobUsd,
    required this.totalInputTokens,
    required this.totalOutputTokens,
  });

  factory LLMEconomics.fromJson(Map<String, dynamic> json) {
    return LLMEconomics(
      totalCostUsd: (json['total_cost_usd'] as num?)?.toDouble() ?? 0.0,
      costLast24hUsd: (json['cost_last_24h_usd'] as num?)?.toDouble() ?? 0.0,
      avgCostPerJobUsd: (json['avg_cost_per_job_usd'] as num?)?.toDouble() ?? 0.0,
      totalInputTokens: (json['total_input_tokens'] as num?)?.toInt() ?? 0,
      totalOutputTokens: (json['total_output_tokens'] as num?)?.toInt() ?? 0,
    );
  }
}

class QualityMetrics {
  final double avgConfidence;
  final int lowConfidenceJobs;
  final int staleJobsOver14d;

  QualityMetrics({
    required this.avgConfidence,
    required this.lowConfidenceJobs,
    required this.staleJobsOver14d,
  });

  factory QualityMetrics.fromJson(Map<String, dynamic> json) {
    return QualityMetrics(
      avgConfidence: (json['avg_confidence'] as num?)?.toDouble() ?? 0.0,
      lowConfidenceJobs: (json['low_confidence_jobs'] as num?)?.toInt() ?? 0,
      staleJobsOver14d: (json['stale_jobs_over_14d'] as num?)?.toInt() ?? 0,
    );
  }
}

class SourceMetric {
  final String sourceName;
  final int total;
  final int classified;
  final int failed;
  final double avgConfidence;

  SourceMetric({
    required this.sourceName,
    required this.total,
    required this.classified,
    required this.failed,
    required this.avgConfidence,
  });

  factory SourceMetric.fromJson(Map<String, dynamic> json) {
    return SourceMetric(
      sourceName: json['source_name']?.toString() ?? 'Direct',
      total: (json['total'] as num?)?.toInt() ?? 0,
      classified: (json['classified'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
      avgConfidence: (json['avg_confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PromptVersionMetric {
  final String? llmModel;
  final String? promptVersion;
  final int jobsProcessed;
  final double avgConfidence;
  final double avgCostUsd;

  PromptVersionMetric({
    this.llmModel,
    this.promptVersion,
    required this.jobsProcessed,
    required this.avgConfidence,
    required this.avgCostUsd,
  });

  factory PromptVersionMetric.fromJson(Map<String, dynamic> json) {
    return PromptVersionMetric(
      llmModel: json['llm_model']?.toString(),
      promptVersion: json['prompt_version']?.toString(),
      jobsProcessed: (json['jobs_processed'] as num?)?.toInt() ?? 0,
      avgConfidence: (json['avg_confidence'] as num?)?.toDouble() ?? 0.0,
      avgCostUsd: (json['avg_cost_usd'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TopErrorMetric {
  final String error;
  final int count;

  TopErrorMetric({
    required this.error,
    required this.count,
  });

  factory TopErrorMetric.fromJson(Map<String, dynamic> json) {
    return TopErrorMetric(
      error: json['error']?.toString() ?? 'Unknown error',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardMetricsModel {
  final PipelineLiveStatus pipelineLive;
  final FunnelMetrics funnel;
  final LLMEconomics llmEconomics;
  final QualityMetrics quality;
  final List<SourceMetric> bySource;
  final List<PromptVersionMetric> byPromptVersion;
  final List<TopErrorMetric> topErrors;

  DashboardMetricsModel({
    required this.pipelineLive,
    required this.funnel,
    required this.llmEconomics,
    required this.quality,
    required this.bySource,
    required this.byPromptVersion,
    required this.topErrors,
  });

  factory DashboardMetricsModel.fromJson(Map<String, dynamic> json) {
    return DashboardMetricsModel(
      pipelineLive: PipelineLiveStatus.fromJson(
        json['pipeline_live'] as Map<String, dynamic>? ?? {},
      ),
      funnel: FunnelMetrics.fromJson(
        json['funnel'] as Map<String, dynamic>? ?? {},
      ),
      llmEconomics: LLMEconomics.fromJson(
        json['llm_economics'] as Map<String, dynamic>? ?? {},
      ),
      quality: QualityMetrics.fromJson(
        json['quality'] as Map<String, dynamic>? ?? {},
      ),
      bySource: (json['by_source'] as List<dynamic>?)
              ?.map((e) => SourceMetric.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      byPromptVersion: (json['by_prompt_version'] as List<dynamic>?)
              ?.map(
                  (e) => PromptVersionMetric.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topErrors: (json['top_errors'] as List<dynamic>?)
              ?.map((e) => TopErrorMetric.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class AdminJobListItem {
  final String id;
  final String companyName;
  final String rawTitle;
  final String? rawLocation;
  final String sourceName;
  final String etlStatus;
  final String? inferredRole;
  final String? inferredCity;
  final String? inferredWorkMode;
  final String? inferredExperience;
  final double? classificationConfidence;
  final int processingAttempts;
  final double? llmCostUsd;
  final String? lastError;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminJobListItem({
    required this.id,
    required this.companyName,
    required this.rawTitle,
    this.rawLocation,
    required this.sourceName,
    required this.etlStatus,
    this.inferredRole,
    this.inferredCity,
    this.inferredWorkMode,
    this.inferredExperience,
    this.classificationConfidence,
    this.processingAttempts = 0,
    this.llmCostUsd,
    this.lastError,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminJobListItem.fromJson(Map<String, dynamic> json) {
    return AdminJobListItem(
      id: json['id']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      rawTitle: json['raw_title']?.toString() ?? '',
      rawLocation: json['raw_location']?.toString(),
      sourceName: json['source_name']?.toString() ?? 'Direct',
      etlStatus: json['etl_status']?.toString() ?? 'RAW',
      inferredRole: json['inferred_role']?.toString(),
      inferredCity: json['inferred_city']?.toString(),
      inferredWorkMode: json['inferred_work_mode']?.toString(),
      inferredExperience: json['inferred_experience']?.toString(),
      classificationConfidence: json['classification_confidence'] != null
          ? (json['classification_confidence'] is num
              ? (json['classification_confidence'] as num).toDouble()
              : double.tryParse(json['classification_confidence'].toString()))
          : null,
      processingAttempts: (json['processing_attempts'] as num?)?.toInt() ?? 0,
      llmCostUsd: json['llm_cost_usd'] != null
          ? (json['llm_cost_usd'] is num
              ? (json['llm_cost_usd'] as num).toDouble()
              : double.tryParse(json['llm_cost_usd'].toString()))
          : null,
      lastError: json['last_error']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}

class PaginatedAdminJobsModel {
  final List<AdminJobListItem> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  PaginatedAdminJobsModel({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PaginatedAdminJobsModel.fromJson(Map<String, dynamic> json) {
    return PaginatedAdminJobsModel(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => AdminJobListItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 25,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
    );
  }
}

class AdminJobDetailModel {
  final String id;
  final String companyName;
  final String rawTitle;
  final String? rawLocation;
  final String sourceName;
  final String etlStatus;
  final String? inferredRole;
  final String? inferredCity;
  final String? inferredWorkMode;
  final String? inferredExperience;
  final double? classificationConfidence;
  final int processingAttempts;
  final double? llmCostUsd;
  final String? lastError;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String sourceUrl;
  final String description;
  final Map<String, dynamic>? rawPayload;
  final String? inferredJobType;
  final List<String> inferredSkills;
  final String? llmModel;
  final String? promptVersion;
  final int? llmInputTokens;
  final int? llmOutputTokens;
  final DateTime? postedAt;
  final DateTime? lastSeenAt;
  final DateTime? classifiedAt;

  AdminJobDetailModel({
    required this.id,
    required this.companyName,
    required this.rawTitle,
    this.rawLocation,
    required this.sourceName,
    required this.etlStatus,
    this.inferredRole,
    this.inferredCity,
    this.inferredWorkMode,
    this.inferredExperience,
    this.classificationConfidence,
    this.processingAttempts = 0,
    this.llmCostUsd,
    this.lastError,
    this.createdAt,
    this.updatedAt,
    required this.sourceUrl,
    required this.description,
    this.rawPayload,
    this.inferredJobType,
    this.inferredSkills = const [],
    this.llmModel,
    this.promptVersion,
    this.llmInputTokens,
    this.llmOutputTokens,
    this.postedAt,
    this.lastSeenAt,
    this.classifiedAt,
  });

  factory AdminJobDetailModel.fromJson(Map<String, dynamic> json) {
    return AdminJobDetailModel(
      id: json['id']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      rawTitle: json['raw_title']?.toString() ?? '',
      rawLocation: json['raw_location']?.toString(),
      sourceName: json['source_name']?.toString() ?? 'Direct',
      etlStatus: json['etl_status']?.toString() ?? 'RAW',
      inferredRole: json['inferred_role']?.toString(),
      inferredCity: json['inferred_city']?.toString(),
      inferredWorkMode: json['inferred_work_mode']?.toString(),
      inferredExperience: json['inferred_experience']?.toString(),
      classificationConfidence: json['classification_confidence'] != null
          ? (json['classification_confidence'] is num
              ? (json['classification_confidence'] as num).toDouble()
              : double.tryParse(json['classification_confidence'].toString()))
          : null,
      processingAttempts: (json['processing_attempts'] as num?)?.toInt() ?? 0,
      llmCostUsd: json['llm_cost_usd'] != null
          ? (json['llm_cost_usd'] is num
              ? (json['llm_cost_usd'] as num).toDouble()
              : double.tryParse(json['llm_cost_usd'].toString()))
          : null,
      lastError: json['last_error']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      sourceUrl: json['source_url']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      rawPayload: json['raw_payload'] is Map<String, dynamic>
          ? json['raw_payload'] as Map<String, dynamic>
          : null,
      inferredJobType: json['inferred_job_type']?.toString(),
      inferredSkills: (json['inferred_skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      llmModel: json['llm_model']?.toString(),
      promptVersion: json['prompt_version']?.toString(),
      llmInputTokens: (json['llm_input_tokens'] as num?)?.toInt(),
      llmOutputTokens: (json['llm_output_tokens'] as num?)?.toInt(),
      postedAt: json['posted_at'] != null
          ? DateTime.tryParse(json['posted_at'].toString())
          : null,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'].toString())
          : null,
      classifiedAt: json['classified_at'] != null
          ? DateTime.tryParse(json['classified_at'].toString())
          : null,
    );
  }
}

class AdminBulkActionResponse {
  final int affectedCount;
  final String message;

  AdminBulkActionResponse({
    required this.affectedCount,
    required this.message,
  });

  factory AdminBulkActionResponse.fromJson(Map<String, dynamic> json) {
    return AdminBulkActionResponse(
      affectedCount: (json['affected_count'] as num?)?.toInt() ?? 0,
      message: json['message']?.toString() ?? 'Operation completed.',
    );
  }
}

