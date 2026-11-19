class JobModel {
  final String id;
  final String sourceUrl;
  final String sourceName;
  final String? sourceId;
  final String companyName;
  final String rawTitle;
  final String? rawLocation;
  final String description;
  final Map<String, dynamic>? rawPayload;
  final String contentHash;

  // LLM Inferred / Enriched Data
  final String? inferredRole;
  final String? inferredCity;
  final String? inferredJobType;
  final String? inferredExperience;
  final String? inferredWorkMode;
  final List<String> inferredSkills;

  final double? classificationConfidence;
  final String? llmModel;
  final String? promptVersion;

  // ETL / Processing State
  final String etlStatus;
  final int processingAttempts;
  final String? lastError;

  // Cost Tracking
  final int? llmInputTokens;
  final int? llmOutputTokens;
  final double? llmCostUsd;

  // Lifecycle & Timestamps
  final DateTime? postedAt;
  final DateTime? lastSeenAt;
  final DateTime? classifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  JobModel({
    required this.id,
    required this.sourceUrl,
    required this.sourceName,
    this.sourceId,
    required this.companyName,
    required this.rawTitle,
    this.rawLocation,
    required this.description,
    this.rawPayload,
    required this.contentHash,
    this.inferredRole,
    this.inferredCity,
    this.inferredJobType,
    this.inferredExperience,
    this.inferredWorkMode,
    this.inferredSkills = const [],
    this.classificationConfidence,
    this.llmModel,
    this.promptVersion,
    this.etlStatus = 'PUBLISHED',
    this.processingAttempts = 0,
    this.lastError,
    this.llmInputTokens,
    this.llmOutputTokens,
    this.llmCostUsd,
    this.postedAt,
    this.lastSeenAt,
    this.classifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  // Convenience UI Getters
  String get title => rawTitle;
  String get company => companyName;
  String get applyUrl => sourceUrl;
  String get location => inferredCity ?? rawLocation ?? 'Remote';
  String get roleCategory => inferredRole ?? 'Other';
  String get workMode => inferredWorkMode ?? 'unknown';
  String get jobType => inferredJobType ?? 'unknown';
  String get experienceLevel => inferredExperience ?? 'unknown';
  List<String> get skills => inferredSkills;

  String get relativePostedDate {
    if (postedAt == null) return 'Recently';
    final now = DateTime.now();
    final diff = now.difference(postedAt!);

    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      return mins <= 1 ? 'Just now' : '${mins}m ago';
    } else if (diff.inHours < 24) {
      final hours = diff.inHours;
      return '${hours}h ago';
    } else if (diff.inDays < 7) {
      final days = diff.inDays;
      return days == 1 ? 'Yesterday' : '${days}d ago';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return weeks == 1 ? '1w ago' : '${weeks}w ago';
    } else {
      final months = (diff.inDays / 30).floor();
      return months == 1 ? '1mo ago' : '${months}mo ago';
    }
  }

  String get formattedConfidence {
    if (classificationConfidence == null) return 'N/A';
    return '${(classificationConfidence! * 100).toStringAsFixed(0)}% AI Match';
  }

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id']?.toString() ?? '',
      sourceUrl: json['source_url']?.toString() ?? '',
      sourceName: json['source_name']?.toString() ?? 'Direct',
      sourceId: json['source_id']?.toString(),
      companyName: json['company_name']?.toString() ?? '',
      rawTitle: json['raw_title']?.toString() ?? '',
      rawLocation: json['raw_location']?.toString(),
      description: json['description']?.toString() ?? '',
      rawPayload: json['raw_payload'] is Map<String, dynamic>
          ? json['raw_payload'] as Map<String, dynamic>
          : null,
      contentHash: json['content_hash']?.toString() ?? '',
      inferredRole: json['inferred_role']?.toString(),
      inferredCity: json['inferred_city']?.toString(),
      inferredJobType: json['inferred_job_type']?.toString(),
      inferredExperience: json['inferred_experience']?.toString(),
      inferredWorkMode: json['inferred_work_mode']?.toString(),
      inferredSkills: (json['inferred_skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      classificationConfidence: json['classification_confidence'] != null
          ? (json['classification_confidence'] is num
              ? (json['classification_confidence'] as num).toDouble()
              : double.tryParse(json['classification_confidence'].toString()))
          : null,
      llmModel: json['llm_model']?.toString(),
      promptVersion: json['prompt_version']?.toString(),
      etlStatus: json['etl_status']?.toString() ?? 'PUBLISHED',
      processingAttempts: (json['processing_attempts'] as num?)?.toInt() ?? 0,
      lastError: json['last_error']?.toString(),
      llmInputTokens: (json['llm_input_tokens'] as num?)?.toInt(),
      llmOutputTokens: (json['llm_output_tokens'] as num?)?.toInt(),
      llmCostUsd: json['llm_cost_usd'] != null
          ? (json['llm_cost_usd'] is num
              ? (json['llm_cost_usd'] as num).toDouble()
              : double.tryParse(json['llm_cost_usd'].toString()))
          : null,
      postedAt: json['posted_at'] != null
          ? DateTime.tryParse(json['posted_at'].toString())
          : null,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'].toString())
          : null,
      classifiedAt: json['classified_at'] != null
          ? DateTime.tryParse(json['classified_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source_url': sourceUrl,
      'source_name': sourceName,
      'source_id': sourceId,
      'company_name': companyName,
      'raw_title': rawTitle,
      'raw_location': rawLocation,
      'description': description,
      'raw_payload': rawPayload,
      'content_hash': contentHash,
      'inferred_role': inferredRole,
      'inferred_city': inferredCity,
      'inferred_job_type': inferredJobType,
      'inferred_experience': inferredExperience,
      'inferred_work_mode': inferredWorkMode,
      'inferred_skills': inferredSkills,
      'classification_confidence': classificationConfidence,
      'llm_model': llmModel,
      'prompt_version': promptVersion,
      'etl_status': etlStatus,
      'processing_attempts': processingAttempts,
      'last_error': lastError,
      'llm_input_tokens': llmInputTokens,
      'llm_output_tokens': llmOutputTokens,
      'llm_cost_usd': llmCostUsd,
      'posted_at': postedAt?.toIso8601String(),
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'classified_at': classifiedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  JobModel copyWith({
    String? id,
    String? sourceUrl,
    String? sourceName,
    String? sourceId,
    String? companyName,
    String? rawTitle,
    String? rawLocation,
    String? description,
    Map<String, dynamic>? rawPayload,
    String? contentHash,
    String? inferredRole,
    String? inferredCity,
    String? inferredJobType,
    String? inferredExperience,
    String? inferredWorkMode,
    List<String>? inferredSkills,
    double? classificationConfidence,
    String? llmModel,
    String? promptVersion,
    String? etlStatus,
    int? processingAttempts,
    String? lastError,
    int? llmInputTokens,
    int? llmOutputTokens,
    double? llmCostUsd,
    DateTime? postedAt,
    DateTime? lastSeenAt,
    DateTime? classifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JobModel(
      id: id ?? this.id,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceName: sourceName ?? this.sourceName,
      sourceId: sourceId ?? this.sourceId,
      companyName: companyName ?? this.companyName,
      rawTitle: rawTitle ?? this.rawTitle,
      rawLocation: rawLocation ?? this.rawLocation,
      description: description ?? this.description,
      rawPayload: rawPayload ?? this.rawPayload,
      contentHash: contentHash ?? this.contentHash,
      inferredRole: inferredRole ?? this.inferredRole,
      inferredCity: inferredCity ?? this.inferredCity,
      inferredJobType: inferredJobType ?? this.inferredJobType,
      inferredExperience: inferredExperience ?? this.inferredExperience,
      inferredWorkMode: inferredWorkMode ?? this.inferredWorkMode,
      inferredSkills: inferredSkills ?? this.inferredSkills,
      classificationConfidence:
          classificationConfidence ?? this.classificationConfidence,
      llmModel: llmModel ?? this.llmModel,
      promptVersion: promptVersion ?? this.promptVersion,
      etlStatus: etlStatus ?? this.etlStatus,
      processingAttempts: processingAttempts ?? this.processingAttempts,
      lastError: lastError ?? this.lastError,
      llmInputTokens: llmInputTokens ?? this.llmInputTokens,
      llmOutputTokens: llmOutputTokens ?? this.llmOutputTokens,
      llmCostUsd: llmCostUsd ?? this.llmCostUsd,
      postedAt: postedAt ?? this.postedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      classifiedAt: classifiedAt ?? this.classifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

